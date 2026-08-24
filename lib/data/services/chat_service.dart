import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/sse_parser.dart';
import '../models/chat_message_model.dart';
import '../models/sse_event.dart';

class ChatService {
  ChatService._();

  static final ChatService instance = ChatService._();

  Dio get _dio => ApiClient.instance.dio;

  Stream<SseEvent> streamChat({
    required String presenceId,
    required String message,
    required String userWallet,
    String? userId,
    String? realmId,
  }) async* {
    AppLogger.debug(
      'Opening SSE stream for presence=$presenceId (web=$kIsWeb)',
      tag: 'ChatService',
    );
    try {
      final data = <String, dynamic>{
        'presenceId': presenceId,
        'message': message,
        'userWallet': userWallet,
      };
      if (userId != null && userId.isNotEmpty) data['userId'] = userId;
      if (realmId != null && realmId.isNotEmpty) data['realmId'] = realmId;

      final response = await _dio.post<dynamic>(
        ApiEndpoints.chatStream,
        data: data,
        options: Options(
          responseType: kIsWeb ? ResponseType.plain : ResponseType.stream,
          receiveTimeout: const Duration(minutes: 5),
          headers: {'Accept': 'text/event-stream'},
        ),
      );

      final statusCode = response.statusCode ?? 0;
      AppLogger.debug(
        'SSE response status=$statusCode, bodyType=${response.data.runtimeType}',
        tag: 'ChatService',
      );

      if (statusCode == 402) {
        // Backend rejected the request: no KIDUNA left to pay for compute.
        throw const InsufficientBalanceException(
          'You have no KIDUNA left. Buy more to keep chatting with Ki.',
        );
      }
      if (statusCode >= 400) {
        throw ServerException('Chat stream returned $statusCode');
      }

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty stream response');
      }

      final Stream<List<int>> byteStream;
      if (body is ResponseBody) {
        byteStream = body.stream;
      } else if (body is String) {
        byteStream = Stream.value(utf8.encode(body));
      } else {
        AppLogger.warning(
          'Unexpected response body type: ${body.runtimeType}',
          tag: 'ChatService',
        );
        byteStream = Stream.value(utf8.encode(body.toString()));
      }

      yield* SseParser.parse(byteStream);
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      AppLogger.error(
        'Chat stream DioException: type=${e.type}, msg=${e.message}',
        tag: 'ChatService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const NetworkException(
        'Unable to connect. Please check your internet.',
      );
    }
  }

  Future<List<ChatMessageModel>> fetchHistory({
    required String presenceId,
    required String userWallet,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.conversationHistory(presenceId, userWallet),
      );

      final body = response.data;
      if (body == null) {
        return [];
      }

      final messages = body['messages'] as List<dynamic>? ?? [];
      final result = messages
          .map((m) => ChatMessageModel.fromJson(m as Map<String, dynamic>))
          .toList();

      AppLogger.info('Loaded ${result.length} messages', tag: 'ChatService');
      return result;
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      AppLogger.error(
        'Failed to fetch conversation history',
        tag: 'ChatService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const NetworkException(
        'Unable to connect. Please check your internet.',
      );
    }
  }
}
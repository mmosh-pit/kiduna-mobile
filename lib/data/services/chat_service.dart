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

/// Handles Ki chat interactions via the kinship-agent API.
///
/// Returns parsed data or throws typed exceptions — no business logic.
class ChatService {
  ChatService._();

  static final ChatService instance = ChatService._();

  Dio get _dio => ApiClient.instance.dio;

  /// Open an SSE stream for a chat message.
  ///
  /// On native: uses `ResponseType.stream` for real-time token streaming.
  /// On web: uses `ResponseType.plain` because Dio's web adapter does not
  /// reliably expose the Fetch API ReadableStream. The full response text
  /// is received at once, then parsed into SSE frames.
  ///
  /// This is a POST — it is never retried on failure.
  Stream<SseEvent> streamChat({
    required String presenceId,
    required String message,
    required String userWallet,
  }) async* {
    AppLogger.debug(
      'Opening SSE stream for presence=$presenceId (web=$kIsWeb)',
      tag: 'ChatService',
    );
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.chatStream,
        data: {
          'presenceId': presenceId,
          'message': message,
          'userWallet': userWallet,
        },
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
        throw const ServerException('Token limit exceeded');
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
        AppLogger.debug(
          'Using ResponseBody stream (native)',
          tag: 'ChatService',
        );
        byteStream = body.stream;
      } else if (body is String) {
        AppLogger.debug(
          'Using plain text response (${body.length} chars)',
          tag: 'ChatService',
        );
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

  /// Fetch the full conversation history.
  ///
  /// Sends `GET /api/conversations/{presenceId}/{userWallet}`.
  /// Returns the list of [ChatMessageModel] from the conversation.
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

import 'package:dio/dio.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../models/ally_agent_model.dart';

class AllyService {
  AllyService._();

  static final AllyService instance = AllyService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<AllyAgentModel> fetchAlly() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.allyAgent,
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from ally endpoint');
      }

      final ally = AllyAgentModel.fromJson(body);

      AppLogger.info('Ally loaded: ${ally.name}', tag: 'AllyService');
      return ally;
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      AppLogger.error(
        'Failed to fetch ally',
        tag: 'AllyService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const NetworkException(
        'Unable to connect. Please check your internet.',
      );
    }
  }

  Future<String> saveAndAttachPrompt({
    required String agentId,
    required String agentName,
    required String wallet,
    required String systemPrompt,
    String? existingPromptId,
  }) async {
    try {
      String promptId;

      if (existingPromptId != null && existingPromptId.isNotEmpty) {
        await _dio.patch<Map<String, dynamic>>(
          ApiEndpoints.promptUpdate(existingPromptId),
          data: {'content': systemPrompt},
        );
        promptId = existingPromptId;
        AppLogger.info('Prompt updated: $promptId', tag: 'AllyService');
      } else {
        final createResponse = await _dio.post<Map<String, dynamic>>(
          ApiEndpoints.prompts,
          data: {
            'name': '$agentName Presence Prompt',
            'content': systemPrompt,
            'wallet': wallet,
          },
        );

        final createBody = createResponse.data;
        if (createBody == null || createBody['id'] == null) {
          throw const ServerException('Failed to create prompt record');
        }

        promptId = createBody['id'] as String;
        AppLogger.info('Prompt created: $promptId', tag: 'AllyService');
      }

      await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.agentUpdate(agentId),
        data: {'promptId': promptId, 'systemPrompt': systemPrompt},
      );
      AppLogger.info(
        'Prompt $promptId attached to agent $agentId',
        tag: 'AllyService',
      );

      return promptId;
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      AppLogger.error(
        'Failed to save and attach prompt',
        tag: 'AllyService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const ServerException('Unable to save presence. Please try again.');
    }
  }

  Future<void> patchAgent(String agentId, Map<String, dynamic> data) async {
    await _dio.patch<Map<String, dynamic>>(
      ApiEndpoints.agentUpdate(agentId),
      data: data,
    );
  }
}

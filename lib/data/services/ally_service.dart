import 'package:dio/dio.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../models/ally_agent_model.dart';

/// Fetches and updates the system ally agent from the kinship-agent API.
///
/// Returns parsed data or throws typed exceptions — no business logic.
class AllyService {
  AllyService._();

  static final AllyService instance = AllyService._();

  Dio get _dio => ApiClient.instance.dio;

  /// Fetch the ally agent profile.
  ///
  /// Sends `GET /api/agents/ally`. The auth interceptor adds the Bearer
  /// token automatically.
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

  /// Save system prompt and attach it to the agent.
  ///
  /// Two-step flow (like knowledge bases):
  /// 1. Create or update a Prompt record via `/api/prompts`.
  /// 2. Attach it to the agent via `PATCH /api/agents/{id}` with `promptId`.
  ///
  /// Returns the new prompt id so the caller can update local state.
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
        // Update existing prompt record
        await _dio.patch<Map<String, dynamic>>(
          ApiEndpoints.promptUpdate(existingPromptId),
          data: {'content': systemPrompt},
        );
        promptId = existingPromptId;
        AppLogger.info('Prompt updated: $promptId', tag: 'AllyService');
      } else {
        // Create new prompt record
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

      // Attach the prompt to the agent
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

  /// Patch agent with arbitrary data.
  Future<void> patchAgent(
    String agentId,
    Map<String, dynamic> data,
  ) async {
    await _dio.patch<Map<String, dynamic>>(
      ApiEndpoints.agentUpdate(agentId),
      data: data,
    );
  }
}
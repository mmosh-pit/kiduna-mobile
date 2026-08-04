import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../models/prompt_model.dart';

/// Service for Prompt (system stance) CRUD + AI generation.
class PromptService {
  PromptService._();
  static final PromptService instance = PromptService._();

  Dio get _dio => ApiClient.instance.dio;

  /// List all prompts for a wallet.
  Future<List<PromptModel>> listPrompts(String wallet) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.prompts,
      queryParameters: {'wallet': wallet},
    );
    final list = response.data?['prompts'] as List<dynamic>? ?? [];
    return list
        .map((e) => PromptModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single prompt by ID.
  Future<PromptModel> fetchPrompt(String promptId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.promptUpdate(promptId),
    );
    return PromptModel.fromJson(response.data ?? {});
  }

  /// Create a new prompt.
  Future<PromptModel> createPrompt({
    required String name,
    required String wallet,
    String content = '',
    String? goal,
    String? connectedKbId,
    String? connectedKbName,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.prompts,
      data: {
        'name': name,
        'content': content,
        'wallet': wallet,
        if (goal != null) 'goal': goal,
        if (connectedKbId != null) 'connectedKBId': connectedKbId,
        if (connectedKbName != null) 'connectedKBName': connectedKbName,
      },
    );
    return PromptModel.fromJson(response.data ?? {});
  }

  /// Update a prompt (PATCH).
  Future<PromptModel> updatePrompt(
    String promptId, {
    String? name,
    String? content,
    String? goal,
    String? connectedKbId,
    String? connectedKbName,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (content != null) data['content'] = content;
    if (goal != null) data['goal'] = goal;
    if (connectedKbId != null) data['connectedKBId'] = connectedKbId;
    if (connectedKbName != null) data['connectedKBName'] = connectedKbName;

    final response = await _dio.patch<Map<String, dynamic>>(
      ApiEndpoints.promptUpdate(promptId),
      data: data,
    );
    return PromptModel.fromJson(response.data ?? {});
  }

  /// Delete a prompt.
  Future<void> deletePrompt(String promptId) async {
    await _dio.delete<void>(ApiEndpoints.promptUpdate(promptId));
  }

  /// Generate system prompt content from goal via AI.
  Future<String> generateFromGoal({
    required String goal,
    String? name,
    String? knowledgeBaseName,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiEndpoints.prompts}/generate',
      data: {
        'goal': goal,
        if (name != null) 'name': name,
        if (knowledgeBaseName != null) 'knowledgeBaseName': knowledgeBaseName,
      },
    );
    return response.data?['content'] as String? ?? '';
  }

  /// Validate goal clarity via AI before generation.
  /// Returns `(valid, message)`.
  Future<({bool valid, String message})> validateGoal({
    required String goal,
    String? name,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiEndpoints.prompts}/validate-goal',
      data: {
        'goal': goal,
        if (name != null) 'name': name,
      },
    );
    final data = response.data ?? {};
    final valid = data['valid'] as bool? ?? false;
    final message = data['message'] as String? ?? '';
    AppLogger.info(
      'validate-goal: valid=$valid message=$message',
      tag: 'PromptService',
    );
    return (valid: valid, message: message);
  }
}
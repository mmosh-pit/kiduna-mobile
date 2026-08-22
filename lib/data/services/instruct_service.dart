import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../models/instruct_model.dart';

/// Service for Instruct (system stance) CRUD + AI generation.
/// Backend API path stays /api/prompts — only Flutter-side naming changes.
class InstructService {
  InstructService._();
  static final InstructService instance = InstructService._();

  Dio get _dio => ApiClient.instance.dio;

  /// List all instructs for a wallet.
  Future<List<InstructModel>> listInstructs(String wallet, {String? realmId}) async {
    final queryParams = <String, dynamic>{'wallet': wallet};
    if (realmId != null) queryParams['realmId'] = realmId;
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.prompts,
      queryParameters: queryParams,
    );
    final list = response.data?['prompts'] as List<dynamic>? ?? [];
    return list
        .map((e) => InstructModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single instruct by ID.
  Future<InstructModel> fetchInstruct(String instructId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.promptUpdate(instructId),
    );
    return InstructModel.fromJson(response.data ?? {});
  }

  /// Create a new instruct.
  Future<InstructModel> createInstruct({
    required String name,
    required String wallet,
    String content = '',
    String? goal,
    String? realmId,
    String? connectedKbId,
    String? connectedKbName,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.prompts,
      data: {
        'name': name,
        'content': content,
        'wallet': wallet,
        'goal': ?goal,
        'realmId': ?realmId,
        'connectedKBId': ?connectedKbId,
        'connectedKBName': ?connectedKbName,
      },
    );
    return InstructModel.fromJson(response.data ?? {});
  }

  /// Update an instruct (PATCH).
  Future<InstructModel> updateInstruct(
    String instructId, {
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
      ApiEndpoints.promptUpdate(instructId),
      data: data,
    );
    return InstructModel.fromJson(response.data ?? {});
  }

  /// Delete an instruct.
  Future<void> deleteInstruct(String instructId) async {
    await _dio.delete<void>(ApiEndpoints.promptUpdate(instructId));
  }

  /// Generate system prompt content from goal via AI.
  Future<String> generateFromGoal({
    required String goal,
    String? knowledgeBaseName,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiEndpoints.prompts}/generate',
      data: {
        'goal': goal,
        'knowledgeBaseName': ?knowledgeBaseName,
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
        'name': ?name,
      },
    );
    final data = response.data ?? {};
    final valid = data['valid'] as bool? ?? false;
    final message = data['message'] as String? ?? '';
    AppLogger.info(
      'validate-goal: valid=$valid message=$message',
      tag: 'InstructService',
    );
    return (valid: valid, message: message);
  }
}
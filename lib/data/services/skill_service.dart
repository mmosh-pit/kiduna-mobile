import 'package:dio/dio.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../models/available_tool_model.dart';
import '../models/skill_model.dart';

/// CRUD operations for skills via the kinship-agent API.
///
/// Returns parsed data or throws typed exceptions — no business logic.
class SkillService {
  SkillService._();

  static final SkillService instance = SkillService._();

  Dio get _dio => ApiClient.instance.dio;

  /// Fetch all skills from the backend.
  Future<List<SkillModel>> list() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.skills,
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from skills list');
      }

      final skillsList = body['skills'] as List<dynamic>? ?? [];
      final skills = skillsList
          .map((e) => SkillModel.fromJson(e as Map<String, dynamic>))
          .toList();

      AppLogger.info('Fetched ${skills.length} skills', tag: 'SkillService');
      return skills;
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      AppLogger.error(
        'Failed to fetch skills',
        tag: 'SkillService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const NetworkException(
        'Unable to connect. Please check your internet.',
      );
    }
  }

  /// Create a new skill.
  ///
  /// Sends `POST /api/skills` with the skill fields plus the creator's
  /// wallet. The auth interceptor adds the Bearer token automatically.
  ///
  /// Returns the [SkillModel] created by the backend (includes the
  /// server-assigned id, file path, and timestamps).
  ///
  /// Throws [ServerException], [NetworkException], [ValidationException],
  /// or [UnauthorizedException] on failure.
  Future<SkillModel> create(SkillModel skill, {required String wallet}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.skills,
        data: skill.toCreateJson(wallet: wallet),
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from skill creation');
      }

      final result = SkillModel.fromJson(body);

      AppLogger.info('Skill created: ${result.id}', tag: 'SkillService');
      return result;
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      AppLogger.error(
        'Failed to create skill',
        tag: 'SkillService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const NetworkException(
        'Unable to connect. Please check your internet.',
      );
    }
  }

  /// Fetch available tools discovered from MCP servers.
  ///
  /// Sends `GET /api/tools/available`. Returns a flat list combining
  /// both internal and external tools. Each tool carries its `uid`,
  /// `name`, `category`, and connection status.
  Future<List<AvailableToolModel>> fetchTools() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.toolsAvailable,
      );

      final body = response.data;
      if (body == null) {
        return [];
      }

      final tools = <AvailableToolModel>[];

      final internal = body['internal'] as List<dynamic>? ?? [];
      for (final item in internal) {
        if (item is Map<String, dynamic>) {
          tools.add(AvailableToolModel.fromJson(item, defaultType: 'internal'));
        }
      }

      final external = body['external'] as List<dynamic>? ?? [];
      for (final item in external) {
        if (item is Map<String, dynamic>) {
          tools.add(AvailableToolModel.fromJson(item));
        }
      }

      AppLogger.info(
        'Fetched ${tools.length} tools '
        '(${internal.length} internal, ${external.length} external)',
        tag: 'SkillService',
      );
      return tools;
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      AppLogger.warning(
        'Failed to fetch tools: ${e.message}',
        tag: 'SkillService',
      );
      return [];
    }
  }

  /// Attach a skill to an agent by adding it to `skill_ids`.
  ///
  /// Sends `PATCH /api/agents/{agentId}` with the updated `skill_ids`
  /// array. The backend's mutable_fields whitelist includes `skill_ids`,
  /// so this is a supported update path.
  ///
  /// [currentSkillIds] should be the agent's existing skill IDs (may be
  /// empty). The [newSkillId] is appended if not already present.
  Future<void> attachSkillToAgent({
    required String agentId,
    required String newSkillId,
  }) async {
    try {
      // Fetch the agent's current skill_ids so we append, not overwrite.
      final agentResponse = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.agentUpdate(agentId),
      );
      final agentData = agentResponse.data;
      final existing = <String>[];
      if (agentData != null) {
        final raw = agentData['skill_ids'] as List<dynamic>? ?? [];
        existing.addAll(raw.cast<String>());
      }

      if (existing.contains(newSkillId)) {
        AppLogger.info(
          'Skill $newSkillId already attached to agent $agentId',
          tag: 'SkillService',
        );
        return;
      }

      final updatedIds = [...existing, newSkillId];

      await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.agentUpdate(agentId),
        data: {'skill_ids': updatedIds},
      );

      AppLogger.info(
        'Skill $newSkillId attached to agent $agentId '
        '(${updatedIds.length} total)',
        tag: 'SkillService',
      );
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      AppLogger.warning(
        'Failed to attach skill to agent: ${e.message}',
        tag: 'SkillService',
      );
    }
  }

  /// Update an existing skill.
  ///
  /// Sends `PATCH /api/skills/{id}` with the changed fields.
  /// Returns the updated [SkillModel] from the backend.
  Future<SkillModel> update(
    String skillId, {
    String? name,
    String? whenText,
    String? thenText,
    List<String>? tools,
    bool? requiresApproval,
    String? skillContent,
    String? wallet,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) {
        data['name'] = name;
      }
      if (whenText != null) {
        data['when_text'] = whenText;
      }
      if (thenText != null) {
        data['then_text'] = thenText;
      }
      if (tools != null) {
        data['tools'] = tools;
      }
      if (requiresApproval != null) {
        data['requires_approval'] = requiresApproval;
      }
      if (skillContent != null) {
        data['skill_content'] = skillContent;
      }
      if (wallet != null) {
        data['wallet'] = wallet;
      }

      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.skillUpdate(skillId),
        data: data,
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from skill update');
      }

      // Backend returns {"skill": {...}}
      final skillJson = body['skill'] as Map<String, dynamic>? ?? body;
      final result = SkillModel.fromJson(skillJson);

      AppLogger.info('Skill updated: ${result.id}', tag: 'SkillService');
      return result;
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      AppLogger.error(
        'Failed to update skill $skillId',
        tag: 'SkillService',
        error: e,
      );
      throw const NetworkException(
        'Unable to connect. Please check your internet.',
      );
    }
  }

  /// Delete a skill from the backend.
  ///
  /// Sends `DELETE /api/skills/{id}`. Also removes the skill from any
  /// agent's `skill_ids` and cleans up the SKILL.md file on disk.
  Future<void> delete(String skillId) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.skillDelete(skillId),
      );
      AppLogger.info('Skill deleted: $skillId', tag: 'SkillService');
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      AppLogger.error(
        'Failed to delete skill $skillId',
        tag: 'SkillService',
        error: e,
      );
      throw const NetworkException(
        'Unable to connect. Please check your internet.',
      );
    }
  }

  /// Pause or resume a skill.
  ///
  /// Sends `PATCH /api/skills/{id}/status` with `{status: "paused"}`
  /// or `{status: "active"}`. The backend updates the scheduler job
  /// accordingly.
  Future<void> updateStatus({
    required String skillId,
    required String status,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.skillStatus(skillId),
        data: {'status': status},
      );
      AppLogger.info('Skill $skillId status → $status', tag: 'SkillService');
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      AppLogger.error(
        'Failed to update skill status',
        tag: 'SkillService',
        error: e,
      );
      throw const NetworkException(
        'Unable to connect. Please check your internet.',
      );
    }
  }
}

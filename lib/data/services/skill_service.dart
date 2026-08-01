import 'package:dio/dio.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
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
}

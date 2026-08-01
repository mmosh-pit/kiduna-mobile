import 'package:dio/dio.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../models/ally_agent_model.dart';

/// Fetches the system ally agent from the kinship-agent API.
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
  ///
  /// Returns the [AllyAgentModel] containing the ally's id, name, and
  /// metadata.
  ///
  /// Throws [NotFoundException] if no ally is seeded, [ServerException],
  /// [NetworkException], or [UnauthorizedException] on failure.
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
}

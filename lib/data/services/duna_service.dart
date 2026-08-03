import 'package:dio/dio.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../models/duna_model.dart';

/// Fetches DUNA registrations from the kinship-studio API.
///
/// Uses [ApiClient.studioDio] — the dunas GET endpoint returns the genesis
/// row to anonymous callers, so no auth token is required.
class DunaService {
  DunaService._();

  static final DunaService instance = DunaService._();

  Dio get _dio => ApiClient.instance.studioDio;

  /// Fetch the genesis duna and the caller's own dunas.
  ///
  /// Sends `GET /api/v1/dunas`.
  Future<DunasResponse> fetchDunas() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.dunas);

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from dunas endpoint');
      }

      final result = DunasResponse.fromJson(body);
      AppLogger.info(
        'Dunas loaded: genesis=${result.genesis?.name ?? "none"}, '
        'count=${result.dunas.length}',
        tag: 'DunaService',
      );
      return result;
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      AppLogger.error(
        'Failed to fetch dunas',
        tag: 'DunaService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const NetworkException(
        'Unable to load ecosystem. Please check your connection.',
      );
    }
  }

  /// Create an organization under the Genesis DUNA.
  ///
  /// Sends `POST /api/v1/dunas/organizations`. Auth token is forwarded via
  /// the studio Dio instance headers.
  Future<DunaModel> createOrganization({
    required String name,
    required String purpose,
    required String email,
    String? registration,
    String? authToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.dunasOrganizations,
        data: {
          'name': name,
          'purpose': purpose,
          'email': email,
          if (registration != null && registration.isNotEmpty)
            'registration': registration,
        },
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from create organization');
      }

      final org = DunaModel.fromJson(body);
      AppLogger.info(
        'Organization created: ${org.name} (id=${org.id})',
        tag: 'DunaService',
      );
      return org;
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) {
        throw const UnauthorizedException(
          'Please sign in to create an organization.',
        );
      }
      if (statusCode == 404) {
        throw const NotFoundException(
          'Genesis DUNA not found. Create the ecosystem first.',
        );
      }
      AppLogger.error(
        'Failed to create organization',
        tag: 'DunaService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const NetworkException(
        'Unable to create organization. Please try again.',
      );
    }
  }
}

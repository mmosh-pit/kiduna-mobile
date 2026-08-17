import 'package:dio/dio.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../models/alliance_model.dart';

/// Communicates with the kinship-backend Alliance API.
///
/// Uses [ApiClient.authDio] — alliance endpoints live in kinship-backend now.
class AllianceService {
  AllianceService._();

  static final AllianceService instance = AllianceService._();

  Dio get _dio => ApiClient.instance.authDio;

  /// Create an Alliance with inline Squads wallet creation.
  ///
  /// Sends `POST /alliances` to kinship-backend. If `walletEnabled` is true,
  /// the backend creates the Squads multisig on-chain and returns the PDAs
  /// in the same response.
  Future<AllianceModel> createAlliance({
    required String name,
    required String handle,
    String? description,
    String? purpose,
    String visibility = 'public',
    bool walletEnabled = true,
    String? authToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.alliances,
        data: {
          'name': name,
          'handle': handle,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (purpose != null && purpose.isNotEmpty) 'purpose': purpose,
          'visibility': visibility,
          'walletEnabled': walletEnabled,
        },
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from create alliance');
      }

      final allianceJson =
          body['alliance'] as Map<String, dynamic>? ?? body;
      final alliance = AllianceModel.fromJson(allianceJson);

      AppLogger.info(
        'Alliance created: ${alliance.name} (id=${alliance.id}), '
        'wallet: ${alliance.multisigPda ?? "none"}',
        tag: 'AllianceService',
      );

      return alliance;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) {
        throw const UnauthorizedException(
          'Please sign in to create an alliance.',
        );
      }
      if (statusCode == 409) {
        throw const ServerException(
          'That handle is already taken — pick another.',
        );
      }
      // Extract server error message for wallet/other failures.
      final serverMsg = e.response?.data is Map
          ? (e.response!.data as Map)['message'] as String?
          : null;
      AppLogger.error(
        'Failed to create alliance',
        tag: 'AllianceService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw NetworkException(
        serverMsg ?? 'Unable to create alliance. Please try again.',
      );
    }
  }

  /// List alliances the caller is a member of.
  ///
  /// Sends `GET /alliances`.
  Future<List<AllianceModel>> fetchAlliances({String? authToken}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.alliances,
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );

      final body = response.data;
      if (body == null) return [];

      final list = body['alliances'] as List<dynamic>? ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(AllianceModel.fromJson)
          .toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      AppLogger.error(
        'Failed to fetch alliances',
        tag: 'AllianceService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const NetworkException(
        'Unable to load alliances. Please check your connection.',
      );
    }
  }

  /// Check if a handle is available.
  ///
  /// Sends `GET /alliances/handle-availability?handle=...`.
  Future<bool> checkHandleAvailability(String handle) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.allianceHandleAvailability,
        queryParameters: {'handle': handle},
      );
      return response.data?['available'] as bool? ?? false;
    } on DioException {
      return false;
    }
  }
}
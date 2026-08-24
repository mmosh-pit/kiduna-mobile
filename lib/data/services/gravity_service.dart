import 'package:dio/dio.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../models/gravity_model.dart';

/// Fetches per-realm gravity scores from the kinship-agent API.
///
/// Returns parsed data or throws typed exceptions — no business logic.
class GravityService {
  GravityService._();

  static final GravityService instance = GravityService._();

  Dio get _dio => ApiClient.instance.dio;

  /// Fetch gravity scores for every realm visible to [walletAddress].
  Future<GravityResponse> fetchGravity(
    String walletAddress, {
    String? currentRealmId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.gravity(walletAddress),
        queryParameters: {
          'current_realm': ?currentRealmId,
        },
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from gravity endpoint');
      }

      final gravity = GravityResponse.fromJson(body);

      AppLogger.info(
        'Gravity loaded: ${gravity.realms.length} realms',
        tag: 'GravityService',
      );
      return gravity;
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      AppLogger.error(
        'Failed to fetch gravity',
        tag: 'GravityService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const NetworkException(
        'Unable to load realm data. Please check your connection.',
      );
    }
  }

  /// Set a gravity level override for a realm.
  Future<void> setLevelOverride({
    required String wallet,
    required String realmId,
    required String level,
  }) async {
    await _postOverride(wallet, realmId, 'set_level', level: level);
  }

  /// Pin a realm at its current gravity level.
  Future<void> pinRealmOverride({
    required String wallet,
    required String realmId,
    required String level,
  }) async {
    await _postOverride(wallet, realmId, 'pin', level: level);
  }

  /// Hide a realm from the atlas.
  Future<void> hideRealmOverride({
    required String wallet,
    required String realmId,
  }) async {
    await _postOverride(wallet, realmId, 'hide');
  }

  /// Remove an existing override for a realm.
  Future<void> removeOverride({
    required String wallet,
    required String realmId,
  }) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.gravityOverride,
        data: {
          'wallet_address': wallet,
          'realm_id': realmId,
        },
      );
    } on DioException catch (e) {
      _throwTyped(e);
    }
  }

  Future<void> _postOverride(
    String wallet,
    String realmId,
    String action, {
    String? level,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.gravityOverride,
        data: {
          'wallet_address': wallet,
          'realm_id': realmId,
          'action': action,
          'level': ?level,
        },
      );
    } on DioException catch (e) {
      _throwTyped(e);
    }
  }

  Never _throwTyped(DioException e) {
    if (e.error is AppException) {
      throw e.error!;
    }
    AppLogger.error(
      'Gravity override failed',
      tag: 'GravityService',
      error: e,
      stackTrace: e.stackTrace,
    );
    throw const ServerException('Gravity override request failed.');
  }
}

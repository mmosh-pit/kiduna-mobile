import 'package:dio/dio.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../models/realm_model.dart';

/// Communicates with the kinship-backend Realms API.
///
/// Unified service replacing [AllianceService], [InstitutionService], and
/// [DunaService]. All 11 Realm types are created/fetched through the same
/// `/realms` endpoints — the [type] field drives type-specific behavior.
class RealmService {
  RealmService._();

  static final RealmService instance = RealmService._();

  Dio get _dio => ApiClient.instance.authDio;

  /// Create any Realm type via `POST /realms`.
  ///
  /// The backend handles type-specific validation (e.g. Institution needs
  /// entityType in config, Organization must have an ecosystem parent).
  /// If [walletEnabled] is true, the backend creates a Squads multisig
  /// on-chain and returns the PDAs in the same response.
  Future<RealmModel> createRealm({
    required String name,
    required String type,
    String? handle,
    String? parentId,
    String? description,
    String? purpose,
    List<String>? tags,
    String? avatar,
    String visibility = 'public',
    Map<String, dynamic>? config,
    String? email,
    bool walletEnabled = false,
    String? authToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.realms,
        data: {
          'name': name,
          'type': type,
          if (handle != null && handle.isNotEmpty) 'handle': handle,
          if (parentId != null && parentId.isNotEmpty) 'parentId': parentId,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (purpose != null && purpose.isNotEmpty) 'purpose': purpose,
          if (tags != null && tags.isNotEmpty) 'tags': tags,
          if (avatar != null && avatar.isNotEmpty) 'avatar': avatar,
          'visibility': visibility,
          if (config != null && config.isNotEmpty) 'config': config,
          if (email != null && email.isNotEmpty) 'email': email,
          'walletEnabled': walletEnabled,
        },
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from create realm');
      }

      final realmJson = body['realm'] as Map<String, dynamic>? ?? body;
      final realm = RealmModel.fromJson(realmJson);

      AppLogger.info(
        'Realm created: ${realm.name} (type=${realm.type}, id=${realm.id}), '
        'wallet: ${realm.multisigPda ?? "none"}',
        tag: 'RealmService',
      );

      return realm;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) {
        throw const UnauthorizedException(
          'Please sign in to create a Realm.',
        );
      }
      if (statusCode == 409) {
        throw const ServerException(
          'That handle is already taken — pick another.',
        );
      }
      final serverMsg = e.response?.data is Map
          ? (e.response!.data as Map)['error'] as String? ??
            (e.response!.data as Map)['message'] as String?
          : null;
      AppLogger.error(
        'Failed to create realm',
        tag: 'RealmService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw NetworkException(
        serverMsg ?? 'Unable to create Realm. Please try again.',
      );
    }
  }

  /// List the caller's Realms via `GET /realms`.
  ///
  /// Optional filters: [type], [parentId], [tags].
  Future<List<RealmModel>> fetchRealms({
    String? type,
    String? parentId,
    List<String>? tags,
    String? authToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.realms,
        queryParameters: {
          if (type != null) 'type': type,
          if (parentId != null) 'parentId': parentId,
          if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
        },
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );

      final body = response.data;
      if (body == null) return [];

      final list = body['realms'] as List<dynamic>? ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(RealmModel.fromJson)
          .toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      AppLogger.error(
        'Failed to fetch realms',
        tag: 'RealmService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const NetworkException(
        'Unable to load Realms. Please check your connection.',
      );
    }
  }

  /// Fetch the genesis Ecosystem via `GET /realms/ecosystem` (no auth).
  Future<RealmModel?> fetchEcosystem() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.realmsEcosystem,
      );

      final body = response.data;
      if (body == null) return null;

      final eco = body['ecosystem'] as Map<String, dynamic>?;
      if (eco == null) return null;

      final ecosystem = RealmModel.fromJson(eco);
      AppLogger.info(
        'Ecosystem loaded: ${ecosystem.name}',
        tag: 'RealmService',
      );
      return ecosystem;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      AppLogger.error(
        'Failed to fetch ecosystem',
        tag: 'RealmService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const NetworkException(
        'Unable to load ecosystem. Please check your connection.',
      );
    }
  }

  /// Check if a handle is available via `GET /realms/handle-availability`.
  Future<bool> checkHandleAvailability(String handle) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.realmHandleAvailability,
        queryParameters: {'handle': handle},
      );
      return response.data?['available'] as bool? ?? false;
    } on DioException {
      return false;
    }
  }

  /// Fetch Realm tree (children) via `GET /realms/tree/:id`.
  Future<List<RealmModel>> fetchRealmChildren(String realmId, {String? authToken}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.realmTree(realmId),
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );

      final body = response.data;
      if (body == null) return [];

      final children = body['children'] as List<dynamic>? ?? [];
      return children
          .whereType<Map<String, dynamic>>()
          .map(RealmModel.fromJson)
          .toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      AppLogger.error(
        'Failed to fetch realm children',
        tag: 'RealmService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const NetworkException(
        'Unable to load Realm children. Please check your connection.',
      );
    }
  }
}

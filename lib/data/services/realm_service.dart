import 'package:dio/dio.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../models/realm_model.dart';

/// Communicates with the kinship-backend Realms API.
///
/// Unified service replacing [AllianceService], [InstitutionService], and
/// [DunaService]. All 12 Realm types (Taxonomy V0.09) are created/fetched
/// through the same `/realms` endpoints — the [type] field drives behavior.
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
    String? primaryTheme,
    String? primaryFocus,
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
          if (primaryTheme != null && primaryTheme.isNotEmpty)
            'primaryTheme': primaryTheme,
          if (primaryFocus != null && primaryFocus.isNotEmpty)
            'primaryFocus': primaryFocus,
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
          'type': ?type,
          'parentId': ?parentId,
          if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
        },
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );

      final body = response.data;
      if (body == null) return [];

      final list = body['realms'] as List<dynamic>? ?? [];
      final realms = list
          .whereType<Map<String, dynamic>>()
          .map(RealmModel.fromJson)
          .toList();
      return realms;
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

      return RealmModel.fromJson(eco);
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

  // ═══════════════════════════════════════════════════════════════
  // Added for Alliance feature
  // ═══════════════════════════════════════════════════════════════

  /// Fetch a single Realm by ID via `GET /realms/:id`.
  Future<RealmModel> fetchRealmById(String realmId, {String? authToken}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.realmById(realmId),
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from fetch realm');
      }

      final realmJson = body['realm'] as Map<String, dynamic>? ?? body;
      return RealmModel.fromJson(realmJson);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw const NetworkException('Unable to load Realm.');
    }
  }

  /// Update a member's role via `PATCH /realms/:id/members/:memberId`.
  Future<void> updateMemberRole({
    required String realmId,
    required String memberId,
    required String role,
    String? authToken,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '${ApiEndpoints.realmById(realmId)}/members/$memberId',
        data: {'role': role},
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );
      AppLogger.info('Updated member $memberId role to $role', tag: 'RealmService');
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['error'] as String?
          : null;
      throw NetworkException(msg ?? 'Unable to update member role.');
    }
  }

  /// Join a realm using an invitation code via `POST /realm-invites/join/:code`.
  Future<Map<String, dynamic>> joinWithCode({
    required String code,
    String? authToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/realm-invites/join/${code.trim().toUpperCase()}',
        data: {},
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );

      final body = response.data ?? {};
      AppLogger.info('Joined realm with code $code', tag: 'RealmService');
      return body;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['error'] as String?
          : null;
      throw NetworkException(msg ?? 'Unable to join. Invalid or expired code.');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Proposal endpoints — Squads on-chain operations
  // ═══════════════════════════════════════════════════════════════

  /// List all on-chain proposals for a realm.
  Future<List<Map<String, dynamic>>> fetchProposals(String realmId, {String? authToken}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.realmById(realmId)}/proposals',
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );
      final body = response.data ?? {};
      final proposals = body['proposals'] as List<dynamic>? ?? [];
      return proposals.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw const NetworkException('Unable to load proposals.');
    }
  }

  /// Create a USDC transfer proposal.
  Future<Map<String, dynamic>> createTransferUsdcProposal({
    required String realmId,
    required String to,
    required double amountUsdc,
    String? authToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.realmById(realmId)}/proposals/transfer-usdc',
        data: {'to': to, 'amountUsdc': amountUsdc},
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );
      return response.data ?? {};
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['error'] as String?
          : null;
      throw NetworkException(msg ?? 'Unable to create proposal.');
    }
  }

  /// Create a SOL transfer proposal.
  Future<Map<String, dynamic>> createTransferSolProposal({
    required String realmId,
    required String to,
    required double amountSol,
    String? authToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.realmById(realmId)}/proposals/transfer-sol',
        data: {'to': to, 'amountSol': amountSol},
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );
      return response.data ?? {};
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['error'] as String?
          : null;
      throw NetworkException(msg ?? 'Unable to create proposal.');
    }
  }

  /// Approve a pending proposal.
  Future<Map<String, dynamic>> approveProposal({
    required String realmId,
    required String transactionIndex,
    String? authToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.realmById(realmId)}/proposals/approve',
        data: {'transactionIndex': transactionIndex},
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );
      return response.data ?? {};
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['error'] as String?
          : null;
      throw NetworkException(msg ?? 'Unable to approve proposal.');
    }
  }

  /// Reject a proposal.
  Future<Map<String, dynamic>> rejectProposal({
    required String realmId,
    required String transactionIndex,
    String? authToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.realmById(realmId)}/proposals/reject',
        data: {'transactionIndex': transactionIndex},
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );
      return response.data ?? {};
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['error'] as String?
          : null;
      throw NetworkException(msg ?? 'Unable to reject proposal.');
    }
  }

  /// Execute an approved vault proposal.
  Future<Map<String, dynamic>> executeVaultProposal({
    required String realmId,
    required String transactionIndex,
    String? authToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.realmById(realmId)}/proposals/execute-vault',
        data: {'transactionIndex': transactionIndex},
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );
      return response.data ?? {};
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['error'] as String?
          : null;
      throw NetworkException(msg ?? 'Unable to execute proposal.');
    }
  }

  /// Propose adding a signer to the Squads multisig.
  Future<Map<String, dynamic>> addMemberProposal({
    required String realmId,
    required String wallet,
    String? authToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.realmById(realmId)}/proposals/add-member',
        data: {'wallet': wallet},
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );
      return response.data ?? {};
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['error'] as String?
          : null;
      throw NetworkException(msg ?? 'Unable to add member.');
    }
  }

  /// Propose removing a signer from the Squads multisig.
  Future<Map<String, dynamic>> removeMemberProposal({
    required String realmId,
    required String wallet,
    String? authToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.realmById(realmId)}/proposals/remove-member',
        data: {'wallet': wallet},
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );
      return response.data ?? {};
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['error'] as String?
          : null;
      throw NetworkException(msg ?? 'Unable to remove member.');
    }
  }

  /// Propose changing the approval threshold.
  Future<Map<String, dynamic>> changeThresholdProposal({
    required String realmId,
    required int newThreshold,
    String? authToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.realmById(realmId)}/proposals/change-threshold',
        data: {'newThreshold': newThreshold},
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );
      return response.data ?? {};
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['error'] as String?
          : null;
      throw NetworkException(msg ?? 'Unable to change threshold.');
    }
  }

  /// Fetch vault SOL + USDC balance for a realm wallet.
  Future<Map<String, dynamic>> fetchWalletBalance(
    String realmId, {
    String? authToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.realmById(realmId)}/wallet-balance',
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );
      return response.data ?? {};
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw const NetworkException('Unable to fetch wallet balance.');
    }
  }

  /// Fetch vault transaction history for a realm wallet.
  Future<List<Map<String, dynamic>>> fetchWalletTransactions(
    String realmId, {
    int limit = 10,
    String? authToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.realmById(realmId)}/wallet-transactions',
        queryParameters: {'limit': limit},
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );
      final body = response.data ?? {};
      final txns = body['transactions'] as List<dynamic>? ?? [];
      return txns.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw const NetworkException('Unable to fetch transactions.');
    }
  }

  // ── Member management ──────────────────────────────────────────────────

  /// Remove a member via `DELETE /realms/:id/members/:memberId`.
  Future<void> removeMember({
    required String realmId,
    required String memberId,
  }) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.realmMemberRemove(realmId, memberId),
        data: {},
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      final msg = e.response?.data?['error'] as String?;
      throw ServerException(msg ?? 'Unable to remove member.');
    }
  }
}
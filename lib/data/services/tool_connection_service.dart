import 'package:dio/dio.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../models/saved_tool_model.dart';

/// Result from `POST /api/tools/verify` — stateless credential check.
class VerifyToolResult {
  const VerifyToolResult({
    required this.success,
    this.error,
    this.externalHandle,
    this.externalUserId,
  });

  final bool success;
  final String? error;
  final String? externalHandle;
  final String? externalUserId;

  factory VerifyToolResult.fromJson(Map<String, dynamic> json) {
    return VerifyToolResult(
      success: (json['success'] ?? false) as bool,
      error: json['error'] as String?,
      externalHandle: json['external_handle'] as String?,
      externalUserId: json['external_user_id'] as String?,
    );
  }
}

/// Manages wallet-level tool connections against `kinship-agent-be`.
///
/// All operations are scoped to a wallet address — tools are global to
/// the wallet, not per-agent.
class ToolConnectionService {
  ToolConnectionService._();
  static final instance = ToolConnectionService._();

  final Dio _dio = ApiClient.instance.dio;

  /// Verify tool credentials without saving.
  ///
  /// `POST /api/tools/verify` with `{tool_name, credentials}`.
  /// Returns success/failure + external handle if successful.
  Future<VerifyToolResult> verify({
    required String toolName,
    required Map<String, String> credentials,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.toolsVerify,
        data: {
          'tool_name': toolName,
          'credentials': credentials,
        },
      );

      final body = response.data;
      if (body == null) {
        return const VerifyToolResult(
          success: false,
          error: 'Empty response',
        );
      }
      return VerifyToolResult.fromJson(body);
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      return VerifyToolResult(
        success: false,
        error: e.message ?? 'Connection failed',
      );
    }
  }

  /// Save a verified tool to the wallet's global pool.
  ///
  /// `POST /api/tools/save` with `{wallet, tool_name, credentials}`.
  Future<bool> save({
    required String wallet,
    required String toolName,
    required Map<String, String> credentials,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.toolsSave,
        data: {
          'wallet': wallet,
          'tool_name': toolName,
          'credentials': credentials,
        },
      );

      final body = response.data;
      final success = (body?['success'] ?? false) as bool;
      if (success) {
        AppLogger.info(
          'Tool $toolName saved for wallet',
          tag: 'ToolConnectionService',
        );
      }
      return success;
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      AppLogger.warning(
        'Failed to save tool: ${e.message}',
        tag: 'ToolConnectionService',
      );
      return false;
    }
  }

  /// List all connected tool accounts for a wallet.
  ///
  /// `GET /api/tools/saved?wallet={wallet}`.
  Future<List<SavedToolModel>> listSaved(String wallet) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.toolsSaved(wallet),
      );

      final body = response.data;
      if (body == null) {
        return [];
      }

      final raw = body['tools'] as List<dynamic>? ?? [];
      final tools = raw
          .whereType<Map<String, dynamic>>()
          .map(SavedToolModel.fromJson)
          .toList();

      AppLogger.info(
        'Fetched ${tools.length} saved tools',
        tag: 'ToolConnectionService',
      );
      return tools;
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      AppLogger.warning(
        'Failed to list saved tools: ${e.message}',
        tag: 'ToolConnectionService',
      );
      return [];
    }
  }

  /// Disconnect a tool account.
  ///
  /// `DELETE /api/tools/saved/{id}?wallet={wallet}`.
  Future<bool> remove({
    required String wallet,
    required String id,
  }) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.toolsRemove(id, wallet),
      );

      final body = response.data;
      final success = (body?['success'] ?? true) as bool;
      if (success) {
        AppLogger.info(
          'Tool $id disconnected',
          tag: 'ToolConnectionService',
        );
      }
      return success;
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      AppLogger.warning(
        'Failed to disconnect tool: ${e.message}',
        tag: 'ToolConnectionService',
      );
      return false;
    }
  }
}
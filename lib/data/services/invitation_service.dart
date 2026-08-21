import 'package:dio/dio.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../models/invitation_request.dart';
import '../models/invitation_response.dart';

/// Creates invitation codes via the kinship-agent API.
///
/// Returns parsed data or throws typed exceptions — no business logic.
class InvitationService {
  InvitationService._();

  static final InvitationService instance = InvitationService._();

  Dio get _dio => ApiClient.instance.dio;

  /// Generate an invitation code.
  ///
  /// Sends `POST /api/v1/codes` with the form fields plus the creator's
  /// wallet. The auth interceptor adds the Bearer token automatically.
  ///
  /// Returns the [InvitationResponse] containing the generated code,
  /// deep-link URL, and personal message.
  ///
  /// Throws [ServerException], [NetworkException], [ValidationException],
  /// or [UnauthorizedException] on failure.
  Future<InvitationResponse> generate(InvitationRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.codes,
        data: request.toJson(),
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from code generation');
      }

      final result = InvitationResponse.fromJson(body);

      AppLogger.info(
        'Invitation generated: ${result.code}',
        tag: 'InvitationService',
      );
      return result;
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      AppLogger.error(
        'Failed to generate invitation',
        tag: 'InvitationService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const NetworkException(
        'Unable to connect. Please check your internet.',
      );
    }
  }
}

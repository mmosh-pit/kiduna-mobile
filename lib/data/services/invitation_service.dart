import 'package:dio/dio.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../models/invitation_request.dart';
import '../models/invitation_response.dart';

/// Creates realm invitations via the kinship-backend API.
///
/// Returns parsed data or throws typed exceptions — no business logic.
class InvitationService {
  InvitationService._();

  static final InvitationService instance = InvitationService._();

  Dio get _dio => ApiClient.instance.authDio;

  /// Generate a realm invitation.
  ///
  /// Sends `POST /realm-invites/:realmId` with the form fields.
  /// The auth interceptor adds the Bearer token automatically.
  ///
  /// Returns the [InvitationResponse] containing the generated code,
  /// deep-link URL, and personal message.
  ///
  /// Throws [ServerException], [NetworkException], [ValidationException],
  /// or [UnauthorizedException] on failure.
  Future<InvitationResponse> generate(InvitationRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.realmInviteCreate(request.realmId),
        data: request.toJson(),
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from invitation creation');
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
      final statusCode = e.response?.statusCode;
      final serverMsg = e.response?.data is Map
          ? (e.response!.data as Map)['message'] as String?
          : null;
      AppLogger.error(
        'Failed to generate invitation',
        tag: 'InvitationService',
        error: e,
        stackTrace: e.stackTrace,
      );
      if (statusCode == 401) {
        throw const UnauthorizedException(
          'Please sign in to create an invitation.',
        );
      }
      if (statusCode == 403) {
        throw UnauthorizedException(
          serverMsg ?? 'You do not have permission to invite to this realm.',
        );
      }
      if (statusCode == 400) {
        throw ValidationException(
          serverMsg ?? 'Invalid invitation details. Please check your inputs.',
        );
      }
      if (statusCode == 409) {
        throw ConflictException(
          serverMsg ?? 'This person is already a member.',
        );
      }
      throw NetworkException(
        serverMsg ?? 'Unable to create invitation. Please try again.',
      );
    }
  }
}

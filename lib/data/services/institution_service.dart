import 'package:dio/dio.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../models/institution_model.dart';

/// Communicates with the kinship-backend Institution API.
///
/// Uses [ApiClient.authDio] — institution endpoints live in kinship-backend.
class InstitutionService {
  InstitutionService._();

  static final InstitutionService instance = InstitutionService._();

  Dio get _dio => ApiClient.instance.authDio;

  /// Create an Institution with inline Squads wallet creation.
  ///
  /// Sends `POST /institutions` to kinship-backend. Wallet first, DB second —
  /// if wallet creation fails, no DB record is created and the error is thrown.
  Future<InstitutionModel> createInstitution({
    required String name,
    required String handle,
    String? description,
    String? purpose,
    String entityType = 'company',
    String? standingDocUrl,
    String? standingDescription,
    String? registrationDomain,
    String? designateContact,
    String? designateEmail,
    String? address,
    bool walletEnabled = true,
    String? authToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.institutions,
        data: {
          'name': name,
          'handle': handle,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (purpose != null && purpose.isNotEmpty) 'purpose': purpose,
          'entityType': entityType,
          if (standingDocUrl != null && standingDocUrl.isNotEmpty)
            'standingDocUrl': standingDocUrl,
          if (standingDescription != null && standingDescription.isNotEmpty)
            'standingDescription': standingDescription,
          if (registrationDomain != null && registrationDomain.isNotEmpty)
            'registrationDomain': registrationDomain,
          if (designateContact != null && designateContact.isNotEmpty)
            'designateContact': designateContact,
          if (designateEmail != null && designateEmail.isNotEmpty)
            'designateEmail': designateEmail,
          if (address != null && address.isNotEmpty) 'address': address,
          'walletEnabled': walletEnabled,
        },
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from create institution');
      }

      final instJson =
          body['institution'] as Map<String, dynamic>? ?? body;
      final institution = InstitutionModel.fromJson(instJson);

      AppLogger.info(
        'Institution created: ${institution.name} (id=${institution.id}), '
        'wallet: ${institution.multisigPda ?? "none"}',
        tag: 'InstitutionService',
      );

      return institution;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) {
        throw const UnauthorizedException(
          'Please sign in to create an institution.',
        );
      }
      if (statusCode == 409) {
        throw const ServerException(
          'That handle is already taken — pick another.',
        );
      }
      final serverMsg = e.response?.data is Map
          ? (e.response!.data as Map)['message'] as String?
          : null;
      AppLogger.error(
        'Failed to create institution',
        tag: 'InstitutionService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw NetworkException(
        serverMsg ?? 'Unable to create institution. Please try again.',
      );
    }
  }

  /// Check if a handle is available.
  ///
  /// Sends `GET /institutions/handle-availability?handle=...`.
  Future<bool> checkHandleAvailability(String handle) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.institutionHandleAvailability,
        queryParameters: {'handle': handle},
      );
      return response.data?['available'] as bool? ?? false;
    } on DioException {
      return false;
    }
  }
}

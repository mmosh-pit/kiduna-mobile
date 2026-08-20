import 'package:dio/dio.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../../data/models/realm_model.dart';

class RealmService {
  RealmService._();

  static final RealmService instance = RealmService._();

  Dio get _authDio => ApiClient.instance.authDio;

  Future<RealmModel?> fetchEcosystem() async {
    try {
      final response = await _authDio.get<Map<String, dynamic>>(
        ApiEndpoints.realmsEcosystem,
      );

      final body = response.data;
      if (body == null) return null;

      final eco = body['ecosystem'];
      if (eco == null) return null;

      return RealmModel.fromJson(eco as Map<String, dynamic>);
    } on DioException catch (e, st) {
      _handleDioError(e, st, 'fetchEcosystem');
    }
  }

  Never _handleDioError(DioException e, StackTrace st, String method) {
    AppLogger.error(
      'Realm $method failed',
      tag: 'RealmService',
      error: e,
      stackTrace: st,
    );

    if (e.error is AppException) {
      throw e.error!;
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw const ApiTimeoutException();
    }

    if (e.type == DioExceptionType.connectionError) {
      throw const NetworkException();
    }

    final statusCode = e.response?.statusCode;
    switch (statusCode) {
      case 401:
      case 403:
        throw const UnauthorizedException();
      case 404:
        throw const NotFoundException();
      default:
        throw const ServerException();
    }
  }
}

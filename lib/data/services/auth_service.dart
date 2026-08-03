import 'package:dio/dio.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../models/user_model.dart';

/// Raw login / token-verify calls against kinship-backend.
///
/// Returns parsed data or throws typed exceptions — no business logic.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  Dio get _dio => ApiClient.instance.authDio;

  /// Login with email and password.
  ///
  /// Sends `POST /login` with `{ handle: email, password: password }`.
  /// Returns `(token, user)` on success.
  ///
  /// Throws [UnauthorizedException] on 401, [ServerException] on 5xx,
  /// [NetworkException] on connection failure.
  Future<({String token, UserModel user})> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {'handle': email, 'password': password},
      );

      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from login');
      }

      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid response structure');
      }

      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw const ServerException('No token in login response');
      }

      final userJson = data['user'] as Map<String, dynamic>?;
      if (userJson == null) {
        throw const ServerException('No user data in login response');
      }

      final user = UserModel.fromJson(userJson);

      AppLogger.info('Login successful', tag: 'AuthService');
      return (token: token, user: user);
    } on DioException catch (e) {
      // ErrorInterceptor already mapped the DioException.error to a typed
      // AppException — rethrow it directly.
      if (e.error is AppException) {
        throw e.error!;
      }
      AppLogger.error(
        'Login failed',
        tag: 'AuthService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const NetworkException(
        'Unable to connect. Please check your internet.',
      );
    }
  }

  /// Verify an existing token and get fresh user data.
  ///
  /// Sends `GET /is-auth` with `Authorization: Bearer <token>`.
  /// Returns the [UserModel] on success.
  ///
  /// Throws [UnauthorizedException] when the token is invalid or expired.
  Future<UserModel> checkAuth(String token) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.isAuth,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final body = response.data;
      if (body == null) {
        throw const UnauthorizedException('Empty response from auth check');
      }

      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const UnauthorizedException('Invalid response structure');
      }

      final isAuth = data['is_auth'] as bool? ?? false;
      if (!isAuth) {
        throw const UnauthorizedException('Session expired');
      }

      final userJson = data['user'] as Map<String, dynamic>?;
      if (userJson == null) {
        throw const UnauthorizedException('No user data in auth response');
      }

      final user = UserModel.fromJson(userJson);

      AppLogger.debug('Auth check passed', tag: 'AuthService');
      return user;
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      AppLogger.error(
        'Auth check failed',
        tag: 'AuthService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const UnauthorizedException('Unable to verify session');
    }
  }
}

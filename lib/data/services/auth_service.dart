import 'package:dio/dio.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../../data/local/secure_storage.dart';
import '../../data/models/user_model.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  Dio get _authDio => ApiClient.instance.authDio;

  // ─── Visitor signup flow ──────────────────────────────────────

  Future<void> generateOtp({required String email}) async {
    try {
      final response = await _authDio.post(
        ApiEndpoints.generateOtp,
        data: {'type': 'email', 'email': email},
      );
      final body = response.data as Map<String, dynamic>;
      if (body['status'] != true) {
        final message = body['message'] as String? ?? 'Failed to send code.';
        if (message.contains('already exists')) {
          throw ConflictException(message);
        }
        throw ValidationException(message);
      }
    } on DioException catch (e, st) {
      _handleDioError(e, st, 'generateOtp');
    }
  }

  Future<void> verifyOtp({required String email, required String otp}) async {
    try {
      final response = await _authDio.post(
        ApiEndpoints.verifyOtp,
        data: {'email': email, 'otp': otp, 'type': 'email'},
      );
      final body = response.data as Map<String, dynamic>;
      if (body['status'] != true) {
        final message = body['message'] as String? ?? 'Invalid code.';
        throw ValidationException(message);
      }
    } on DioException catch (e, st) {
      _handleDioError(e, st, 'verifyOtp');
    }
  }

  Future<void> resendOtp({required String email}) async {
    try {
      final response = await _authDio.post(
        ApiEndpoints.resendOtp,
        data: {'type': 'email', 'email': email},
      );
      final body = response.data as Map<String, dynamic>;
      if (body['status'] != true) {
        throw ValidationException(
          body['message'] as String? ?? 'Failed to resend code.',
        );
      }
    } on DioException catch (e, st) {
      _handleDioError(e, st, 'resendOtp');
    }
  }

  // ── SMS OTP ──────────────────────────────────────────────────────────────

  Future<void> generateSmsOtp({
    required String mobile,
    required String countryCode,
    String? email,
  }) async {
    try {
      final response = await _authDio.post(
        ApiEndpoints.generateOtp,
        data: {
          'type': 'sms',
          'mobile': mobile,
          'countryCode': countryCode,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );
      final body = response.data as Map<String, dynamic>;
      if (body['status'] != true) {
        final message =
            body['message'] as String? ?? 'Failed to send SMS code.';
        if (message.contains('already exists')) {
          throw ConflictException(message);
        }
        throw ValidationException(message);
      }
    } on DioException catch (e, st) {
      _handleDioError(e, st, 'generateSmsOtp');
    }
  }

  Future<void> verifySmsOtp({
    required String mobile,
    required String otp,
  }) async {
    try {
      final response = await _authDio.post(
        ApiEndpoints.verifyOtp,
        data: {'mobile': mobile, 'otp': otp, 'type': 'sms'},
      );
      final body = response.data as Map<String, dynamic>;
      if (body['status'] != true) {
        final message = body['message'] as String? ?? 'Invalid code.';
        throw ValidationException(message);
      }
    } on DioException catch (e, st) {
      _handleDioError(e, st, 'verifySmsOtp');
    }
  }

  Future<void> resendSmsOtp({
    required String mobile,
    required String countryCode,
    String? email,
  }) async {
    try {
      final response = await _authDio.post(
        ApiEndpoints.resendOtp,
        data: {
          'type': 'sms',
          'mobile': mobile,
          'countryCode': countryCode,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );
      final body = response.data as Map<String, dynamic>;
      if (body['status'] != true) {
        throw ValidationException(
          body['message'] as String? ?? 'Failed to resend SMS code.',
        );
      }
    } on DioException catch (e, st) {
      _handleDioError(e, st, 'resendSmsOtp');
    }
  }

  Future<AuthResponse> saveEarlyAccess({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authDio.post(
        ApiEndpoints.saveEarlyAccess,
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'hasVerifiedEmail': true,
          'currentStep': '4',
        },
      );
      final body = response.data as Map<String, dynamic>;
      if (body['status'] != true) {
        final message =
            body['message'] as String? ?? 'Failed to create account.';
        if (message.contains('already registered') ||
            message.contains('already exists')) {
          throw ConflictException(message);
        }
        throw ValidationException(message);
      }
      return AuthResponse.fromVisitorJson(body);
    } on DioException catch (e, st) {
      _handleDioError(e, st, 'saveEarlyAccess');
    }
  }

  Future<bool> validateKinshipCode({required String code}) async {
    try {
      final response = await _authDio.post(
        ApiEndpoints.hasCodeExist,
        data: {'code': code},
      );
      final body = response.data as Map<String, dynamic>;
      final result = body['result'] as Map<String, dynamic>?;
      return result?['exists'] == true;
    } on DioException catch (e, st) {
      _handleDioError(e, st, 'validateKinshipCode');
    }
  }

  Future<void> updateKinshipCode({
    required String email,
    required String referredCode,
    bool noCodeChecked = false,
  }) async {
    try {
      await _authDio.post(
        ApiEndpoints.upsertEarlyAccess,
        data: {
          'email': email,
          'referedKinshipCode': referredCode,
          'noCodeChecked': noCodeChecked,
          'currentStep': 'complete',
        },
      );
    } on DioException catch (e, st) {
      _handleDioError(e, st, 'updateKinshipCode');
    }
  }

  /// Join a realm using an invitation code (RLM-XXXXXX).
  ///
  /// Backend internally:
  ///   1. Validates the invite code
  ///   2. Adds user to realm_members
  ///   3. Resolves inviter's kinship code
  ///   4. Builds lineage automatically
  ///
  /// Returns a map with: success, realmId, realmName, role, lineageBuilt
  Future<Map<String, dynamic>> joinRealmViaInvite({
    required String code,
  }) async {
    try {
      // Auth token must be manually attached — authDio has no AuthInterceptor.
      // Token was saved in Step 3 (createAccount).
      final token = await SecureStorage.instance.getToken();
      final response = await _authDio.post(
        '/realm-invites/join/${code.trim().toUpperCase()}',
        data: {},
        options: token != null && token.isNotEmpty
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );
      final body = response.data as Map<String, dynamic>;

      if (body.containsKey('error')) {
        throw ValidationException(
          body['error'] as String? ?? 'Failed to join.',
        );
      }

      final data = body['data'] as Map<String, dynamic>? ?? {};
      return data;
    } on DioException catch (e, st) {
      _handleDioError(e, st, 'joinRealmViaInvite');
      return {};
    }
  }

  /// Preview an invitation code (no auth required).
  /// Returns realm name, type, role, validity.
  Future<Map<String, dynamic>> previewInvite({
    required String code,
  }) async {
    try {
      final response = await _authDio.get(
        '/realm-invites/join/${code.trim().toUpperCase()}',
      );
      return response.data as Map<String, dynamic>? ?? {};
    } on DioException catch (e, st) {
      _handleDioError(e, st, 'previewInvite');
      return {'valid': false, 'reason': 'Network error'};
    }
  }

  // ─── KIDUNA Token ──────────────────────────────────────────────────

  /// Get current KIDUNA token price.
  Future<Map<String, dynamic>> getKidunaRate() async {
    try {
      final response = await _authDio.get('/kiduna/rate');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e, st) {
      _handleDioError(e, st, 'getKidunaRate');
      return {'tokenPrice': 0.00001, 'currency': 'KIDUNA', 'priceCurrency': 'USDC'};
    }
  }

  /// Initiate KIDUNA purchase via Stripe onramp.
  Future<Map<String, dynamic>> purchaseKiduna({
    required double usdcAmount,
  }) async {
    try {
      final token = await SecureStorage.instance.getToken();
      final response = await _authDio.post(
        '/kiduna/purchase',
        data: {'usdcAmount': usdcAmount},
        options: token != null && token.isNotEmpty
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );
      final body = response.data as Map<String, dynamic>;
      if (body.containsKey('error')) {
        throw ValidationException(
          body['error'] as String? ?? 'Purchase failed.',
        );
      }
      return body['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e, st) {
      _handleDioError(e, st, 'purchaseKiduna');
      return {};
    }
  }

  /// Get user's current KIDUNA balance.
  Future<Map<String, dynamic>> getKidunaBalance() async {
    try {
      final token = await SecureStorage.instance.getToken();
      final response = await _authDio.get(
        '/kiduna/balance',
        options: token != null && token.isNotEmpty
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );
      final body = response.data as Map<String, dynamic>;
      return body['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e, st) {
      _handleDioError(e, st, 'getKidunaBalance');
      return {'balance': 0, 'totalPurchased': 0, 'totalSpent': 0};
    }
  }

  /// Verify Stripe onramp session and credit KIDUNA if payment complete.
  /// This is a fallback for when the webhook hasn't arrived yet.
  Future<Map<String, dynamic>> verifyOnrampSession({
    required String sessionId,
  }) async {
    try {
      final token = await SecureStorage.instance.getToken();
      final response = await _authDio.post(
        '/stripe/verify-onramp',
        data: {'sessionId': sessionId},
        options: token != null && token.isNotEmpty
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );
      return response.data as Map<String, dynamic>? ?? {};
    } on DioException catch (e, st) {
      _handleDioError(e, st, 'verifyOnrampSession');
      return {};
    }
  }

  // ─── Forgot password ─────────────────────────────────────────────

  Future<void> requestPasswordReset({required String email}) async {
    try {
      final response = await _authDio.post(
        ApiEndpoints.forgotPasswordVerification,
        data: {'email': email},
      );
      final body = response.data as Map<String, dynamic>;
      if (body['ok'] != true) {
        throw const ServerException('Failed to send reset code.');
      }
    } on DioException catch (e, st) {
      _handleDioError(e, st, 'requestPasswordReset');
    }
  }

  Future<void> resetPassword({
    required String email,
    required int code,
    required String newPassword,
  }) async {
    try {
      final response = await _authDio.post(
        ApiEndpoints.forgotPasswordVerification,
        data: {'email': email, 'code': code, 'newPassword': newPassword},
      );
      final body = response.data as Map<String, dynamic>;
      if (body['ok'] != true) {
        throw const ServerException('Failed to reset password.');
      }
    } on DioException catch (e, st) {
      _handleDioError(e, st, 'resetPassword');
    }
  }

  // ─── Login ──────────────────────────────────────────────────────

  Future<({String token, UserModel user})> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authDio.post<Map<String, dynamic>>(
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

  // ─── Auth check ─────────────────────────────────────────────────

  Future<UserModel> checkAuth(String token) async {
    try {
      final response = await _authDio.get<Map<String, dynamic>>(
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

  // ─── Error handling ───────────────────────────────────────────

  Never _handleDioError(DioException e, StackTrace st, String method) {
    AppLogger.error(
      'Auth $method failed',
      tag: 'AuthService',
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
    final errorBody = e.response?.data;
    final errorCode = errorBody is Map<String, dynamic>
        ? (errorBody['error'] as String?) ?? (errorBody['message'] as String?)
        : null;

    switch (statusCode) {
      case 400:
        if (errorCode == 'invalid-credentials') {
          throw const ValidationException('Invalid email or password.');
        }
        throw ValidationException(errorCode ?? 'Bad request.');
      case 401:
      case 403:
        throw const UnauthorizedException();
      case 404:
        throw const NotFoundException();
      case 409:
        throw ConflictException(
          errorCode ?? 'An account with this email already exists.',
        );
      default:
        throw const ServerException();
    }
  }
}
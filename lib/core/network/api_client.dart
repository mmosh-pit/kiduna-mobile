import 'package:dio/dio.dart';

import '../../config/constants.dart';
import '../../config/env.dart';
import 'api_interceptors.dart';

/// Singleton Dio HTTP client for all API calls.
///
/// Every service must use this instance — never create a standalone Dio.
/// Base URL comes from `Env.apiBaseUrl`; auth tokens are injected
/// automatically by [AuthInterceptor]; errors are mapped to typed exceptions
/// by [ErrorInterceptor].
///
/// Call [init] once during app startup (after dotenv is loaded) before making
/// any requests. [tokenProvider] should return the stored auth token, or
/// `null` when unauthenticated.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  late final Dio dio;
  late final Dio authDio;
  bool _initialized = false;

  /// Initialise the shared Dio instances.
  ///
  /// Must be called exactly once — typically in `main()` right after
  /// `dotenv.load()`. [tokenProvider] is the async callback that reads the
  /// current auth token from secure storage.
  void init({required Future<String?> Function() tokenProvider}) {
    if (_initialized) {
      return;
    }

    // ── Agent Dio (kinship-agent) ──
    dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(tokenProvider: tokenProvider),
      ErrorInterceptor(),
      AppLogInterceptor(),
    ]);

    // ── Auth Dio (kinship-backend) — now includes AuthInterceptor ──
    authDio = Dio(
      BaseOptions(
        baseUrl: Env.authApiUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    authDio.interceptors.addAll([
      AuthInterceptor(tokenProvider: tokenProvider),
      ErrorInterceptor(),
      AppLogInterceptor(),
    ]);

    _initialized = true;
  }

  /// A third Dio instance pointed at the **studio** backend
  /// (`Env.studioBaseUrl` — kinship-studio Next.js).  Used for dunas, markets,
  /// and other studio-specific endpoints.  No auth interceptor — the dunas GET
  /// endpoint returns the genesis row to anonymous callers.
  late final Dio studioDio = Dio(
    BaseOptions(
      baseUrl: Env.studioBaseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )..interceptors.addAll([ErrorInterceptor(), AppLogInterceptor()]);
}

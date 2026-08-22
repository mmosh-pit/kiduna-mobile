import 'package:dio/dio.dart';

import '../../config/constants.dart';
import '../../config/env.dart';
import 'api_interceptors.dart';

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  late final Dio dio;
  late final Dio authDio;
  bool _initialized = false;

  void init({required Future<String?> Function() tokenProvider}) {
    if (_initialized) return;

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
}

import 'package:dio/dio.dart';

import '../../config/constants.dart';
import '../../config/env.dart';
import 'api_interceptors.dart';

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  late final Dio dio;
  bool _initialized = false;

  void init({required Future<String?> Function() tokenProvider}) {
    if (_initialized) return;

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

    _initialized = true;
  }

  late final Dio authDio = Dio(
    BaseOptions(
      baseUrl: Env.authApiUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )..interceptors.addAll([ErrorInterceptor(), AppLogInterceptor()]);
}

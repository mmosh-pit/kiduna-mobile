import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class Env {
  const Env._();

  static String _raw(String key) =>
      dotenv.isInitialized ? (dotenv.env[key] ?? '') : '';

  static String get apiBaseUrl => _raw('API_BASE_URL');
  static String get authApiUrl => _raw('AUTH_API_URL');
  static String get env => _raw('ENV');

  static bool get isProduction => env == 'prod';
  static bool get isConfigured =>
      apiBaseUrl.isNotEmpty && authApiUrl.isNotEmpty;
}

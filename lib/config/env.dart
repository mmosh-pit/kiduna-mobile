import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class Env {
  const Env._();

  static String _raw(String key) =>
      dotenv.isInitialized ? (dotenv.env[key] ?? '') : '';

  static String get apiBaseUrl => _raw('API_BASE_URL');
  static String get authApiUrl => _raw('AUTH_API_URL');
  static String get env => _raw('ENV');

  /// Public URL of the Flutter web app (used for browser-based flows
  /// launched from desktop, e.g. the KIDUNA purchase page).
  static String get webAppUrl => _raw('WEB_APP_URL');

  static bool get isProduction => env == 'prod';
  static String get googleClientId => _raw('GOOGLE_CLIENT_ID');
  static String get googleApiKey => _raw('GOOGLE_API_KEY');

  static bool get isConfigured =>
      apiBaseUrl.isNotEmpty && authApiUrl.isNotEmpty;
}
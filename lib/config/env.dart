import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime environments the app can build against.
enum Environment { dev, staging, prod }

/// Environment configuration.
///
/// Values are loaded at runtime from the bundled `.env` file by
/// `flutter_dotenv` (see `main`). `.env` is never committed and must hold only
/// non-sensitive config — it ships inside the app bundle. Never hardcode API
/// URLs or keys at call sites; read them here.
abstract class Env {
  const Env._();

  /// Reads a raw value from the loaded `.env`. Returns an empty string when
  /// dotenv has not been initialised (e.g. in unit tests) so reads never throw.
  static String _raw(String key) =>
      dotenv.isInitialized ? (dotenv.env[key] ?? '') : '';

  /// The active environment, resolved from `ENV`. Defaults to
  /// [Environment.dev] when unset.
  static Environment get current {
    switch (_raw('ENV')) {
      case 'prod':
        return Environment.prod;
      case 'staging':
        return Environment.staging;
      default:
        return Environment.dev;
    }
  }

  /// Base URL for all API calls, from `API_BASE_URL`.
  static String get apiBaseUrl => _raw('API_BASE_URL');

  /// Base URL for authentication calls (kinship-backend), from `AUTH_API_URL`.
  static String get authApiUrl => _raw('AUTH_API_URL');

  /// Whether the app is running against the production environment.
  static bool get isProduction => current == Environment.prod;

  /// Whether the required configuration was loaded. Asserted at app startup so
  /// a missing or empty `.env` fails loudly.
  static bool get isConfigured =>
      apiBaseUrl.isNotEmpty && authApiUrl.isNotEmpty;
}

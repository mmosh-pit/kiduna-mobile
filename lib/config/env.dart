/// Runtime environments the app can build against.
enum Environment { dev, staging, prod }

/// Environment configuration.
///
/// Values are supplied at build time via `--dart-define` so secrets are never
/// committed. Never hardcode API URLs or keys at call sites — read them here.
///
/// Example:
/// ```
/// flutter run --dart-define=ENV=prod \
///   --dart-define=API_BASE_URL=https://api.kinship.systems
/// ```
abstract class Env {
  const Env._();

  static const String _rawEnv = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  /// The active environment, resolved from the `ENV` define.
  static Environment get current {
    switch (_rawEnv) {
      case 'prod':
        return Environment.prod;
      case 'staging':
        return Environment.staging;
      default:
        return Environment.dev;
    }
  }

  /// Base URL for all API calls. Consumed by the network client (once added).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.dev.kinship.systems',
  );

  /// Whether the app is running against the production environment.
  static bool get isProduction => current == Environment.prod;
}

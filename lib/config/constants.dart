/// App-wide constant values.
///
/// Namespaced in an abstract class so they are never instantiated and always
/// referenced as `AppConstants.spacingMd`. Never hardcode durations, sizes, or
/// limits at call sites — add them here.
abstract class AppConstants {
  const AppConstants._();

  static const String appName = 'Kiduna';

  // Animation durations.
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration defaultAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Spacing scale.
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

  // Corner radii.
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 20;

  // Pagination.
  static const int defaultPageSize = 20;

  // Network timeouts.
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Let the web build into the app itself instead of the download page.
  ///
  /// On web the app normally sends an authenticated user to DownloadAppScreen,
  /// because the product ships as a mobile app. That makes the browser useless
  /// for development, so this opens it up — off by default, so a production
  /// web build still shows the download page with no source change:
  ///
  ///   flutter run -d chrome --dart-define=ALLOW_WEB_APP=true
  static const bool allowWebApp = bool.fromEnvironment('ALLOW_WEB_APP');

  /// True when this build should route web users to the download page.
  static bool webDownloadGate(bool isWeb) => isWeb && !allowWebApp;
}

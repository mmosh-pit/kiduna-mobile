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

  // Spacing scale — matches the design kit (4 → 64).
  static const double spacing1 = 4;
  static const double spacing2 = 8;
  static const double spacing3 = 12;
  static const double spacing4 = 16;
  static const double spacing5 = 20;
  static const double spacing6 = 24;
  static const double spacing8 = 32;
  static const double spacing10 = 40;
  static const double spacing12 = 48;
  static const double spacing16 = 64;

  // Legacy aliases — prefer the numbered scale above.
  static const double spacingXs = spacing1;
  static const double spacingSm = spacing2;
  static const double spacingMd = spacing4;
  static const double spacingLg = spacing6;
  static const double spacingXl = spacing8;

  // Corner radii — match KidunaMetrics (the source of truth).
  static const double radiusSm = 5;
  static const double radiusMd = 6;
  static const double radiusLg = 14;

  // Pagination.
  static const int defaultPageSize = 20;

  // Network timeouts.
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

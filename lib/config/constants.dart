/// App-wide constant values.
abstract class AppConstants {
  const AppConstants._();

  static const String appName = 'Kiduna';

  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration defaultAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  static const double spacing1 = 4;
  static const double spacing2 = 8;
  static const double spacing3 = 12;
  static const double spacing4 = 16;
  static const double spacing5 = 20;
  static const double spacing6 = 24;
  static const double spacing8 = 32;
  static const double spacing12 = 48;

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

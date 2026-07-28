import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/config/env.dart';

void main() {
  test('defaults to the dev environment when no ENV define is supplied', () {
    expect(Env.current, Environment.dev);
    expect(Env.isProduction, isFalse);
  });

  test('reports not configured when API_BASE_URL is absent', () {
    // The test harness runs without --dart-define-from-file, so no base URL is
    // injected and there is no hardcoded fallback.
    expect(Env.apiBaseUrl, isEmpty);
    expect(Env.isConfigured, isFalse);
  });
}

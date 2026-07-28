import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/config/env.dart';

void main() {
  test('defaults to the dev environment', () {
    expect(Env.current, Environment.dev);
    expect(Env.isProduction, isFalse);
  });

  test('provides a non-empty API base URL', () {
    expect(Env.apiBaseUrl, isNotEmpty);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/config/constants.dart';

void main() {
  test('exposes the app name and an ascending spacing scale', () {
    expect(AppConstants.appName, 'Kiduna');
    expect(AppConstants.spacingSm, greaterThan(AppConstants.spacingXs));
    expect(AppConstants.spacingMd, greaterThan(AppConstants.spacingSm));
    expect(AppConstants.spacingXl, greaterThan(AppConstants.spacingLg));
  });

  test('exposes a positive default page size', () {
    expect(AppConstants.defaultPageSize, greaterThan(0));
  });
}

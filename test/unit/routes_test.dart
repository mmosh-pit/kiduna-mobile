import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/app/routes.dart';

void main() {
  test('the Field is the root path', () {
    expect(Routes.field, '/');
  });

  test('the AEV has its own studio path', () {
    expect(Routes.aev, '/studio/aev');
  });

  test('builds a concrete user-profile path from an id', () {
    expect(Routes.userProfilePath('42'), '/user/42');
  });
}

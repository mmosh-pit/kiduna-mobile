import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/app/routes.dart';

void main() {
  test('the Field is the root path', () {
    expect(Routes.field, '/');
  });

  test('builds a concrete user-profile path from an id', () {
    expect(Routes.userProfilePath('42'), '/user/42');
  });
}

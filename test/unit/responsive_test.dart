import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/core/utils/responsive.dart';

void main() {
  group('screenClassForWidth', () {
    test('is mobile below the tablet breakpoint', () {
      expect(screenClassForWidth(0), ScreenClass.mobile);
      expect(screenClassForWidth(599), ScreenClass.mobile);
    });

    test('is tablet from the tablet breakpoint up to desktop', () {
      expect(screenClassForWidth(600), ScreenClass.tablet);
      expect(screenClassForWidth(1023), ScreenClass.tablet);
    });

    test('is desktop at and above the desktop breakpoint', () {
      expect(screenClassForWidth(1024), ScreenClass.desktop);
      expect(screenClassForWidth(1920), ScreenClass.desktop);
    });
  });
}

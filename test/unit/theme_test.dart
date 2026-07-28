import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/config/theme.dart';

void main() {
  test('light and dark themes use Material 3', () {
    expect(AppTheme.light.useMaterial3, isTrue);
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
  });

  test('uses Avenir as the base font family', () {
    expect(AppTheme.light.textTheme.bodyMedium?.fontFamily, 'Avenir');
    expect(AppTheme.light.textTheme.titleLarge?.fontFamily, 'Avenir');
  });

  test('uses GoudyHeavyface for display styles', () {
    expect(AppTheme.light.textTheme.displayLarge?.fontFamily, 'GoudyHeavyface');
    expect(AppTheme.light.textTheme.displayMedium?.fontFamily, 'GoudyHeavyface');
    expect(AppTheme.light.textTheme.displaySmall?.fontFamily, 'GoudyHeavyface');
  });
}

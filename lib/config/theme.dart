import 'package:flutter/material.dart';

import 'theme_extensions.dart';

/// Central app theme — the single source of styling truth.
abstract class AppTheme {
  const AppTheme._();

  static const Color _seedColor = Color(0xFF2E7D6B);
  static const String bodyFontFamily = 'Avenir';
  static const String displayFontFamily = 'GoudyHeavyface';

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamily: bodyFontFamily,
      appBarTheme: const AppBarTheme(centerTitle: true),
      extensions: const <ThemeExtension<dynamic>>[
        KidunaColors.standard,
        KidunaText.standard,
        KidunaMetrics.standard,
        KidunaShadows.standard,
      ],
    );
    return base.copyWith(textTheme: _applyDisplayFont(base.textTheme));
  }

  static TextTheme _applyDisplayFont(TextTheme textTheme) {
    return textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.copyWith(
        fontFamily: displayFontFamily,
      ),
      displayMedium: textTheme.displayMedium?.copyWith(
        fontFamily: displayFontFamily,
      ),
      displaySmall: textTheme.displaySmall?.copyWith(
        fontFamily: displayFontFamily,
      ),
    );
  }
}

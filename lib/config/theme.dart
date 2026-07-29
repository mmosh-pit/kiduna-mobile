import 'package:flutter/material.dart';

import 'theme_extensions.dart';

/// Central app theme — the single source of styling truth.
///
/// Widgets read styling through `Theme.of(context)`; never hardcode colors,
/// text styles, or spacing at call sites.
abstract class AppTheme {
  const AppTheme._();

  static const Color _seedColor = Color(0xFF2E7D6B);

  /// Base font used for all text (body, labels, titles).
  static const String bodyFontFamily = 'Avenir';

  /// Display font used for large headings.
  static const String displayFontFamily = 'GoudyHeavyface';

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );
    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamily: bodyFontFamily,
      appBarTheme: const AppBarTheme(centerTitle: true),
      extensions: const <ThemeExtension<dynamic>>[KidunaColors.standard],
    );
    return base.copyWith(textTheme: _applyDisplayFont(base.textTheme));
  }

  /// Applies [displayFontFamily] to the large display styles while leaving the
  /// rest on [bodyFontFamily].
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

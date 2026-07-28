import 'package:flutter/material.dart';

/// Convenience accessors on [BuildContext] for theme, media query, and sizing.
///
/// Prefer these over repeatedly calling `Theme.of(context)` / `MediaQuery.of`.
extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;

  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isMobile => screenWidth < 600;
}

import 'package:flutter/material.dart';

import '../../config/theme_extensions.dart';

/// Convenience accessors on [BuildContext] for theme and sizing.
extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;

  KidunaColors get kiduna =>
      Theme.of(this).extension<KidunaColors>() ?? KidunaColors.standard;

  KidunaText get kidunaText =>
      Theme.of(this).extension<KidunaText>() ?? KidunaText.standard;

  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;
}

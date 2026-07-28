import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Convenience accessors on [BuildContext] for localization, theme, media
/// query, and sizing.
///
/// Prefer these over repeatedly calling `Theme.of(context)` / `MediaQuery.of`.
extension ContextExtensions on BuildContext {
  /// Localized strings for the current locale. See lib/l10n/app_en.arb.
  AppLocalizations get l10n => AppLocalizations.of(this);

  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;

  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isMobile => screenWidth < 600;
}

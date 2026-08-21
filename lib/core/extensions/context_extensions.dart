import 'package:flutter/material.dart';

import '../../config/theme_extensions.dart';
import '../../l10n/app_localizations.dart';

/// Convenience accessors on [BuildContext] for localization, theme, media
/// query, and sizing.
///
/// Prefer these over repeatedly calling `Theme.of(context)` / `MediaQuery.of`.
extension ContextExtensions on BuildContext {
  /// Localized strings for the current locale. See lib/l10n/app_en.arb.
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;

  /// Kiduna Field palette tokens. Falls back to [KidunaColors.standard] if the
  /// extension is not registered on the active theme.
  KidunaColors get kiduna =>
      Theme.of(this).extension<KidunaColors>() ?? KidunaColors.standard;

  /// Kiduna Field typography tokens. Falls back to [KidunaText.standard].
  KidunaText get kidunaText =>
      Theme.of(this).extension<KidunaText>() ?? KidunaText.standard;

  /// Kiduna Field layout metrics. Falls back to [KidunaMetrics.standard].
  KidunaMetrics get metrics =>
      Theme.of(this).extension<KidunaMetrics>() ?? KidunaMetrics.standard;

  /// Kiduna Field shadow tokens. Falls back to [KidunaShadows.standard].
  KidunaShadows get shadows =>
      Theme.of(this).extension<KidunaShadows>() ?? KidunaShadows.standard;

  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isMobile => screenWidth < 600;
}

import 'package:flutter/material.dart';

/// Kiduna Field layout metrics — radii, hairline, icon sizes, and the desktop
/// breakpoint.
///
/// Values are taken exactly from the kiduna-studio-design-kit prototype
/// (`canonical-first-field.module.css`). They are fixed design primitives and
/// do not vary between light and dark. Read them via `context.metrics` rather
/// than writing raw numbers into widgets. Per-widget spacing (paddings, gaps)
/// lives with each Field widget as it is built.
@immutable
class KidunaMetrics extends ThemeExtension<KidunaMetrics> {
  const KidunaMetrics({
    required this.radiusXs,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusPanel,
    required this.radiusLg,
    required this.radiusXl,
    required this.radiusPill,
    required this.hairline,
    required this.enamelIcon,
    required this.kiEnamelIcon,
    required this.panelControl,
    required this.boundaryWidth,
    required this.desktopMinWidth,
  });

  /// Smallest radius (`4px` — buttons).
  final double radiusXs;

  /// Small control radius (`border-radius: 5px`).
  final double radiusSm;

  /// Default control radius (`6px` — primary buttons, inputs).
  final double radiusMd;

  /// Field panel radius (`10px`).
  final double radiusPanel;

  /// Card radius (`14px`).
  final double radiusLg;

  /// Large panel radius (`20px`).
  final double radiusXl;

  /// Fully rounded pills and chips (`9999px`).
  final double radiusPill;

  /// Hairline border width (`1px`).
  final double hairline;

  /// Realm-context enamel icon size (`--icon-size: 64px`).
  final double enamelIcon;

  /// Ki header enamel icon size (`--icon-size: 58px`).
  final double kiEnamelIcon;

  /// Panel chrome control button size (`17px`).
  final double panelControl;

  /// Field–Ki boundary column width (`7px`).
  final double boundaryWidth;

  /// Width at and above which the desktop Field–Ki split is shown; below it the
  /// layout reflows (`min-width: 1024px`).
  final double desktopMinWidth;

  /// Canonical Field metrics — matches the prototype exactly.
  static const KidunaMetrics standard = KidunaMetrics(
    radiusXs: 4,
    radiusSm: 5,
    radiusMd: 6,
    radiusPanel: 10,
    radiusLg: 14,
    radiusXl: 20,
    radiusPill: 9999,
    hairline: 1,
    enamelIcon: 64,
    kiEnamelIcon: 58,
    panelControl: 17,
    boundaryWidth: 7,
    desktopMinWidth: 1024,
  );

  @override
  KidunaMetrics copyWith({
    double? radiusXs,
    double? radiusSm,
    double? radiusMd,
    double? radiusPanel,
    double? radiusLg,
    double? radiusXl,
    double? radiusPill,
    double? hairline,
    double? enamelIcon,
    double? kiEnamelIcon,
    double? panelControl,
    double? boundaryWidth,
    double? desktopMinWidth,
  }) {
    return KidunaMetrics(
      radiusXs: radiusXs ?? this.radiusXs,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusPanel: radiusPanel ?? this.radiusPanel,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusXl: radiusXl ?? this.radiusXl,
      radiusPill: radiusPill ?? this.radiusPill,
      hairline: hairline ?? this.hairline,
      enamelIcon: enamelIcon ?? this.enamelIcon,
      kiEnamelIcon: kiEnamelIcon ?? this.kiEnamelIcon,
      panelControl: panelControl ?? this.panelControl,
      boundaryWidth: boundaryWidth ?? this.boundaryWidth,
      desktopMinWidth: desktopMinWidth ?? this.desktopMinWidth,
    );
  }

  @override
  KidunaMetrics lerp(covariant ThemeExtension<KidunaMetrics>? other, double t) {
    if (other is! KidunaMetrics) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

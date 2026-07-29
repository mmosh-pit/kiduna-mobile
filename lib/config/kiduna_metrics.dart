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
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusPanel,
    required this.radiusPill,
    required this.hairline,
    required this.enamelIcon,
    required this.kiEnamelIcon,
    required this.panelControl,
    required this.boundaryWidth,
    required this.desktopMinWidth,
  });

  /// Small control radius (`border-radius: 5px`).
  final double radiusSm;

  /// Default control radius (`6px` — primary buttons, inputs).
  final double radiusMd;

  /// Field panel radius (`10px`).
  final double radiusPanel;

  /// Fully rounded pills and chips (`999px`).
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
    radiusSm: 5,
    radiusMd: 6,
    radiusPanel: 10,
    radiusPill: 999,
    hairline: 1,
    enamelIcon: 64,
    kiEnamelIcon: 58,
    panelControl: 17,
    boundaryWidth: 7,
    desktopMinWidth: 1024,
  );

  @override
  KidunaMetrics copyWith({
    double? radiusSm,
    double? radiusMd,
    double? radiusPanel,
    double? radiusPill,
    double? hairline,
    double? enamelIcon,
    double? kiEnamelIcon,
    double? panelControl,
    double? boundaryWidth,
    double? desktopMinWidth,
  }) {
    return KidunaMetrics(
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusPanel: radiusPanel ?? this.radiusPanel,
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

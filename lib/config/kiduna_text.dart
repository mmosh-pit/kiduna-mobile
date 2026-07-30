import 'package:flutter/material.dart';

/// Font family registered in `pubspec.yaml` for display text.
const String _goudy = 'GoudyHeavyface';

/// Font family registered in `pubspec.yaml` for body and controls.
const String _avenir = 'Avenir';

/// Font family registered in `pubspec.yaml` for callouts, quotations, and asides.
const String _ibmPlexSans = 'IBMPlexSans';

/// Kiduna Field typography roles.
///
/// Sizes, weights, line-heights, and letter-spacing are taken exactly from the
/// kiduna-studio-design-kit prototype (`canonical-first-field.module.css`).
/// Goudy Heavyface carries headings and object identity; Avenir carries body,
/// labels, and operational text.
///
/// Styles intentionally carry no colour — the same role appears in gold, sky,
/// cream, or muted depending on context. Apply colour at the call site, e.g.
/// `context.kidunaText.eyebrow.copyWith(color: context.kiduna.gold)`.
/// Uppercase eyebrows are produced by the caller (`text.toUpperCase()`); CSS
/// `letter-spacing` in `em` is converted here to logical pixels.
@immutable
class KidunaText extends ThemeExtension<KidunaText> {
  const KidunaText({
    required this.displayHero,
    required this.displayLarge,
    required this.display,
    required this.h1Large,
    required this.h2,
    required this.headingLarge,
    required this.heading,
    required this.h4,
    required this.h5,
    required this.h6,
    required this.warning,
    required this.eyebrow,
    required this.eyebrowSmall,
    required this.micro,
    required this.label,
    required this.labelStrong,
    required this.bodySm,
    required this.bodySmall,
    required this.bodyBase,
    required this.body,
    required this.bodyLg,
    required this.bodyLarge,
    required this.caption,
    required this.callout,
  });

  /// Goudy 72/1.05 — hero display (`--fs-6xl`, h1 large).
  final TextStyle displayHero;

  /// Goudy 54/1.05 — large display heading (`--fs-5xl`, h1).
  final TextStyle displayLarge;

  /// Goudy 42/1 — the Ki title (`.kiHeader h2`, clamp max).
  final TextStyle display;

  /// Goudy 40/1.05 — large heading (`--fs-4xl`).
  final TextStyle h1Large;

  /// Goudy 30/1.2 — section heading (`--fs-3xl`, h2).
  final TextStyle h2;

  /// Goudy 25/1 — Possible Actions heading (`.actionPanel h3`).
  final TextStyle headingLarge;

  /// Goudy 24/1 — realm name and Inspect heading (`.realmContext h2`).
  final TextStyle heading;

  /// Goudy 20/1.2 — sub-heading (`--fs-xl`, h4).
  final TextStyle h4;

  /// Goudy 18/1.2 — small heading (`--fs-lg`, h5).
  final TextStyle h5;

  /// Goudy 16/1.2 — smallest heading (`--fs-base`, h6).
  final TextStyle h6;

  /// Goudy 26/1.1 — narrow-viewport warning (`.narrowWarning strong`).
  final TextStyle warning;

  /// Avenir 10/700, +1.8px tracking — gold or sky eyebrow (`.kiMessage span`).
  final TextStyle eyebrow;

  /// Avenir 9/700, +1.44px tracking — compact eyebrow (`.computeBalance span`).
  final TextStyle eyebrowSmall;

  /// Avenir 8/400 — the smallest labels (`.computeCard dt`, `.focusControl span`).
  final TextStyle micro;

  /// Avenir 10/400 — form labels and chips (`.taskForm label`, `.kiChits`).
  final TextStyle label;

  /// Avenir 10/700, +0.4px tracking — panel titles (`.panelChrome strong`).
  final TextStyle labelStrong;

  /// Avenir 11/1.45 — fact values and quiet body (`.factList strong`).
  final TextStyle bodySmall;

  /// Avenir 14/1.5 — small standard body (`--fs-sm`).
  final TextStyle bodySm;

  /// Avenir 16/1.5 — standard body text (`--fs-base`).
  final TextStyle bodyBase;

  /// Avenir 13/1.4 — default body and inputs (`.actionGrid strong`, inputs).
  final TextStyle body;

  /// Avenir 18/1.5 — large body text (`--fs-lg`).
  final TextStyle bodyLg;

  /// Avenir 19/1.58 — Ki conversational message (`.kiMessage p`, clamp max).
  final TextStyle bodyLarge;

  /// Avenir 12/1.5 — Ki invitation line and short prose (`.kiMessage strong`).
  final TextStyle caption;

  /// IBM Plex Sans 18/1.2 weight 500 — callout / quotation / aside.
  final TextStyle callout;

  /// Canonical Field typography — matches the prototype exactly.
  static const KidunaText standard = KidunaText(
    displayHero: TextStyle(
      fontFamily: _goudy,
      fontSize: 72,
      height: 1.05,
      fontWeight: FontWeight.w400,
    ),
    displayLarge: TextStyle(
      fontFamily: _goudy,
      fontSize: 54,
      height: 1.05,
      fontWeight: FontWeight.w400,
    ),
    display: TextStyle(
      fontFamily: _goudy,
      fontSize: 42,
      height: 1,
      fontWeight: FontWeight.w400,
    ),
    h1Large: TextStyle(
      fontFamily: _goudy,
      fontSize: 40,
      height: 1.05,
      fontWeight: FontWeight.w400,
    ),
    h2: TextStyle(
      fontFamily: _goudy,
      fontSize: 30,
      height: 1.2,
      fontWeight: FontWeight.w400,
    ),
    headingLarge: TextStyle(
      fontFamily: _goudy,
      fontSize: 25,
      height: 1,
      fontWeight: FontWeight.w400,
    ),
    heading: TextStyle(
      fontFamily: _goudy,
      fontSize: 24,
      height: 1,
      fontWeight: FontWeight.w400,
    ),
    h4: TextStyle(
      fontFamily: _goudy,
      fontSize: 20,
      height: 1.2,
      fontWeight: FontWeight.w400,
    ),
    h5: TextStyle(
      fontFamily: _goudy,
      fontSize: 18,
      height: 1.2,
      fontWeight: FontWeight.w400,
    ),
    h6: TextStyle(
      fontFamily: _goudy,
      fontSize: 16,
      height: 1.2,
      fontWeight: FontWeight.w400,
    ),
    warning: TextStyle(
      fontFamily: _goudy,
      fontSize: 26,
      height: 1.1,
      fontWeight: FontWeight.w400,
    ),
    eyebrow: TextStyle(
      fontFamily: _avenir,
      fontSize: 10,
      height: 1,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.8,
    ),
    eyebrowSmall: TextStyle(
      fontFamily: _avenir,
      fontSize: 9,
      height: 1,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.44,
    ),
    micro: TextStyle(
      fontFamily: _avenir,
      fontSize: 8,
      height: 1.2,
      fontWeight: FontWeight.w400,
    ),
    label: TextStyle(
      fontFamily: _avenir,
      fontSize: 10,
      height: 1.3,
      fontWeight: FontWeight.w400,
    ),
    labelStrong: TextStyle(
      fontFamily: _avenir,
      fontSize: 10,
      height: 1,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
    ),
    bodySmall: TextStyle(
      fontFamily: _avenir,
      fontSize: 11,
      height: 1.45,
      fontWeight: FontWeight.w400,
    ),
    bodySm: TextStyle(
      fontFamily: _avenir,
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w400,
    ),
    bodyBase: TextStyle(
      fontFamily: _avenir,
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w400,
    ),
    body: TextStyle(
      fontFamily: _avenir,
      fontSize: 13,
      height: 1.4,
      fontWeight: FontWeight.w400,
    ),
    bodyLg: TextStyle(
      fontFamily: _avenir,
      fontSize: 18,
      height: 1.5,
      fontWeight: FontWeight.w400,
    ),
    bodyLarge: TextStyle(
      fontFamily: _avenir,
      fontSize: 19,
      height: 1.58,
      fontWeight: FontWeight.w400,
    ),
    caption: TextStyle(
      fontFamily: _avenir,
      fontSize: 12,
      height: 1.4,
      fontWeight: FontWeight.w400,
    ),
    callout: TextStyle(
      fontFamily: _ibmPlexSans,
      fontSize: 18,
      height: 1.2,
      fontWeight: FontWeight.w500,
    ),
  );

  @override
  KidunaText copyWith({
    TextStyle? displayHero,
    TextStyle? displayLarge,
    TextStyle? display,
    TextStyle? h1Large,
    TextStyle? h2,
    TextStyle? headingLarge,
    TextStyle? heading,
    TextStyle? h4,
    TextStyle? h5,
    TextStyle? h6,
    TextStyle? warning,
    TextStyle? eyebrow,
    TextStyle? eyebrowSmall,
    TextStyle? micro,
    TextStyle? label,
    TextStyle? labelStrong,
    TextStyle? bodySm,
    TextStyle? bodySmall,
    TextStyle? bodyBase,
    TextStyle? body,
    TextStyle? bodyLg,
    TextStyle? bodyLarge,
    TextStyle? caption,
    TextStyle? callout,
  }) {
    return KidunaText(
      displayHero: displayHero ?? this.displayHero,
      displayLarge: displayLarge ?? this.displayLarge,
      display: display ?? this.display,
      h1Large: h1Large ?? this.h1Large,
      h2: h2 ?? this.h2,
      headingLarge: headingLarge ?? this.headingLarge,
      heading: heading ?? this.heading,
      h4: h4 ?? this.h4,
      h5: h5 ?? this.h5,
      h6: h6 ?? this.h6,
      warning: warning ?? this.warning,
      eyebrow: eyebrow ?? this.eyebrow,
      eyebrowSmall: eyebrowSmall ?? this.eyebrowSmall,
      micro: micro ?? this.micro,
      label: label ?? this.label,
      labelStrong: labelStrong ?? this.labelStrong,
      bodySm: bodySm ?? this.bodySm,
      bodySmall: bodySmall ?? this.bodySmall,
      bodyBase: bodyBase ?? this.bodyBase,
      body: body ?? this.body,
      bodyLg: bodyLg ?? this.bodyLg,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      caption: caption ?? this.caption,
      callout: callout ?? this.callout,
    );
  }

  @override
  KidunaText lerp(covariant ThemeExtension<KidunaText>? other, double t) {
    if (other is! KidunaText) {
      return this;
    }
    return KidunaText(
      displayHero: TextStyle.lerp(displayHero, other.displayHero, t)!,
      displayLarge: TextStyle.lerp(displayLarge, other.displayLarge, t)!,
      display: TextStyle.lerp(display, other.display, t)!,
      h1Large: TextStyle.lerp(h1Large, other.h1Large, t)!,
      h2: TextStyle.lerp(h2, other.h2, t)!,
      headingLarge: TextStyle.lerp(headingLarge, other.headingLarge, t)!,
      heading: TextStyle.lerp(heading, other.heading, t)!,
      h4: TextStyle.lerp(h4, other.h4, t)!,
      h5: TextStyle.lerp(h5, other.h5, t)!,
      h6: TextStyle.lerp(h6, other.h6, t)!,
      warning: TextStyle.lerp(warning, other.warning, t)!,
      eyebrow: TextStyle.lerp(eyebrow, other.eyebrow, t)!,
      eyebrowSmall: TextStyle.lerp(eyebrowSmall, other.eyebrowSmall, t)!,
      micro: TextStyle.lerp(micro, other.micro, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      labelStrong: TextStyle.lerp(labelStrong, other.labelStrong, t)!,
      bodySm: TextStyle.lerp(bodySm, other.bodySm, t)!,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t)!,
      bodyBase: TextStyle.lerp(bodyBase, other.bodyBase, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodyLg: TextStyle.lerp(bodyLg, other.bodyLg, t)!,
      bodyLarge: TextStyle.lerp(bodyLarge, other.bodyLarge, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      callout: TextStyle.lerp(callout, other.callout, t)!,
    );
  }
}

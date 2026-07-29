import 'package:flutter/material.dart';

/// Font family registered in `pubspec.yaml` for display text.
const String _goudy = 'GoudyHeavyface';

/// Font family registered in `pubspec.yaml` for body and controls.
const String _avenir = 'Avenir';

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
    required this.display,
    required this.headingLarge,
    required this.heading,
    required this.warning,
    required this.eyebrow,
    required this.eyebrowSmall,
    required this.micro,
    required this.label,
    required this.labelStrong,
    required this.bodySmall,
    required this.body,
    required this.bodyLarge,
    required this.caption,
  });

  /// Goudy 42/1 — the Ki title (`.kiHeader h2`, clamp max).
  final TextStyle display;

  /// Goudy 25/1 — Possible Actions heading (`.actionPanel h3`).
  final TextStyle headingLarge;

  /// Goudy 24/1 — realm name and Inspect heading (`.realmContext h2`).
  final TextStyle heading;

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

  /// Avenir 13/1.4 — default body and inputs (`.actionGrid strong`, inputs).
  final TextStyle body;

  /// Avenir 19/1.58 — Ki conversational message (`.kiMessage p`, clamp max).
  final TextStyle bodyLarge;

  /// Avenir 12/1.5 — Ki invitation line and short prose (`.kiMessage strong`).
  final TextStyle caption;

  /// Canonical Field typography — matches the prototype exactly.
  static const KidunaText standard = KidunaText(
    display: TextStyle(
      fontFamily: _goudy,
      fontSize: 42,
      height: 1,
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
    body: TextStyle(
      fontFamily: _avenir,
      fontSize: 13,
      height: 1.4,
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
      height: 1.5,
      fontWeight: FontWeight.w400,
    ),
  );

  @override
  KidunaText copyWith({
    TextStyle? display,
    TextStyle? headingLarge,
    TextStyle? heading,
    TextStyle? warning,
    TextStyle? eyebrow,
    TextStyle? eyebrowSmall,
    TextStyle? micro,
    TextStyle? label,
    TextStyle? labelStrong,
    TextStyle? bodySmall,
    TextStyle? body,
    TextStyle? bodyLarge,
    TextStyle? caption,
  }) {
    return KidunaText(
      display: display ?? this.display,
      headingLarge: headingLarge ?? this.headingLarge,
      heading: heading ?? this.heading,
      warning: warning ?? this.warning,
      eyebrow: eyebrow ?? this.eyebrow,
      eyebrowSmall: eyebrowSmall ?? this.eyebrowSmall,
      micro: micro ?? this.micro,
      label: label ?? this.label,
      labelStrong: labelStrong ?? this.labelStrong,
      bodySmall: bodySmall ?? this.bodySmall,
      body: body ?? this.body,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      caption: caption ?? this.caption,
    );
  }

  @override
  KidunaText lerp(covariant ThemeExtension<KidunaText>? other, double t) {
    if (other is! KidunaText) {
      return this;
    }
    return KidunaText(
      display: TextStyle.lerp(display, other.display, t)!,
      headingLarge: TextStyle.lerp(headingLarge, other.headingLarge, t)!,
      heading: TextStyle.lerp(heading, other.heading, t)!,
      warning: TextStyle.lerp(warning, other.warning, t)!,
      eyebrow: TextStyle.lerp(eyebrow, other.eyebrow, t)!,
      eyebrowSmall: TextStyle.lerp(eyebrowSmall, other.eyebrowSmall, t)!,
      micro: TextStyle.lerp(micro, other.micro, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      labelStrong: TextStyle.lerp(labelStrong, other.labelStrong, t)!,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodyLarge: TextStyle.lerp(bodyLarge, other.bodyLarge, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
    );
  }
}

import 'package:flutter/material.dart';

const String _goudy = 'GoudyHeavyface';
const String _avenir = 'Avenir';

/// Kiduna Field typography roles.
///
/// Styles carry no colour — apply at the call site via `.copyWith(color: ...)`.
@immutable
class KidunaText extends ThemeExtension<KidunaText> {
  const KidunaText({
    required this.displayLarge,
    required this.heading,
    required this.h2,
    required this.h4,
    required this.h5,
    required this.eyebrow,
    required this.eyebrowSmall,
    required this.label,
    required this.labelStrong,
    required this.body,
    required this.bodySm,
    required this.bodyLarge,
    required this.caption,
    required this.micro,
  });

  final TextStyle displayLarge;
  final TextStyle heading;
  final TextStyle h2;
  final TextStyle h4;
  final TextStyle h5;
  final TextStyle eyebrow;
  final TextStyle eyebrowSmall;
  final TextStyle label;
  final TextStyle labelStrong;
  final TextStyle body;
  final TextStyle bodySm;
  final TextStyle bodyLarge;
  final TextStyle caption;
  final TextStyle micro;

  static const KidunaText standard = KidunaText(
    displayLarge: TextStyle(
      fontFamily: _goudy,
      fontSize: 54,
      height: 1.05,
      fontWeight: FontWeight.w400,
    ),
    heading: TextStyle(
      fontFamily: _goudy,
      fontSize: 24,
      height: 1,
      fontWeight: FontWeight.w400,
    ),
    h2: TextStyle(
      fontFamily: _goudy,
      fontSize: 30,
      height: 1.2,
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
    body: TextStyle(
      fontFamily: _avenir,
      fontSize: 13,
      height: 1.4,
      fontWeight: FontWeight.w400,
    ),
    bodySm: TextStyle(
      fontFamily: _avenir,
      fontSize: 14,
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
      height: 1.5,
      fontWeight: FontWeight.w400,
    ),
    micro: TextStyle(
      fontFamily: _avenir,
      fontSize: 8,
      height: 1.2,
      fontWeight: FontWeight.w400,
    ),
  );

  @override
  KidunaText copyWith({
    TextStyle? displayLarge,
    TextStyle? heading,
    TextStyle? h2,
    TextStyle? h4,
    TextStyle? h5,
    TextStyle? eyebrow,
    TextStyle? eyebrowSmall,
    TextStyle? label,
    TextStyle? labelStrong,
    TextStyle? body,
    TextStyle? bodySm,
    TextStyle? bodyLarge,
    TextStyle? caption,
    TextStyle? micro,
  }) {
    return KidunaText(
      displayLarge: displayLarge ?? this.displayLarge,
      heading: heading ?? this.heading,
      h2: h2 ?? this.h2,
      h4: h4 ?? this.h4,
      h5: h5 ?? this.h5,
      eyebrow: eyebrow ?? this.eyebrow,
      eyebrowSmall: eyebrowSmall ?? this.eyebrowSmall,
      label: label ?? this.label,
      labelStrong: labelStrong ?? this.labelStrong,
      body: body ?? this.body,
      bodySm: bodySm ?? this.bodySm,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      caption: caption ?? this.caption,
      micro: micro ?? this.micro,
    );
  }

  @override
  KidunaText lerp(covariant ThemeExtension<KidunaText>? other, double t) {
    if (other is! KidunaText) {
      return this;
    }
    return KidunaText(
      displayLarge: TextStyle.lerp(displayLarge, other.displayLarge, t)!,
      heading: TextStyle.lerp(heading, other.heading, t)!,
      h2: TextStyle.lerp(h2, other.h2, t)!,
      h4: TextStyle.lerp(h4, other.h4, t)!,
      h5: TextStyle.lerp(h5, other.h5, t)!,
      eyebrow: TextStyle.lerp(eyebrow, other.eyebrow, t)!,
      eyebrowSmall: TextStyle.lerp(eyebrowSmall, other.eyebrowSmall, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      labelStrong: TextStyle.lerp(labelStrong, other.labelStrong, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodySm: TextStyle.lerp(bodySm, other.bodySm, t)!,
      bodyLarge: TextStyle.lerp(bodyLarge, other.bodyLarge, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      micro: TextStyle.lerp(micro, other.micro, t)!,
    );
  }
}

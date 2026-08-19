import 'package:flutter/material.dart';

/// Kiduna "Deep. Warm. Alive." palette.
///
/// Token values taken from the kiduna-studio-design-kit prototype
/// (`canonical-first-field.module.css`). Read via `context.kiduna`.
@immutable
class KidunaColors extends ThemeExtension<KidunaColors> {
  const KidunaColors({
    required this.field,
    required this.deep,
    required this.surface,
    required this.raised,
    required this.raisedAlt,
    required this.cream,
    required this.text,
    required this.muted,
    required this.quiet,
    required this.sky,
    required this.skyHover,
    required this.skyButtonInk,
    required this.gold,
    required this.camel,
    required this.mint,
    required this.line,
    required this.error,
    required this.complete,
    required this.warning,
  });

  final Color field;
  final Color deep;
  final Color surface;
  final Color raised;
  final Color raisedAlt;
  final Color cream;
  final Color text;
  final Color muted;
  final Color quiet;
  final Color sky;
  final Color skyHover;
  final Color skyButtonInk;
  final Color gold;
  final Color camel;
  final Color mint;
  final Color line;
  final Color error;
  final Color complete;
  final Color warning;

  static const KidunaColors standard = KidunaColors(
    field: Color(0xFF0A0604),
    deep: Color(0xFF060304),
    surface: Color(0xFF1C140D),
    raised: Color(0xFF271B11),
    raisedAlt: Color(0xFF33251A),
    cream: Color(0xFFFFF6D5),
    text: Color(0xFFFFFFE6),
    muted: Color(0xFFCBBCAC),
    quiet: Color(0xFF8F8175),
    sky: Color(0xFF03CCD9),
    skyHover: Color(0xFF2FE0EA),
    skyButtonInk: Color(0xFF1C140D),
    gold: Color(0xFFEAAA00),
    camel: Color(0xFFC19A6B),
    mint: Color(0xFF8FE6C6),
    line: Color(0x38C19A6B),
    error: Color(0xFFFF3A3A),
    complete: Color(0xFF00EB75),
    warning: Color(0xFFFFCA05),
  );

  @override
  KidunaColors copyWith({
    Color? field,
    Color? deep,
    Color? surface,
    Color? raised,
    Color? raisedAlt,
    Color? cream,
    Color? text,
    Color? muted,
    Color? quiet,
    Color? sky,
    Color? skyHover,
    Color? skyButtonInk,
    Color? gold,
    Color? camel,
    Color? mint,
    Color? line,
    Color? error,
    Color? complete,
    Color? warning,
  }) {
    return KidunaColors(
      field: field ?? this.field,
      deep: deep ?? this.deep,
      surface: surface ?? this.surface,
      raised: raised ?? this.raised,
      raisedAlt: raisedAlt ?? this.raisedAlt,
      cream: cream ?? this.cream,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      quiet: quiet ?? this.quiet,
      sky: sky ?? this.sky,
      skyHover: skyHover ?? this.skyHover,
      skyButtonInk: skyButtonInk ?? this.skyButtonInk,
      gold: gold ?? this.gold,
      camel: camel ?? this.camel,
      mint: mint ?? this.mint,
      line: line ?? this.line,
      error: error ?? this.error,
      complete: complete ?? this.complete,
      warning: warning ?? this.warning,
    );
  }

  @override
  KidunaColors lerp(covariant ThemeExtension<KidunaColors>? other, double t) {
    if (other is! KidunaColors) {
      return this;
    }
    return KidunaColors(
      field: Color.lerp(field, other.field, t)!,
      deep: Color.lerp(deep, other.deep, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      raisedAlt: Color.lerp(raisedAlt, other.raisedAlt, t)!,
      cream: Color.lerp(cream, other.cream, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      quiet: Color.lerp(quiet, other.quiet, t)!,
      sky: Color.lerp(sky, other.sky, t)!,
      skyHover: Color.lerp(skyHover, other.skyHover, t)!,
      skyButtonInk: Color.lerp(skyButtonInk, other.skyButtonInk, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      camel: Color.lerp(camel, other.camel, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      line: Color.lerp(line, other.line, t)!,
      error: Color.lerp(error, other.error, t)!,
      complete: Color.lerp(complete, other.complete, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

import 'package:flutter/material.dart';

/// Kiduna "Deep. Warm. Alive." Field palette.
///
/// Exact token values taken from the kiduna-studio-design-kit prototype
/// (`canonical-first-field.module.css`, the `.shell` custom properties). This
/// is the single source of colour truth for the Studio Field surface across
/// web, mobile, and desktop. Never hardcode a Field colour at a call site —
/// read it from here via `Theme.of(context).extension<KidunaColors>()` or the
/// `context.kiduna` helper in `context_extensions.dart`.
///
/// The Field design is intrinsically dark, so [standard] is registered on both
/// the light and dark [ThemeData]; the tokens do not change between them.
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
  });

  /// Deepest Field background (`--field`).
  final Color field;

  /// Darkest ink and composer ground (`--deep`).
  final Color deep;

  /// Default panel ground / espresso (`--surface`).
  final Color surface;

  /// Raised warm surface (`--raised`).
  final Color raised;

  /// Elevated instrument surface (`--raised-2`).
  final Color raisedAlt;

  /// Headings and highlights (`--cream`).
  final Color cream;

  /// Primary readable text; replaces pure white (`--text`).
  final Color text;

  /// Secondary copy (`--muted`).
  final Color muted;

  /// Tertiary text and quiet labels (`--quiet`).
  final Color quiet;

  /// Ki, navigation, links, and the single primary Action (`--sky`).
  final Color sky;

  /// Sky hover state (`--sky-hover`).
  final Color skyHover;

  /// Ink for content on a sky-filled control (`--sky-button-ink`). Contextual:
  /// it defaults to the local ground ([surface]) and must be overridden per
  /// material where the ground behind the button differs. White or cream ink on
  /// sky is prohibited.
  final Color skyButtonInk;

  /// Kiduna mark, significance, and deliberate upright emphasis (`--gold`).
  final Color gold;

  /// Warm structure and secondary accents (`--camel`).
  final Color camel;

  /// Rare emergence, intelligence, or living state (`--mint`).
  final Color mint;

  /// Hairline borders — camel at 22% alpha (`--line`).
  final Color line;

  /// Canonical Field palette — matches the prototype token values exactly.
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
    );
  }
}

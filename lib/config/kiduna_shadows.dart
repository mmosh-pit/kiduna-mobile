import 'package:flutter/material.dart';

/// Kiduna Field shadow and glow tokens.
///
/// Values taken from the kiduna-studio-design-kit prototype CSS. Shadows use
/// warm deep-umber tones (`rgba(12,7,3,…)` / `rgba(0,0,0,…)`) rather than
/// neutral grey. Glows use the corresponding accent colour. Read them via
/// `context.shadows` rather than writing raw [BoxShadow] lists in widgets.
@immutable
class KidunaShadows extends ThemeExtension<KidunaShadows> {
  const KidunaShadows({
    required this.sm,
    required this.md,
    required this.lg,
    required this.glowAccent,
    required this.glowSky,
    required this.glowWarm,
    required this.panel,
    required this.realmPill,
    required this.enamelIcon,
    required this.kiEnamelIcon,
  });

  /// Subtle depth (`--shadow-sm`).
  final List<BoxShadow> sm;

  /// Card elevation (`--shadow-md`).
  final List<BoxShadow> md;

  /// Modal / overlay depth (`--shadow-lg`).
  final List<BoxShadow> lg;

  /// Sky-blue accent glow ring (`--shadow-glow-accent`).
  final List<BoxShadow> glowAccent;

  /// Sky glow ring alias (`--shadow-glow-sky`).
  final List<BoxShadow> glowSky;

  /// Warm camel glow ring (`--shadow-glow-warm`).
  final List<BoxShadow> glowWarm;

  /// Field panel depth.
  final List<BoxShadow> panel;

  /// Realm context pill depth.
  final List<BoxShadow> realmPill;

  /// Ecosystem enamel icon multi-ring glow.
  final List<BoxShadow> enamelIcon;

  /// Ki enamel icon multi-ring glow.
  final List<BoxShadow> kiEnamelIcon;

  /// Canonical Field shadows — matches the prototype exactly.
  static const KidunaShadows standard = KidunaShadows(
    sm: [
      BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x66000000)),
    ],
    md: [
      BoxShadow(offset: Offset(0, 6), blurRadius: 20, color: Color(0x800C0703)),
    ],
    lg: [
      BoxShadow(
        offset: Offset(0, 18),
        blurRadius: 48,
        color: Color(0x990C0703),
      ),
    ],
    glowAccent: [
      BoxShadow(spreadRadius: 1, color: Color(0x5903CCD9)),
      BoxShadow(offset: Offset(0, 8), blurRadius: 28, color: Color(0x2E03CCD9)),
    ],
    glowSky: [
      BoxShadow(spreadRadius: 1, color: Color(0x5903CCD9)),
      BoxShadow(offset: Offset(0, 8), blurRadius: 28, color: Color(0x2E03CCD9)),
    ],
    glowWarm: [
      BoxShadow(spreadRadius: 1, color: Color(0x66C19A6B)),
      BoxShadow(offset: Offset(0, 8), blurRadius: 28, color: Color(0x29C19A6B)),
    ],
    panel: [
      BoxShadow(
        offset: Offset(0, 18),
        blurRadius: 52,
        color: Color(0x6B000000),
      ),
    ],
    realmPill: [
      BoxShadow(
        offset: Offset(0, 16),
        blurRadius: 46,
        color: Color(0x61000000),
      ),
    ],
    enamelIcon: [
      BoxShadow(spreadRadius: 4, color: Color(0xE60A0604)),
      BoxShadow(spreadRadius: 5, color: Color(0x52C19A6B)),
      BoxShadow(blurRadius: 20, color: Color(0x1AEAAA00)),
    ],
    kiEnamelIcon: [
      BoxShadow(spreadRadius: 4, color: Color(0xE60A0604)),
      BoxShadow(spreadRadius: 5, color: Color(0x4203CCD9)),
      BoxShadow(blurRadius: 24, color: Color(0x1F03CCD9)),
    ],
  );

  @override
  KidunaShadows copyWith({
    List<BoxShadow>? sm,
    List<BoxShadow>? md,
    List<BoxShadow>? lg,
    List<BoxShadow>? glowAccent,
    List<BoxShadow>? glowSky,
    List<BoxShadow>? glowWarm,
    List<BoxShadow>? panel,
    List<BoxShadow>? realmPill,
    List<BoxShadow>? enamelIcon,
    List<BoxShadow>? kiEnamelIcon,
  }) {
    return KidunaShadows(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      glowAccent: glowAccent ?? this.glowAccent,
      glowSky: glowSky ?? this.glowSky,
      glowWarm: glowWarm ?? this.glowWarm,
      panel: panel ?? this.panel,
      realmPill: realmPill ?? this.realmPill,
      enamelIcon: enamelIcon ?? this.enamelIcon,
      kiEnamelIcon: kiEnamelIcon ?? this.kiEnamelIcon,
    );
  }

  @override
  KidunaShadows lerp(covariant ThemeExtension<KidunaShadows>? other, double t) {
    if (other is! KidunaShadows) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

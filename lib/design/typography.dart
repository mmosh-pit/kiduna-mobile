import 'package:flutter/painting.dart';

import 'tokens.dart';

/// Kiduna Studio type.
///
/// **Goudy Heavyface** — identity, major Realm headings, thresholds, and
/// significant figures.
/// **Avenir** — body copy, controls, and operational information.
///
/// Source: `design-kit/studio-v1.7/DESIGN-SYSTEM.md`.
///
/// Licence note: both are commercial typefaces. The TTFs ship inside the
/// Studio Design Kit, which is fine for prototyping — confirm distribution
/// licensing before any store release.
abstract final class Type {
  static const _identity = 'GoudyHeavyface';
  static const _body = 'Avenir';

  // ── Identity · Goudy Heavyface ────────────────────────────────────────

  /// Ecosystem and major Realm identity.
  static const display = TextStyle(
    fontFamily: _identity,
    fontSize: 44,
    height: 1.08,
    letterSpacing: -0.4,
    color: Enamel.text,
  );

  /// Realm headings and thresholds.
  static const heading = TextStyle(
    fontFamily: _identity,
    fontSize: 26,
    height: 1.15,
    color: Enamel.text,
  );

  /// Significant figures — Compute balances, counts.
  static const figure = TextStyle(
    fontFamily: _identity,
    fontSize: 20,
    height: 1.2,
    color: Enamel.cream,
  );

  /// The name attached to a Realm node. Attached, never floating.
  static const realmName = TextStyle(
    fontFamily: _identity,
    fontSize: 13,
    height: 1.2,
    color: Enamel.text,
  );

  // ── Body and operational · Avenir ─────────────────────────────────────

  static const body = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 1.5,
    color: Enamel.text,
  );

  static const bodyQuiet = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w300,
    fontSize: 14,
    height: 1.5,
    color: Enamel.camel,
  );

  /// Controls and buttons.
  static const control = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w800,
    fontSize: 13,
    height: 1.2,
    letterSpacing: 0.3,
  );

  /// Realm type, role, stationed Ally — the operational line under a node.
  static const operational = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w300,
    fontSize: 11,
    height: 1.3,
    color: Enamel.camel,
  );

  /// Eyebrows and section markers.
  static const eyebrow = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w800,
    fontSize: 10,
    height: 1.4,
    letterSpacing: 1.6,
    color: Enamel.camel,
  );
}

import 'package:flutter/animation.dart';

/// Kiduna Field motion tokens.
///
/// Durations, scales, and curves taken from the kiduna-studio-design-kit
/// prototype CSS. The four named motion categories are Breathe, Relate,
/// Gather, and Drift. Read these via `KidunaMotion.xxx` — they are static
/// constants, not a ThemeExtension, because motion does not vary between
/// light and dark themes.
abstract class KidunaMotion {
  const KidunaMotion._();

  // Breathe — slow living emphasis.
  static const Duration breatheDuration = Duration(seconds: 7);
  static const double breatheScale = 1.035;

  // Drift — ambient atmospheric motion.
  static const Duration driftDuration = Duration(seconds: 16);

  // Gather — gathering transition.
  static const Duration gatherDuration = Duration(milliseconds: 900);

  // Path pulse — connectors between Realm nodes.
  static const Duration pathPulseDuration = Duration(seconds: 4);

  // Panel transitions.
  static const Duration panelIn = Duration(milliseconds: 260);
  static const Duration panelTransition = Duration(milliseconds: 160);

  // Realm node animations.
  static const Duration realmResolve = Duration(milliseconds: 760);
  static const Duration realmOrbit = Duration(seconds: 24);
  static const Duration realmSignalPulse = Duration(milliseconds: 2800);

  // Connector stroke animation.
  static const Duration connectorStroke = Duration(milliseconds: 220);

  // Star breathe cycle.
  static const Duration starBreathe = Duration(seconds: 5);

  // Comet pass.
  static const Duration cometPass = Duration(seconds: 24);

  // Common interaction transitions.
  static const Duration hoverFact = Duration(milliseconds: 150);
  static const Duration fieldDrag = Duration(milliseconds: 150);
  static const Duration constellationTransition = Duration(milliseconds: 180);

  // Standard curves.
  static const Curve panelCurve = Curves.easeOut;
  static const Curve gatherCurve = Cubic(.2, .7, .2, 1);
  static const Curve realmCrestCurve = Cubic(.16, 1, .3, 1);
}

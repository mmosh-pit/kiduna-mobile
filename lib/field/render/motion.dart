/// The motion vocabulary of the Field.
///
/// Five named verbs, specified rather than invented — timings come from
/// `kit/enamel/02-FIELD-GROUND-MOTION.md` and the implemented keyframes in
/// `canonical-first-field.module.css`.
///
/// | Verb | State | Spec |
/// |---|---|---|
/// | **Breathe** | Open | scale 1 → 1.035 → 1, 6–8s, ease-in-out |
/// | **Drift** | Dreaming | max ±8px/axis, 14–18s, long ease-in-out loop |
/// | **Relate** | Engaged | brighten an *existing* path, 3–5s luminance cycle |
/// | **Gather** | Focused | 900ms settle, 120–150ms sibling stagger |
/// | **Orbit** | — | ≥16s per revolution; membership, not decoration |
///
/// Nothing here bounces. The Field reads as *alive*, not animated.
///
/// Pure functions and constants: no Flame, no Flutter, no clock of its own.
library;

import 'dart:math' as math;

abstract final class Verb {
  // ── Breathe ───────────────────────────────────────────────────────────
  /// A Realm at rest remains available.
  static const breathePeriodMin = 6.0;
  static const breathePeriodMax = 8.0;

  /// `1 → 1.035 → 1`. Never more.
  static const breatheScale = 0.035;

  /// Glow follows scale with less than 20% luminance change.
  static const breatheGlow = 0.20;

  // ── Drift ─────────────────────────────────────────────────────────────
  /// Maximum excursion per axis, in pixels at normal scale.
  static const driftMax = 8.0;
  static const driftPeriodMin = 14.0;
  static const driftPeriodMax = 18.0;

  /// The reference's own per-node drift is far slower and smaller than the
  /// canon's ceiling: `56 + (i % 8) × 7` seconds over roughly ±3px. That is
  /// what makes the Field feel alive without anything appearing to move.
  static double nodeDriftPeriod(int index) => 56 + (index % 8) * 7;

  /// Negative, staggered, so no two nodes are ever in phase.
  static double nodeDriftPhase(int index) => (index % 9) * -7.3;

  static const nodeDriftFrom = (-2.0, 1.0);
  static const nodeDriftTo = (3.0, -2.0);

  // ── Relate ────────────────────────────────────────────────────────────
  /// A gentle luminance cycle — only while the relationship is active.
  static const relatePeriodMin = 3.0;
  static const relatePeriodMax = 5.0;

  // ── Gather ────────────────────────────────────────────────────────────
  /// Each arriving object settles in 900ms.
  static const gatherSettle = 0.9;

  /// Siblings stagger by 120–150ms.
  static const gatherStagger = 0.13;

  /// The implemented crest entry: opacity .36 → 1, brightness .72 → 1.
  static const resolveDuration = 0.76;
  static const resolveOpacityFrom = 0.36;
  static const resolveBrightnessFrom = 0.72;

  // ── Orbit ─────────────────────────────────────────────────────────────
  /// Minimum for a complete revolution. Denotes membership, attention, or
  /// active containment — never decoration.
  static const orbitMinPeriod = 16.0;

  /// The cluster ring's travelling light. Far slower than the canon floor:
  /// this is the Field breathing, not a carousel. Staggered per cluster so no
  /// two rings pulse together.
  static double clusterOrbitPeriod(int index) => 46 + index * 9;

  /// The proportion of the ring lit at any moment.
  static const clusterArcSpan = 0.13;

  /// The implemented role ring.
  static const roleOrbitPeriod = 24.0;
  static const roleOrbitTilt = -18.0;
  static const roleOrbitFlatten = 0.56;

  // ── Signal ────────────────────────────────────────────────────────────
  /// One active glint reveals change. Scale .72 → 2.1, opacity .72 → 0,
  /// invisible from 72% of the cycle onward.
  static const signalPeriod = 2.8;

  // ── Ground ────────────────────────────────────────────────────────────
  static const starBreatheMin = 0.24;
  static const starBreatheMax = 0.82;
  static const starDriftTo = (9.0, -5.0);
  static const nebulaPeriod = 30.0;
  static const galaxyPeriod = 18.0;
  static const cometPeriod = 24.0;

  /// The comet idles almost invisible for 72% of its cycle, then passes.
  static const cometDormantUntil = 0.72;
  static const cometPeakAt = 0.82;
  static const cometDormantOpacity = 0.16;
  static const cometPeakOpacity = 0.72;

  // ── Curves ────────────────────────────────────────────────────────────

  /// `0 → 1` over one period, wrapping. [phase] shifts the start, and may be
  /// negative to stagger siblings out of step.
  static double cycle(double elapsed, double period, {double phase = 0}) {
    if (period <= 0) return 0;
    final t = (elapsed + phase) % period;
    return (t < 0 ? t + period : t) / period;
  }

  /// `0 → 1 → 0` over one period. CSS `alternate`, without the jump back.
  static double pingPong(double elapsed, double period, {double phase = 0}) {
    final t = cycle(elapsed, period * 2, phase: phase);
    return t < 0.5 ? t * 2 : (1 - t) * 2;
  }

  static double easeInOut(double t) {
    final c = t.clamp(0.0, 1.0);
    return c < 0.5 ? 2 * c * c : 1 - math.pow(-2 * c + 2, 2) / 2;
  }

  static double easeOut(double t) {
    final c = t.clamp(0.0, 1.0);
    return 1 - math.pow(1 - c, 3).toDouble();
  }

  static double lerp(double a, double b, double t) => a + (b - a) * t;

  /// The reference's Gather curve: `cubic-bezier(.2, .7, .2, 1)`.
  ///
  /// Slight overshoot in *position only* — never a cartoon bounce. Solved by
  /// Newton iteration rather than approximated, so a Realm lands where the
  /// reference lands.
  static double gather(double t) => cubicBezier(0.2, 0.7, 0.2, 1.0, t);

  /// A CSS-style cubic Bézier easing: control points (x1,y1) and (x2,y2) with
  /// implicit endpoints at (0,0) and (1,1).
  static double cubicBezier(
    double x1,
    double y1,
    double x2,
    double y2,
    double t,
  ) {
    final clamped = t.clamp(0.0, 1.0);
    if (clamped <= 0) return 0;
    if (clamped >= 1) return 1;

    double curve(double a, double b, double p) {
      final c = 3 * a;
      final bb = 3 * (b - a) - c;
      final aa = 1 - c - bb;
      return ((aa * p + bb) * p + c) * p;
    }

    double slope(double a, double b, double p) {
      final c = 3 * a;
      final bb = 3 * (b - a) - c;
      final aa = 1 - c - bb;
      return (3 * aa * p + 2 * bb) * p + c;
    }

    // Solve curve(x1, x2, p) == clamped for p.
    var p = clamped;
    for (var i = 0; i < 8; i++) {
      final error = curve(x1, x2, p) - clamped;
      if (error.abs() < 1e-6) break;
      final d = slope(x1, x2, p);
      if (d.abs() < 1e-6) break;
      p -= error / d;
    }
    return curve(y1, y2, p.clamp(0.0, 1.0));
  }

  /// The comet's opacity at a point in its cycle: dormant, then a brief flare,
  /// then dormant again.
  static double cometOpacity(double t) {
    if (t < cometDormantUntil) return cometDormantOpacity;
    if (t < cometPeakAt) {
      final k = (t - cometDormantUntil) / (cometPeakAt - cometDormantUntil);
      return lerp(cometDormantOpacity, cometPeakOpacity, easeInOut(k));
    }
    final k = (t - cometPeakAt) / (1 - cometPeakAt);
    return lerp(cometPeakOpacity, cometDormantOpacity, easeInOut(k));
  }
}

/// Whether the Field is allowed to move, and how far along it is.
///
/// > When reduced motion is requested: stop breathe, drift, orbit, path pulse,
/// > parallax and stagger. **Retain** semantic glow, scale, labels, state
/// > sigils and hierarchy.
/// >
/// > *Never remove information because animation is disabled.*
///
/// Reduced motion holds [elapsed] at zero, so every phase function returns its
/// resting value. Nothing branches on the flag at the drawing site, which is
/// what stops a reduced-motion path from quietly losing information.
class Motion {
  Motion({this.reduced = false});

  bool reduced;

  double _elapsed = 0;

  /// Seconds since the Field appeared — frozen at 0 when motion is reduced.
  double get elapsed => reduced ? 0 : _elapsed;

  /// Entry animations still need a real clock so they can *complete*; they are
  /// simply skipped to their finished state when motion is reduced.
  double get entryElapsed => reduced ? double.infinity : _elapsed;

  void tick(double dt) => _elapsed += dt;

  /// Rewinds the clock so the staggered arrival can be watched again. Used by
  /// the Field Catalog; the Field itself arrives once.
  void restart() => _elapsed = 0;

  /// `0 → 1` progress of a staggered entry for the [index]th sibling.
  double entry(int index) {
    final start = index * Verb.gatherStagger;
    final t = (entryElapsed - start) / Verb.resolveDuration;
    return t.isNaN ? 1 : t.clamp(0.0, 1.0);
  }
}

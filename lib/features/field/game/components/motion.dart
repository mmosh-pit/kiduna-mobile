import 'dart:math' as math;

abstract final class Verb {
  static const breathePeriodMin = 6.0;
  static const breathePeriodMax = 8.0;
  static const breatheScale = 0.035;
  static const breatheGlow = 0.20;

  static const driftMax = 8.0;
  static const driftPeriodMin = 14.0;
  static const driftPeriodMax = 18.0;

  static double nodeDriftPeriod(int index) => 56 + (index % 8) * 7;
  static double nodeDriftPhase(int index) => (index % 9) * -7.3;

  static const nodeDriftFrom = (-2.0, 1.0);
  static const nodeDriftTo = (3.0, -2.0);

  static const relatePeriodMin = 3.0;
  static const relatePeriodMax = 5.0;

  static const gatherSettle = 0.9;
  static const gatherStagger = 0.13;

  static const resolveDuration = 0.76;
  static const resolveOpacityFrom = 0.36;
  static const resolveBrightnessFrom = 0.72;

  static const orbitMinPeriod = 16.0;

  static double clusterOrbitPeriod(int index) => 46 + index * 9;
  static const clusterArcSpan = 0.13;

  static const roleOrbitPeriod = 24.0;
  static const roleOrbitTilt = -18.0;
  static const roleOrbitFlatten = 0.56;

  static const signalPeriod = 2.8;

  static const starBreatheMin = 0.24;
  static const starBreatheMax = 0.82;
  static const starDriftTo = (9.0, -5.0);
  static const nebulaPeriod = 30.0;
  static const galaxyPeriod = 18.0;
  static const cometPeriod = 24.0;

  static const cometDormantUntil = 0.72;
  static const cometPeakAt = 0.82;
  static const cometDormantOpacity = 0.16;
  static const cometPeakOpacity = 0.72;

  static double cycle(double elapsed, double period, {double phase = 0}) {
    if (period <= 0) return 0;
    final t = (elapsed + phase) % period;
    return (t < 0 ? t + period : t) / period;
  }

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

  static double gather(double t) => cubicBezier(0.2, 0.7, 0.2, 1.0, t);

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

class Motion {
  Motion({this.reduced = false});

  bool reduced;

  double _elapsed = 0;

  double get elapsed => reduced ? 0 : _elapsed;

  double get entryElapsed => reduced ? double.infinity : _elapsed;

  void tick(double dt) => _elapsed += dt;

  void restart() => _elapsed = 0;

  double entry(int index) {
    final start = index * Verb.gatherStagger;
    final t = (entryElapsed - start) / Verb.resolveDuration;
    return t.isNaN ? 1 : t.clamp(0.0, 1.0);
  }
}

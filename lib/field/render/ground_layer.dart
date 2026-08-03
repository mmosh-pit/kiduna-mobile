/// Layer 1 · Ground.
///
/// > A dark field should feel **deep, not empty**. The ground stays crisp at
/// > near-black umber. Warmth belongs to objects: reflected enamel light, thin
/// > orbit engravings, and sparse cream or gold glints.
///
/// Permitted: sparse camel or warm-gold arcs at ≤10% opacity, 2–3px moon-cream
/// and sun-gold glints, subtle inset lacquer depth at the viewport boundary.
///
/// Prohibited: visible grids, full-screen gradients, broad washes, dense star
/// fields, and **animated backgrounds independent of objects** — which is why
/// every mote here is tied to a specified verb rather than free-running.
library;

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../design/tokens.dart';
import 'layers.dart';
import 'motion.dart';

/// A star: x%, y%, radius px, base opacity, drift group.
typedef _Star = (double, double, double, double, int);

class GroundLayer extends PositionComponent {
  GroundLayer(this.motion) : super(priority: Layer.ground);

  final Motion motion;

  /// Transcribed from the reference `STARS` table so the sky is the same sky.
  /// Sparse by design — a dense star field is explicitly prohibited.
  static const List<_Star> _allStars = [
    (5, 12, 1, .42, 0), (11, 68, 2, .74, 1), (16, 35, 1, .35, 0), (20, 84, 1, .52, 2),
    (25, 18, 2, .58, 0), (29, 57, 1, .30, 1), (34, 76, 1, .54, 0), (39, 27, 1, .48, 3),
    (43, 90, 2, .70, 0), (47, 44, 1, .32, 1), (52, 13, 1, .43, 0), (55, 68, 1, .60, 2),
    (60, 33, 2, .75, 0), (64, 82, 1, .34, 1), (69, 20, 1, .46, 0), (72, 57, 1, .56, 3),
    (77, 9, 2, .68, 0), (81, 73, 1, .42, 2), (85, 39, 1, .50, 0), (89, 88, 1, .33, 1),
    (94, 24, 2, .64, 0), (8, 47, 1, .26, 2), (14, 93, 1, .44, 0), (31, 8, 1, .38, 1),
    (37, 63, 2, .62, 0), (49, 79, 1, .28, 3), (58, 95, 1, .40, 0), (67, 47, 1, .30, 2),
    (75, 91, 2, .63, 0), (87, 59, 1, .39, 1), (96, 70, 1, .47, 0), (92, 6, 1, .35, 2),
  ];

  /// Camel arcs, at or below 10% opacity. Centre x%, y%, radius %, opacity.
  static const List<(double, double, double, double)> _arcs = [
    (18, 30, 34, .07),
    (74, 66, 42, .05),
    (46, 88, 28, .06),
    (88, 18, 22, .04),
  ];

  /// Cap ambient objects by viewport. A phone shows fewer motes than a
  /// desktop, and the Field reads the same either way.
  List<_Star> get _stars {
    final area = size.x * size.y;
    if (area >= 900000) return _allStars;
    if (area >= 400000) return _allStars.take(22).toList();
    return _allStars.take(14).toList();
  }

  // Shaders are rebuilt only when the viewport changes, never per frame.
  Paint? _vignette;
  Vector2? _shadedFor;

  void _rebuildShaders() {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    _vignette = Paint()
      ..shader = RadialGradient(
        radius: 0.86,
        colors: [
          const Color(0x00000000),
          Enamel.deepEspresso.withValues(alpha: 0.72),
        ],
        stops: const [0.68, 1.0],
      ).createShader(rect);
    _shadedFor = size.clone();
  }

  /// How far the sky is allowed to wander. Dreaming widens it toward the
  /// canon's ±8px ceiling; every other state keeps the resting fraction.
  double driftScale = 0.42;

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    if (_shadedFor != size) _rebuildShaders();

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = Enamel.deepField,
    );

    // ── Nebula · Drift ────────────────────────────────────────────────
    // A single warm bloom, rotating imperceptibly. 30s, alternate.
    final nebulaT = Verb.pingPong(motion.elapsed, Verb.nebulaPeriod);
    final nebulaCentre = Offset(
      0.30 * w + Verb.lerp(-8, 18, nebulaT),
      0.34 * h + Verb.lerp(2, -8, nebulaT),
    );
    final nebulaRect =
        Rect.fromCircle(center: nebulaCentre, radius: math.min(w, h) * 0.42);
    canvas.drawOval(
      nebulaRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Enamel.camel.withValues(alpha: 0.045),
            const Color(0x00000000),
          ],
        ).createShader(nebulaRect),
    );

    // ── Distant galaxy · Gather ───────────────────────────────────────
    // 18s, opacity .36 ↔ .58, scale .98 ↔ 1.03.
    final galaxyT = Verb.pingPong(motion.elapsed, Verb.galaxyPeriod);
    final galaxyScale = Verb.lerp(0.98, 1.03, Verb.easeInOut(galaxyT));
    final galaxyRect = Rect.fromCenter(
      center: Offset(0.78 * w, 0.72 * h),
      width: math.min(w, h) * 0.5 * galaxyScale,
      height: math.min(w, h) * 0.22 * galaxyScale,
    );
    canvas.save();
    canvas.translate(galaxyRect.center.dx, galaxyRect.center.dy);
    canvas.rotate(-18 * math.pi / 180);
    canvas.translate(-galaxyRect.center.dx, -galaxyRect.center.dy);
    canvas.drawOval(
      galaxyRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Enamel.mint.withValues(
              alpha: 0.030 * Verb.lerp(0.36, 0.58, galaxyT) / 0.58,
            ),
            const Color(0x00000000),
          ],
        ).createShader(galaxyRect),
    );
    canvas.restore();

    // ── Gold-wire arcs ────────────────────────────────────────────────
    // Engraving, not decoration. These do not move.
    for (final (cx, cy, r, opacity) in _arcs) {
      canvas.drawCircle(
        Offset(cx / 100 * w, cy / 100 * h),
        r / 100 * math.min(w, h) * 1.6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Enamel.camel.withValues(alpha: opacity),
      );
    }

    // ── Comet · one pass per cycle ────────────────────────────────────
    // Dormant at .16 for 72% of 24s, then it flares and is gone.
    final cometT = Verb.cycle(motion.elapsed, Verb.cometPeriod);
    final cometAlpha = Verb.cometOpacity(cometT);
    final cometShift = Verb.lerp(-18, 13, Verb.easeInOut(cometT));
    final cometHead =
        Offset(0.62 * w + cometShift, 0.20 * h - cometShift * 0.5);
    canvas.drawLine(
      cometHead,
      cometHead + const Offset(-46, 23),
      Paint()
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round
        ..color = Enamel.cream.withValues(alpha: cometAlpha * 0.5),
    );
    canvas.drawCircle(
      cometHead,
      1.6,
      Paint()..color = Enamel.cream.withValues(alpha: cometAlpha),
    );

    // ── Stars · Breathe and Drift ─────────────────────────────────────
    for (final (x, y, radius, base, group) in _stars) {
      // Four drift groups keep the sky from pulsing as one organism.
      final phase = group * -4.7;
      final breathe = Verb.pingPong(motion.elapsed, 5.5 + group, phase: phase);
      final alpha = Verb.lerp(
        Verb.starBreatheMin,
        Verb.starBreatheMax,
        Verb.easeInOut(breathe),
      ) *
          base;

      final driftT =
          Verb.pingPong(motion.elapsed, Verb.driftPeriodMax + group, phase: phase);
      final centre = Offset(
        x / 100 * w + Verb.starDriftTo.$1 * driftT * driftScale,
        y / 100 * h + Verb.starDriftTo.$2 * driftT * driftScale,
      );

      canvas.drawCircle(
        centre,
        radius,
        Paint()..color = Enamel.cream.withValues(alpha: alpha),
      );
      // Glow follows the breath, well under the 20% luminance ceiling.
      // Two soft discs rather than a mask blur: at this radius the result is
      // indistinguishable, and 32 animated blurs per frame is not affordable.
      canvas.drawCircle(
        centre,
        radius * Verb.lerp(2.2, 2.6, breathe),
        Paint()..color = Enamel.cream.withValues(alpha: alpha * 0.13),
      );
      canvas.drawCircle(
        centre,
        radius * Verb.lerp(3.4, 4.0, breathe),
        Paint()..color = Enamel.cream.withValues(alpha: alpha * 0.05),
      );
    }

    // Inset lacquer depth at the boundary — the Field sits inside something.
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _vignette!);
  }
}

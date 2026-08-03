/// Layer 2 · Geometry — the primitive library.
///
/// The eight background primitives from `kit/enamel/09-BACKGROUND-GEOMETRY.md`,
/// each drawn at its specified construction and resting treatment. Pure
/// painters over a `Canvas`: no Flame, no widgets, no clock of their own, so
/// the Field, the Catalog and any future Scene draw the *same* geometry rather
/// than three lookalikes.
///
/// > Background geometry is a semantic scaffolding layer between the lacquer
/// > ground and Field objects. It establishes gravity, belonging, passage, and
/// > depth **without becoming wallpaper**.
///
/// Every primitive carries a meaning, and the meaning is the reason it may be
/// drawn. Nothing here is available as decoration — a `crossingGlint` with no
/// exchange behind it is as wrong as a connector with no relationship.
library;

import 'dart:math' as math;
import 'dart:ui';

import '../../design/tokens.dart';

/// How present a primitive is. The spec gives two resting bands and one active
/// band; anything brighter than [relevant] must be earned by real change.
enum GeometryState {
  /// `--studio-geometry-resting-opacity: 0.08`
  resting(0.08),

  /// `--studio-geometry-relevant-opacity: 0.18`
  relevant(0.18),

  /// Active — a change is being reported. Never a resting value.
  active(0.42);

  const GeometryState(this.opacity);
  final double opacity;
}

/// How an orbit is engraved. The spec allows three, each meaning something:
/// continuous for stable belonging, dashed for unresolved or historical
/// context, doubled for a shared or reciprocal frame.
enum OrbitEngraving { continuous, dashed, doubled }

abstract final class Geometry {
  // Construction constants, quoted from the primitive library table.
  static const orbitHairline = 1.0;
  static const orbitDash = [3.0, 7.0];
  static const anchorSmall = 6.0;
  static const anchorRegular = 12.0;
  static const glintSmall = 3.0;
  static const glintRegular = 7.0;
  static const glintHero = 11.0;

  /// The warm grey the accents mix into, shared with `ClusterLayer`.
  static const quiet = Color(0xFF8F8176);

  // ── Orbit arc ─────────────────────────────────────────────────────────
  /// *belonging · context · gravity* — elliptical, object-centred.
  ///
  /// Resting treatment: warm-metal hairline at 5–12%. The state band is
  /// clamped into that range so a resting orbit can never out-shout an object.
  static void orbitArc(
    Canvas canvas,
    Rect bounds, {
    Color color = Enamel.camel,
    OrbitEngraving engraving = OrbitEngraving.continuous,
    GeometryState state = GeometryState.resting,
    double rotation = 0,
  }) {
    final alpha = state.opacity.clamp(0.05, 0.12);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = orbitHairline
      ..color = color.withValues(alpha: alpha);

    canvas.save();
    canvas.translate(bounds.center.dx, bounds.center.dy);
    canvas.rotate(rotation);
    canvas.translate(-bounds.center.dx, -bounds.center.dy);

    switch (engraving) {
      case OrbitEngraving.continuous:
        canvas.drawOval(bounds, paint);
      case OrbitEngraving.dashed:
        _dashedOval(canvas, bounds, paint);
      case OrbitEngraving.doubled:
        canvas.drawOval(bounds, paint);
        canvas.drawOval(bounds.deflate(3.5), paint);
    }
    canvas.restore();
  }

  // ── Journey path ──────────────────────────────────────────────────────
  /// *movement · sequence · passage* — an open curved path with an origin and
  /// a destination. Resting treatment: camel or gold at 8–16%.
  ///
  /// Curved by gravity rather than arbitrary flourish: the control point is
  /// perpendicular to the chord, so the bend is a function of the two
  /// endpoints and nothing else.
  static void journeyPath(
    Canvas canvas,
    Offset from,
    Offset to, {
    Color color = Enamel.camel,
    GeometryState state = GeometryState.resting,
    double bend = 0.16,
  }) {
    final alpha = state.opacity.clamp(0.08, 0.16);
    canvas.drawPath(
      _bowed(from, to, bend),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: alpha),
    );
  }

  // ── Anchor stud ───────────────────────────────────────────────────────
  /// *attachment · commitment · endpoint* — a radial warm-metal bead with a
  /// dark collar. Visible at **every** attached endpoint: the spec requires a
  /// path to begin or end at a stud, node, threshold, or edge continuation,
  /// so a floating path end is a defect, not a style.
  static void anchorStud(
    Canvas canvas,
    Offset at, {
    Color color = Enamel.camel,
    double size = anchorSmall,
    bool emphasized = false,
  }) {
    final r = size / 2;
    // The dark collar is what lifts the bead off whatever it lands on.
    canvas.drawCircle(at, r * 1.5, Paint()..color = Enamel.deepField);
    canvas.drawCircle(
      at,
      r,
      Paint()..color = color.withValues(alpha: emphasized ? 1 : 0.82),
    );
    if (!emphasized) return;
    canvas.drawCircle(
      at.translate(-r * 0.3, -r * 0.3),
      r * 0.34,
      Paint()..color = Enamel.cream.withValues(alpha: 0.85),
    );
  }

  // ── Constellation ─────────────────────────────────────────────────────
  /// *distributed affinity · peers* — 3–6 nodes joined by selective hairlines.
  ///
  /// Resting treatment: **nodes clearer than lines.** The lines are drawn at a
  /// third of the node alpha for exactly that reason — a constellation is a set
  /// of peers, not a route between them.
  static void constellation(
    Canvas canvas,
    List<Offset> nodes, {
    Color color = Enamel.cream,
    GeometryState state = GeometryState.resting,
  }) {
    assert(nodes.length >= 3 && nodes.length <= 6,
        'The spec fixes a constellation at 3–6 nodes.');
    final alpha = state.opacity.clamp(0.08, 0.18);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = color.withValues(alpha: alpha * 0.34);
    for (var i = 0; i < nodes.length - 1; i++) {
      canvas.drawLine(nodes[i], nodes[i + 1], line);
    }

    for (final node in nodes) {
      canvas.drawCircle(
        node,
        1.9,
        Paint()..color = color.withValues(alpha: (alpha * 5).clamp(0.0, 0.92)),
      );
    }
  }

  // ── Crossing glint ────────────────────────────────────────────────────
  /// *exchange · encounter · transfer* — a four- or eight-point cream star at
  /// a meaningful crossing.
  ///
  /// Resting treatment: **hidden unless the crossing matters.** There is no
  /// resting glint, which is why this takes no [GeometryState]: drawing one at
  /// all is the claim that an exchange happened here.
  static void crossingGlint(
    Canvas canvas,
    Offset at, {
    double size = glintRegular,
    int points = 8,
    double opacity = 1,
  }) {
    assert(points == 4 || points == 8, 'The spec allows four or eight points.');
    final long = size;
    final short = size * 0.28;
    final path = Path();
    final step = math.pi * 2 / (points * 2);
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? long : short;
      final a = -math.pi / 2 + i * step;
      final p = Offset(at.dx + math.cos(a) * r, at.dy + math.sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawCircle(
      at,
      size * 1.6,
      Paint()..color = Enamel.cream.withValues(alpha: 0.10 * opacity),
    );
    canvas.drawPath(
      path,
      Paint()..color = Enamel.cream.withValues(alpha: 0.95 * opacity),
    );
  }

  // ── Horizon ring ──────────────────────────────────────────────────────
  /// *approach · threshold · nesting* — an expanding circular arc becoming the
  /// viewport edge.
  ///
  /// Resting treatment: 8–18%; **cream only near entry**. [approach] is 0 at
  /// rest and 1 at the threshold, and it is the only thing that may bring the
  /// ring to cream — which is what makes "the rim becomes a horizon" a
  /// continuous crossing rather than a cut.
  static void horizonRing(
    Canvas canvas,
    Offset centre,
    double radius, {
    Color color = Enamel.camel,
    double approach = 0,
  }) {
    final t = approach.clamp(0.0, 1.0);
    final alpha = 0.08 + (0.18 - 0.08) * t;
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 + t * 1.4
        ..color = Color.lerp(color, Enamel.cream, t)!.withValues(
          alpha: alpha + t * 0.5,
        ),
    );
  }

  // ── Phase node ────────────────────────────────────────────────────────
  /// *position in a cycle* — a bead placed on an orbit.
  ///
  /// **One active node maximum per orbit.** The caller owns that rule; this
  /// draws a single bead and cannot enforce it, so orbits that carry a phase
  /// node must derive its angle from one source.
  static void phaseNode(
    Canvas canvas,
    Rect orbit,
    double phase, {
    Color color = Enamel.camel,
    bool active = true,
  }) {
    final angle = phase * math.pi * 2;
    final at = Offset(
      orbit.center.dx + math.cos(angle) * orbit.width / 2,
      orbit.center.dy + math.sin(angle) * orbit.height / 2,
    );
    canvas.drawCircle(
      at,
      4.5,
      Paint()..color = color.withValues(alpha: active ? 0.16 : 0.06),
    );
    canvas.drawCircle(
      at,
      1.7,
      Paint()..color = Enamel.cream.withValues(alpha: active ? 0.9 : 0.34),
    );
  }

  // ── Cardinal tick ─────────────────────────────────────────────────────
  /// *stable orientation* — a short radial mark at N/E/S/W.
  ///
  /// Resting treatment: **engraved, not glowing.** It never brightens, never
  /// animates, and never carries state — its whole job is to stay put so
  /// everything else can be read as having moved.
  static void cardinalTicks(
    Canvas canvas,
    Offset centre,
    double radius, {
    Color color = Enamel.camel,
    double length = 5,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.22);
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final c = math.cos(a), s = math.sin(a);
      canvas.drawLine(
        Offset(centre.dx + c * radius, centre.dy + s * radius),
        Offset(
          centre.dx + c * (radius + length),
          centre.dy + s * (radius + length),
        ),
        paint,
      );
    }
  }

  // ── Internals ─────────────────────────────────────────────────────────

  /// A quadratic bow, perpendicular to the chord.
  static Path _bowed(Offset from, Offset to, double bend) {
    final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
    final d = to - from;
    final normal = Offset(-d.dy, d.dx);
    final len = normal.distance;
    final control = len == 0
        ? mid
        : mid + Offset(normal.dx / len, normal.dy / len) * (len * bend);
    return Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
  }

  /// `--studio-orbit-dash: 3px 7px`, walked around the oval by hand because
  /// `PathMetric` on an oval is the only reliable way to keep dash length
  /// constant as the ellipse flattens.
  static void _dashedOval(Canvas canvas, Rect bounds, Paint paint) {
    final source = Path()..addOval(bounds);
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final step = draw ? orbitDash[0] : orbitDash[1];
        final next = math.min(distance + step, metric.length);
        if (draw) canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next;
        draw = !draw;
      }
    }
  }
}

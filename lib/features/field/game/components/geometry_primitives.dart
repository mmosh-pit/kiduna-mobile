import 'dart:math' as math;
import 'dart:ui';

import '../enamel_tokens.dart';

enum GeometryState {
  resting(0.08),
  relevant(0.18),
  active(0.42);

  const GeometryState(this.opacity);
  final double opacity;
}

enum OrbitEngraving { continuous, dashed, doubled }

abstract final class Geometry {
  static const orbitHairline = 1.0;
  static const orbitDash = [3.0, 7.0];
  static const anchorSmall = 6.0;
  static const anchorRegular = 12.0;
  static const glintSmall = 3.0;
  static const glintRegular = 7.0;
  static const glintHero = 11.0;
  static const quiet = Color(0xFF8F8176);

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

  static void anchorStud(
    Canvas canvas,
    Offset at, {
    Color color = Enamel.camel,
    double size = anchorSmall,
    bool emphasized = false,
  }) {
    final r = size / 2;
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

  static void constellation(
    Canvas canvas,
    List<Offset> nodes, {
    Color color = Enamel.cream,
    GeometryState state = GeometryState.resting,
  }) {
    assert(nodes.length >= 3 && nodes.length <= 6);
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

  static void crossingGlint(
    Canvas canvas,
    Offset at, {
    double size = glintRegular,
    int points = 8,
    double opacity = 1,
  }) {
    assert(points == 4 || points == 8);
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

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../data/field_models.dart';
import '../enamel_tokens.dart';
import '../field_typography.dart';
import 'cluster_layer.dart';

String _superGroupOf(String clusterId) {
  final dash = clusterId.indexOf('-');
  return dash <= 0 ? clusterId : clusterId.substring(0, dash);
}

abstract final class ClusterStarPainter {
  static List<(String, Rect, Color, int)> _superClusters(
    ClusterLayer layer,
  ) {
    final groups = <String, List<ClusterDef>>{};
    for (final c in layer.clusters) {
      if (c.isBranch) continue;
      groups.putIfAbsent(_superGroupOf(c.id), () => []).add(c);
    }
    return [
      for (final entry in groups.entries)
        (
          entry.value.first.label.split(' · ').first,
          entry.value
              .map((c) => layer.rectFor(c))
              .reduce((Rect a, Rect b) => a.expandToInclude(b))
              .inflate(18),
          entry.value.first.accent,
          entry.value.length,
        ),
    ];
  }

  static void paintSuperClusters(ClusterLayer layer, Canvas canvas) {
    for (final (label, rect, accent, count) in _superClusters(layer)) {
      canvas.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              accent.withValues(alpha: 0.07),
              const Color(0x00000000),
            ],
            stops: const [0.0, 0.72],
          ).createShader(rect),
      );
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = accent.withValues(alpha: 0.30),
      );
      layer.labelPaints
          .putIfAbsent(
            'super-$label',
            () => TextPaint(
              style: TextStyle(
                fontFamily: Type.body.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 1.2,
                color: Color.lerp(ClusterLayer.quiet, accent, 0.62)!,
              ),
            ),
          )
          .render(
            canvas,
            '${label.toUpperCase()}   $count ORBITS',
            Vector2(rect.center.dx, rect.center.dy),
            anchor: Anchor.center,
          );
    }
  }

  static void paintStars(ClusterLayer layer, Canvas canvas) {
    for (final cluster in layer.clusters) {
      if (cluster.isBranch) continue;

      final centre = Offset(
        cluster.left / 100 * layer.size.x,
        cluster.top / 100 * layer.size.y,
      );
      final held = layer.realmCounts[cluster.id] ?? 0;
      final core = 3.4 + math.min(held, 8) * 0.42;
      final accent = cluster.accent;

      canvas.drawCircle(
        centre,
        core * 7.5,
        Paint()
          ..shader = RadialGradient(
            colors: [
              accent.withValues(alpha: 0.20),
              const Color(0x00000000),
            ],
            stops: const [0.0, 0.78],
          ).createShader(
            Rect.fromCircle(center: centre, radius: core * 7.5),
          ),
      );

      final spike = core * 3.1;
      canvas.drawPath(
        Path()
          ..moveTo(centre.dx, centre.dy - spike)
          ..quadraticBezierTo(centre.dx + core * 0.34,
              centre.dy - core * 0.34, centre.dx + spike, centre.dy)
          ..quadraticBezierTo(centre.dx + core * 0.34,
              centre.dy + core * 0.34, centre.dx, centre.dy + spike)
          ..quadraticBezierTo(centre.dx - core * 0.34,
              centre.dy + core * 0.34, centre.dx - spike, centre.dy)
          ..quadraticBezierTo(centre.dx - core * 0.34,
              centre.dy - core * 0.34, centre.dx, centre.dy - spike)
          ..close(),
        Paint()..color = accent.withValues(alpha: 0.62),
      );

      canvas.drawCircle(centre, core, Paint()..color = Enamel.cream);

      if (cluster.label.isEmpty) continue;
      layer.labelPaints
          .putIfAbsent(
            'star-${cluster.id}',
            () => TextPaint(
              style: TextStyle(
                fontFamily: Type.body.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 1.0,
                color: Color.lerp(ClusterLayer.quiet, accent, 0.72)!
                    .withValues(alpha: 0.92),
              ),
            ),
          )
          .render(
            canvas,
            held == 0
                ? cluster.label.toUpperCase()
                : '${cluster.label.toUpperCase()}   $held',
            Vector2(centre.dx, centre.dy + core * 4.6),
            anchor: Anchor.topCenter,
          );
    }
  }
}

import 'dart:math' as math;
import 'dart:ui' show Picture, PictureRecorder;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../data/field_models.dart';
import '../enamel_tokens.dart';
import 'cluster_star_painter.dart';
import 'layers.dart';
import 'motion.dart';

class ClusterLayer extends PositionComponent {
  ClusterLayer(this.clusters, this.motion) : super(priority: Layer.geometry);

  final List<ClusterDef> clusters;
  final Motion motion;

  static const quiet = Color(0xFF8F8176);
  final Map<String, TextPaint> labelPaints = {};

  bool _collapsed = false;
  set collapsed(bool value) {
    if (_collapsed == value) return;
    _collapsed = value;
    _recorded = null;
  }

  bool _starField = false;
  set starField(bool value) {
    if (_starField == value) return;
    _starField = value;
    _recorded = null;
  }

  Map<String, int> realmCounts = const {};

  Set<String>? _visibleIds;
  set visibleIds(Set<String>? value) {
    if (_visibleIds?.length == value?.length &&
        (value == null || _visibleIds!.containsAll(value))) {
      return;
    }
    _visibleIds = value;
    _recorded = null;
  }

  bool _isVisible(ClusterDef c) => _visibleIds?.contains(c.id) ?? true;

  double contentFade = 1;

  Picture? _recorded;
  Vector2? _recordedFor;

  Rect rectFor(ClusterDef cluster) => Rect.fromCenter(
        center: Offset(
          cluster.left / 100 * size.x,
          cluster.top / 100 * size.y,
        ),
        width: cluster.radiusX * 2 / 100 * size.x,
        height: cluster.radiusY * 2 / 100 * size.y,
      );

  @override
  void render(Canvas canvas) {
    if (contentFade <= 0.01) return;
    if (_recorded == null || _recordedFor != size) {
      final recorder = PictureRecorder();
      _paintStill(Canvas(recorder));
      _recorded = recorder.endRecording();
      _recordedFor = size.clone();
    }
    final useFade = contentFade < 1;
    if (useFade) {
      canvas.saveLayer(
        null,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: contentFade),
      );
    }
    canvas.drawPicture(_recorded!);
    _paintRings(canvas);
    if (useFade) canvas.restore();
  }

  void _paintStill(Canvas canvas) {
    if (_starField) {
      ClusterStarPainter.paintStars(this, canvas);
      return;
    }
    if (_collapsed) {
      ClusterStarPainter.paintSuperClusters(this, canvas);
      return;
    }
    for (final cluster in clusters) {
      if (cluster.isBranch || !_isVisible(cluster)) continue;
      if ((realmCounts[cluster.id] ?? 0) < 3) continue;

      final rect = rectFor(cluster);
      final accent = cluster.accent;

      canvas.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              accent.withValues(alpha: 0.05),
              const Color(0x00000000),
            ],
            stops: const [0.0, 0.69],
          ).createShader(rect),
      );

    }
  }

  void _paintRings(Canvas canvas) {
    if (_collapsed || _starField) return;
    for (var i = 0; i < clusters.length; i++) {
      final cluster = clusters[i];
      if (cluster.isBranch || !_isVisible(cluster)) continue;
      if ((realmCounts[cluster.id] ?? 0) < 3) continue;

      final rect = rectFor(cluster);
      final accent = cluster.accent;

      final breath = Verb.easeInOut(
        Verb.pingPong(motion.elapsed, 7 + i * 0.4, phase: i * -2.3),
      );
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = accent.withValues(alpha: Verb.lerp(0.24, 0.28, breath)),
      );

      if (motion.reduced) continue;

      final phase = Verb.cycle(motion.elapsed, Verb.clusterOrbitPeriod(i));
      final angle = phase * math.pi * 2;
      const span = Verb.clusterArcSpan;

      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..shader = SweepGradient(
            colors: [
              const Color(0x00000000),
              const Color(0x00000000),
              accent.withValues(alpha: 0.85),
              const Color(0x00000000),
              const Color(0x00000000),
            ],
            stops: const [0, 0.5 - span, 0.5, 0.5 + span, 1],
            transform: GradientRotation(angle - math.pi),
          ).createShader(rect),
      );

      final node = Offset(
        rect.center.dx + math.cos(angle) * rect.width / 2,
        rect.center.dy + math.sin(angle) * rect.height / 2,
      );
      canvas.drawCircle(
        node,
        4.5,
        Paint()
          ..color = accent.withValues(alpha: 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        node,
        1.7,
        Paint()..color = Enamel.cream.withValues(alpha: 0.9),
      );
    }
  }
}

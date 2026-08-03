/// Layer 3 · Connection.
///
/// > Semantic paths join anchored points.
///
/// Lines are never decorative. Every curve reveals membership, exchange,
/// attention, passage, or shared gravity — so this layer draws only what the
/// resolver found, and invents nothing.
///
/// Three species, deliberately ranked:
///   1. within-cluster chains, in the cluster accent;
///   2. cross-cluster bridges, quieter and visually distinct;
///   3. the current path, gold and subordinate to Realm identity.
library;

import 'dart:ui' show Picture, PictureRecorder;

import 'package:flutter/painting.dart';

import 'package:flame/components.dart';

import '../../design/tokens.dart';
import '../placement.dart';
import 'motion.dart';
import 'layers.dart';

class ConnectorLayer extends PositionComponent {
  ConnectorLayer(this.field, this.motion) : super(priority: Layer.connection);

  ResolvedField field;
  final Motion motion;

  /// The Realm currently under inspection, if any.
  String? selectedId;

  /// Selection changes which paths are live, so the recorded picture has to be
  /// retaken. Selection is rare; a frame's re-record costs nothing.
  /// Relate: brighten paths that already exist. It multiplies luminance and
  /// can do nothing else — there is no code path here that adds a Connector,
  /// which is how "selection brightens light already there" stays true by
  /// construction rather than by discipline.
  bool _relate = false;
  set relate(bool value) {
    if (_relate == value) return;
    _relate = value;
    _recorded = null;
  }

  double get relateGain => _relate ? 1.7 : 1.0;

  void select(String? id) {
    if (selectedId == id) return;
    selectedId = id;
    _recorded = null;
  }

  void reseat(ResolvedField next) {
    field = next;
    _recorded = null;
  }

  bool _touches(Connector c) =>
      selectedId != null &&
      (c.from.realm.id == selectedId || c.to.realm.id == selectedId);

  /// Paths dim with whatever they connect.
  static const _bandAlpha = <DistanceBand, double>{
    DistanceBand.near: 0.50,
    DistanceBand.middle: 0.34,
    DistanceBand.far: 0.18,
  };

  Offset _at(Placement p) => Offset(
        p.position.left / 100 * size.x,
        p.position.top / 100 * size.y,
      );

  /// Quadratic Bézier with the reference's control-point bend, expressed in
  /// percent and projected like everything else.
  Path _curve(Connector c) {
    final a = _at(c.from);
    final b = _at(c.to);
    final bendPx = c.bend / 100 * size.y;
    return Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(
        (a.dx + b.dx) / 2,
        (a.dy + b.dy) / 2 + bendPx,
        b.dx,
        b.dy,
      );
  }

  // This layer is entirely static in Phase 4 — nothing here animates — so it
  // is recorded once and replayed. Re-rasterising blurred strokes every frame
  // was costing roughly a third of the frame budget.
  Picture? _recorded;
  Vector2? _recordedFor;

  @override
  void render(Canvas canvas) {
    if (_recorded == null || _recordedFor != size) {
      final recorder = PictureRecorder();
      _paint(Canvas(recorder));
      _recorded = recorder.endRecording();
      _recordedFor = size.clone();
    }
    canvas.drawPicture(_recorded!);
    _paintActive(canvas);
  }

  /// **Relate.** Brighten an *existing* path — never create one. A gentle 3–5s
  /// luminance cycle, and it stops the moment the relationship is no longer
  /// contextually active.
  void _paintActive(Canvas canvas) {
    if (selectedId == null) return;
    final pulse = Verb.lerp(
      0.55,
      1.0,
      Verb.easeInOut(Verb.pingPong(motion.elapsed, Verb.relatePeriodMax)),
    );

    for (final c in [...field.connectors, ...field.bridges]) {
      if (!_touches(c)) continue;
      final accent = c.kind == ConnectorKind.bridge
          ? Enamel.camel
          : c.from.cluster.accent;
      final path = _curve(c);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4
          ..color = accent.withValues(alpha: 0.30 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = accent.withValues(alpha: 0.92 * pulse),
      );
    }
  }

  void _paint(Canvas canvas) {
    // Current path first — it sits beneath identity, never over it.
    final target = field.currentPathTarget;
    if (target != null) {
      final end = _at(target);
      final start = Offset(0.02 * size.x, 0.05 * size.y);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          0.18 * size.x,
          0.08 * size.y,
          end.dx - 0.12 * size.x,
          end.dy - 0.12 * size.y,
          end.dx,
          end.dy,
        );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = Enamel.sunGold.withValues(alpha: 0.34)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
      );
    }

    // Cross-cluster bridges: quieter, and visually distinct from the chains.
    for (final bridge in field.bridges) {
      if (_touches(bridge)) continue;
      canvas.drawPath(
        _curve(bridge),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = Enamel.camel.withValues(alpha: 0.20),
      );
    }

    // Within-cluster chains, luminous in the cluster accent.
    for (final connector in field.connectors) {
      if (_touches(connector)) continue;
      final accent = connector.from.cluster.accent;
      // Relate multiplies what the band already grants, and is clamped so a
      // resting path can never reach the luminance reserved for an active
      // relationship. Brightening is the whole effect.
      final alpha =
          (_bandAlpha[connector.distance]! * relateGain).clamp(0.0, 0.62);
      final path = _curve(connector);

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..color = accent.withValues(alpha: alpha * 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = accent.withValues(alpha: alpha),
      );
    }
  }
}

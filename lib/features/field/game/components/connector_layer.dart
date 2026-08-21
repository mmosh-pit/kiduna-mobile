import 'dart:ui' show Picture, PictureRecorder;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../data/placement.dart';
import '../enamel_tokens.dart';
import 'layers.dart';
import 'motion.dart';

class ConnectorLayer extends PositionComponent {
  ConnectorLayer(this.field, this.motion) : super(priority: Layer.connection);

  ResolvedField field;
  final Motion motion;

  String? selectedId;

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

  static const _gravityAlpha = <Gravity, double>{
    Gravity.vital: 0.52,
    Gravity.central: 0.40,
    Gravity.relevant: 0.24,
    Gravity.available: 0.10,
    Gravity.quiet: 0.0,
  };

  Offset _at(Placement p) => Offset(
        p.position.left / 100 * size.x,
        p.position.top / 100 * size.y,
      );

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

  double contentFade = 1;

  Picture? _recorded;
  Vector2? _recordedFor;

  @override
  void render(Canvas canvas) {
    if (contentFade <= 0.01) return;
    if (_recorded == null || _recordedFor != size) {
      final recorder = PictureRecorder();
      _paint(Canvas(recorder));
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
    _paintActive(canvas);
    if (useFade) canvas.restore();
  }

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

    final dimFactor = selectedId != null ? 0.4 : 1.0;
    for (final connector in field.connectors) {
      if (_touches(connector)) continue;
      final gAlpha = _gravityAlpha[connector.minGravity]!;
      if (gAlpha <= 0) continue;
      final accent = connector.from.cluster.accent;
      final alpha = (gAlpha * relateGain * dimFactor).clamp(0.0, 0.62);
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

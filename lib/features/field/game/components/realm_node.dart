import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

import '../../data/field_models.dart';
import '../../data/placement.dart';
import 'layers.dart';
import 'motion.dart';
import 'realm_node_paint.dart';

class RealmNode extends PositionComponent with HoverCallbacks {
  RealmNode({
    required Placement placement,
    required this.emblem,
    required this.motion,
    required this.index,
    required this.entryIndex,
    required this.onSelect,
    required this.onActivate,
    required this.onHoverChanged,
  })  : _placement = placement,
        _metrics = RealmNodeMetrics.of(placement.gravity),
        _shownAt = placement.position,
        super(
          priority: Layer.object,
          anchor: Anchor.center,
          size: Vector2(
            placement.gravity.componentSize.width,
            placement.gravity.componentSize.height,
          ),
        );

  Placement _placement;
  Placement get placement => _placement;

  final void Function(RealmNode) onSelect;
  final void Function(RealmNode) onActivate;
  final void Function(RealmNode, bool) onHoverChanged;
  final Sprite emblem;
  final Motion motion;
  final int index;
  final int entryIndex;

  RealmNodeMetrics _metrics;
  final _paint = RealmPaintCache();

  double zoom = 1;
  double contentFade = 1;
  double travelSlideY = 0;
  Vector2 worldSize = Vector2.all(1);
  bool selected = false;
  bool hidden = false;
  bool activeHover = false;

  FieldPoint _shownAt;
  FieldPoint? _gatherFrom;
  double _gatherElapsed = double.infinity;

  bool get isGathering => _gatherElapsed < Verb.gatherSettle;

  void regather() {
    _gatherFrom = _shownAt;
    _gatherElapsed = motion.reduced ? Verb.gatherSettle : 0;
  }

  void reseat(Placement next) {
    _gatherFrom = _shownAt;
    _gatherElapsed = motion.reduced ? Verb.gatherSettle : 0;

    if (next.gravity != _placement.gravity) {
      _metrics = RealmNodeMetrics.of(next.gravity);
      size = Vector2(
        next.gravity.componentSize.width,
        next.gravity.componentSize.height,
      );
      _placement = next;
      _paint.build(_metrics, _placement, size);
    } else {
      _placement = next;
    }
    if (motion.reduced) _shownAt = next.position;
  }

  static const _typeRevealZoom = 1.6;
  bool get _showType => _metrics.showType || zoom >= _typeRevealZoom;

  @override
  Future<void> onLoad() async =>
      _paint.build(_metrics, _placement, size);

  @override
  void onHoverEnter() {
    priority = Layer.object + 5;
    onHoverChanged(this, true);
  }

  @override
  void onHoverExit() {
    priority = Layer.object;
    onHoverChanged(this, false);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGathering) {
      _gatherElapsed += dt;
      final t = Verb.gather(
        (_gatherElapsed / Verb.gatherSettle).clamp(0.0, 1.0),
      );
      final from = _gatherFrom ?? _placement.position;
      _shownAt = FieldPoint(
        Verb.lerp(from.left, _placement.position.left, t),
        Verb.lerp(from.top, _placement.position.top, t),
      );
      if (!isGathering) _shownAt = _placement.position;
    }
    position = Vector2(
      _shownAt.left / 100 * worldSize.x,
      _shownAt.top / 100 * worldSize.y,
    );
  }

  @override
  void render(Canvas canvas) {
    if (hidden || contentFade <= 0.01) return;
    final entry = motion.entry(entryIndex);
    if (entry <= 0) return;

    final driftT = Verb.pingPong(
      motion.elapsed,
      Verb.nodeDriftPeriod(index),
      phase: Verb.nodeDriftPhase(index),
    );
    final dx = Verb.lerp(Verb.nodeDriftFrom.$1, Verb.nodeDriftTo.$1, driftT);
    final dy = Verb.lerp(Verb.nodeDriftFrom.$2, Verb.nodeDriftTo.$2, driftT);

    var breath = 1.0;
    if (_placement.gravity.level >= 2) {
      final period = Verb.lerp(
        Verb.breathePeriodMin,
        Verb.breathePeriodMax,
        (index % 5) / 4,
      );
      final t = Verb.easeInOut(
        Verb.pingPong(motion.elapsed, period, phase: index * -1.9),
      );
      breath = 1 + Verb.breatheScale * t;
    }

    final resolve = Verb.easeOut(entry);
    final alpha = Verb.lerp(Verb.resolveOpacityFrom, 1, resolve) * contentFade;

    canvas.save();
    canvas.translate(dx, dy + travelSlideY);
    if (breath != 1.0) {
      canvas.translate(_paint.centre.dx, _paint.centre.dy);
      canvas.scale(breath);
      canvas.translate(-_paint.centre.dx, -_paint.centre.dy);
    }
    if (alpha < 1) {
      canvas.saveLayer(
        null,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: alpha),
      );
    }

    _paint.paintCrest(
      canvas,
      _placement,
      emblem,
      motion,
      index,
      selected,
      _metrics,
    );
    _paint.paintLabel(
      canvas,
      _metrics,
      size,
      _showType,
      activeHover,
      _placement.cluster.accent,
    );

    if (alpha < 1) canvas.restore();
    canvas.restore();
  }
}

/// Layer 4 · Object.
///
/// > A Realm occupies the Field.
///
/// Anatomy, per the Design Lab canon §03:
///   **01** enamel rim + reflected light
///   **02** dark core + type icon
///   **03** attached label, **never floating**
///
/// Fidelity falls with distance, and that fall *is* the information: near
/// carries a unique Portrait, far a generic type glyph.
///
/// Motion: every node drifts on the reference's very slow orbit; Realms that
/// are Available or better also Breathe. Labels move with their object and
/// never independently.
library;

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../models.dart';
import '../placement.dart';
import 'layers.dart';
import 'motion.dart';

/// Per-band metrics. Sizes are fixed pixels — they never stretch with the
/// Field, only with the camera.
class _Metrics {
  const _Metrics(this.crest, this.nameSize, this.typeSize, this.showType);

  final double crest;
  final double nameSize;
  final double typeSize;
  final bool showType;

  static const _byBand = {
    DistanceBand.near: _Metrics(84, 13, 11, true),
    DistanceBand.middle: _Metrics(64, 12, 10, true),
    DistanceBand.far: _Metrics(40, 10, 9, false),
  };

  static _Metrics of(DistanceBand band) => _byBand[band]!;
}

class RealmNode extends PositionComponent with HoverCallbacks {
  RealmNode({
    required Placement placement,
    required this.emblem,
    required this.motion,
    required this.index,
    required this.entryIndex,
    required this.onSelect,
    required this.onActivate,
  })  : _placement = placement,
        _metrics = _Metrics.of(placement.band),
        _shownAt = placement.position,
        super(
          priority: Layer.object,
          anchor: Anchor.center,
          size: Vector2(
            placement.band.size.width,
            placement.band.size.height,
          ),
        );

  Placement _placement;

  /// The Realm as currently resolved. Gravity changes replace it.
  Placement get placement => _placement;

  /// Selection is inspection. The callback never enters anything.
  final void Function(RealmNode) onSelect;

  /// Explicit intent: opens the inspection alert. Still not entry.
  final void Function(RealmNode) onActivate;
  final Sprite emblem;
  final Motion motion;

  /// Position across the whole Field. Drives the drift and breathe phases, so
  /// no two nodes are ever in step.
  final int index;

  /// Position within this node's own cluster. Gather staggers *siblings*, so
  /// each cluster arrives together rather than the Field unrolling for four
  /// seconds.
  final int entryIndex;

  _Metrics _metrics;

  /// Current camera zoom. "Labels resolve by distance" — approaching lets the
  /// far band earn the type label it does not carry at rest.
  double zoom = 1;

  /// The Field's extent in world units, so percent can be resolved here rather
  /// than by the game — Gather has to move this node between layouts.
  Vector2 worldSize = Vector2.all(1);

  /// Selection brightens what is already there. It never enters, joins, or
  /// grants anything.
  bool selected = false;

  /// Prototype only: suppressed by the paging or collapse demo. The shipped
  /// Field never hides a Realm — "everything is present" is canon.
  bool hidden = false;

  /// Gather: where the Realm is travelling from and to, in percent, and how
  /// far through the 900ms settle it is.
  FieldPoint _shownAt;
  FieldPoint? _gatherFrom;
  double _gatherElapsed = double.infinity;

  bool get isGathering => _gatherElapsed < Verb.gatherSettle;

  /// Re-runs the arrival without moving anything.
  ///
  /// Focused is a Gather, and a Gather is *settling*, not travelling: the
  /// Realm arrives again at the place it already occupies. Position is the
  /// encoding — it says where this Realm sits in the Source's attention — so a
  /// state that displaced Realms would be rewriting meaning to express a mood.
  void regather() {
    _gatherFrom = _shownAt;
    _gatherElapsed = motion.reduced ? Verb.gatherSettle : 0;
  }

  /// Re-resolved after a Gravity change. The Realm travels to its new place
  /// over 900ms and may cross into a different distance band on the way.
  void reseat(Placement next) {
    _gatherFrom = _shownAt;
    _gatherElapsed = motion.reduced ? Verb.gatherSettle : 0;

    if (next.band != _placement.band) {
      _metrics = _Metrics.of(next.band);
      size = Vector2(next.band.size.width, next.band.size.height);
      _placement = next;
      _rebuildPaint();
    } else {
      _placement = next;
    }
    if (motion.reduced) _shownAt = next.position;
  }

  static const _typeRevealZoom = 1.6;

  bool get _showType => _metrics.showType || zoom >= _typeRevealZoom;

  Color get accent => placement.cluster.accent;
  double get bandOpacity => placement.band.opacity;

  /// Breathe is reserved for available or currently relevant objects. A Quiet
  /// Realm is legitimate context; it rests.
  bool get _breathes => placement.gravity.level >= 2;

  // ── Paint cache ───────────────────────────────────────────────────────
  // Gradients and text layout depend only on the crest geometry, which changes
  // just once per Gravity band crossing. Building them per frame across the
  // Field is the difference between 60fps and not.

  late double _r;
  late Offset _centre;
  late Rect _crestRect;
  late Paint _bloomPaint;
  late Paint _corePaint;
  late Paint _rimPaint;
  late Paint _innerRimPaint;
  late Paint _highlightPaint;
  late Paint _studFill;
  late Paint _studRim;
  late Paint _rolePaint;
  late Paint _selectionPaint;
  late TextPainter _namePainter;
  late TextPainter _typePainter;
  TextPainter? _motifPainter;
  late TextPainter _factsPainter;

  @override
  Future<void> onLoad() async => _rebuildPaint();

  void _rebuildPaint() {
    _r = _metrics.crest / 2;
    _centre = Offset(size.x / 2, _r + 2);
    _crestRect = Rect.fromCircle(center: _centre, radius: _r);

    _bloomPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: 0.24 * bandOpacity),
          const Color(0x00000000),
        ],
      ).createShader(Rect.fromCircle(center: _centre, radius: _r * 1.5));

    _corePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        colors: [
          Enamel.raisedWarmSurface.withValues(alpha: bandOpacity),
          Enamel.deepEspresso.withValues(alpha: bandOpacity),
        ],
      ).createShader(_crestRect);

    _rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = placement.realm.fixture ? 0.8 : 1.4
      ..color = accent.withValues(
        alpha: (placement.realm.fixture ? 0.42 : 0.86) * bandOpacity,
      );

    _innerRimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Enamel.sunGold.withValues(alpha: 0.30 * bandOpacity);

    _highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Enamel.cream.withValues(alpha: 0.16 * bandOpacity);

    _studFill = Paint()..color = Enamel.deepEspresso.withValues(alpha: 0.96);

    _studRim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = accent.withValues(alpha: 0.78 * bandOpacity);

    _rolePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = Enamel.sunGold.withValues(alpha: 0.22 * bandOpacity);

    // Selection increases the light of what is already drawn — it does not
    // add a new mark or a badge.
    _selectionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Enamel.cream.withValues(alpha: 0.72);

    // The reference tints a Realm's name with its cluster accent, so colour
    // carries cluster membership even before the label is read.
    final namePaint = TextPaint(
      style: TextStyle(
        fontFamily: Type.realmName.fontFamily,
        fontSize: _metrics.nameSize,
        height: 1.15,
        color: Color.lerp(accent, Enamel.cream, 0.30)!
            .withValues(alpha: bandOpacity),
        shadows: const [
          Shadow(color: Enamel.deepEspresso, blurRadius: 4),
          Shadow(color: Enamel.deepEspresso, blurRadius: 8),
        ],
      ),
    );
    final typePaint = TextPaint(
      style: TextStyle(
        fontFamily: Type.operational.fontFamily,
        fontWeight: FontWeight.w300,
        fontSize: _metrics.typeSize,
        letterSpacing: 0.9,
        color: Enamel.camel.withValues(alpha: bandOpacity * 0.82),
        shadows: const [Shadow(color: Enamel.deepEspresso, blurRadius: 4)],
      ),
    );
    // Motifs are symbol glyphs — ⌑ ✦ ◌ ◆ ♨ ≋ — that neither Goudy Heavyface
    // nor Avenir covers, and Flutter web cannot fall back to a system font
    // because CanvasKit only knows the fonts we bundle.
    final motifPaint = TextPaint(
      style: TextStyle(
        fontFamily: 'Motif',
        fontSize: _metrics.crest * 0.17,
        color: Enamel.cream.withValues(alpha: bandOpacity * 0.9),
      ),
    );
    final factsPaint = TextPaint(
      style: TextStyle(
        fontFamily: Type.operational.fontFamily,
        fontWeight: FontWeight.w300,
        fontSize: 10.5,
        letterSpacing: 0.4,
        color: Enamel.text,
      ),
    );

    _namePainter =
        namePaint.toTextPainter(_fit(placement.realm.name, _metrics.nameSize));
    _typePainter = typePaint.toTextPainter(placement.realm.typeName.toUpperCase());
    _motifPainter = placement.realm.motif.isEmpty
        ? null
        : motifPaint.toTextPainter(placement.realm.motif);
    _factsPainter = factsPaint.toTextPainter(placement.identityFacts);
  }

  // ── Interaction ───────────────────────────────────────────────────────

  @override
  void onHoverEnter() => priority = Layer.object + 5;

  @override
  void onHoverExit() => priority = Layer.object;

  @override
  void update(double dt) {
    super.update(dt);
    if (isGathering) {
      _gatherElapsed += dt;
      final t = Verb.gather(
        (_gatherElapsed / Verb.gatherSettle).clamp(0.0, 1.0),
      );
      final from = _gatherFrom ?? placement.position;
      _shownAt = FieldPoint(
        Verb.lerp(from.left, placement.position.left, t),
        Verb.lerp(from.top, placement.position.top, t),
      );
      if (!isGathering) _shownAt = placement.position;
    }
    position = Vector2(
      _shownAt.left / 100 * worldSize.x,
      _shownAt.top / 100 * worldSize.y,
    );
  }

  @override
  void render(Canvas canvas) {
    if (hidden) return;
    final entry = motion.entry(entryIndex);
    if (entry <= 0) return;

    // ── Drift ─────────────────────────────────────────────────────────
    // The reference's slow node orbit: 56–105s, staggered so nothing is in
    // phase, over roughly ±3px. Labels ride along inside the same transform,
    // so they never detach from their object.
    final driftT = Verb.pingPong(
      motion.elapsed,
      Verb.nodeDriftPeriod(index),
      phase: Verb.nodeDriftPhase(index),
    );
    final dx = Verb.lerp(Verb.nodeDriftFrom.$1, Verb.nodeDriftTo.$1, driftT);
    final dy = Verb.lerp(Verb.nodeDriftFrom.$2, Verb.nodeDriftTo.$2, driftT);

    // ── Breathe ───────────────────────────────────────────────────────
    // 1 → 1.035 → 1 over 6–8s. Never more.
    var breath = 1.0;
    if (_breathes) {
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

    // Entry: opacity .36 → 1, eased. Gather's stagger is applied by index.
    final resolve = Verb.easeOut(entry);
    final alpha = Verb.lerp(Verb.resolveOpacityFrom, 1, resolve);

    canvas.save();
    canvas.translate(dx, dy);
    if (breath != 1.0) {
      canvas.translate(_centre.dx, _centre.dy);
      canvas.scale(breath);
      canvas.translate(-_centre.dx, -_centre.dy);
    }
    if (alpha < 1) {
      canvas.saveLayer(
        null,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: alpha),
      );
    }

    _paintCrest(canvas);
    _paintLabel(canvas);

    if (alpha < 1) canvas.restore();
    canvas.restore();
  }

  void _paintCrest(Canvas canvas) {
    // ── 01 · Enamel rim and reflected light ──────────────────────────────
    // Light gathers locally around meaning: the accent bleeds into the ground.
    canvas.drawCircle(_centre, _r * 1.5, _bloomPaint);

    // ── 02 · Dark core ───────────────────────────────────────────────────
    canvas.drawCircle(_centre, _r, _corePaint);

    // Gold-wire rim. A proposed entity gets a broken rim: visible as
    // structure, never presented as though it already exists.
    if (placement.realm.fixture) {
      const segments = 12;
      const sweep = math.pi * 2 / segments;
      for (var i = 0; i < segments; i++) {
        canvas.drawArc(_crestRect, i * sweep, sweep * 0.55, false, _rimPaint);
      }
    } else {
      canvas.drawCircle(_centre, _r, _rimPaint);
      canvas.drawCircle(_centre, _r - 3, _innerRimPaint);
    }

    // Type emblem, clipped inside the core.
    final emblemSize = _r * 1.44;
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: _centre, radius: _r - 2)),
    );
    emblem.render(
      canvas,
      position: Vector2(_centre.dx - emblemSize / 2, _centre.dy - emblemSize / 2),
      size: Vector2.all(emblemSize),
      overridePaint: Paint()
        ..colorFilter = ColorFilter.mode(
          const Color(0xFFFFFFFF).withValues(alpha: bandOpacity),
          BlendMode.modulate,
        ),
    );
    canvas.restore();

    // ── Orbit · the role ring ────────────────────────────────────────────
    // 24s per revolution, tilted and flattened. Orbit denotes membership and
    // attention, so only Realms the viewer actually stands in carry one.
    if (placement.band != DistanceBand.far && placement.role != Role.guest) {
      final t = Verb.cycle(motion.elapsed, Verb.roleOrbitPeriod,
          phase: index * -2.1);
      canvas.save();
      canvas.translate(_centre.dx, _centre.dy);
      canvas.rotate(Verb.roleOrbitTilt * math.pi / 180);
      canvas.scale(1, Verb.roleOrbitFlatten);
      canvas.drawCircle(Offset.zero, _r * 1.22, _rolePaint);
      // A single phase node brightens as it travels — one signal, not many.
      final angle = t * math.pi * 2;
      canvas.drawCircle(
        Offset(math.cos(angle) * _r * 1.22, math.sin(angle) * _r * 1.22),
        1.7,
        Paint()..color = Enamel.sunGold.withValues(alpha: 0.62 * bandOpacity),
      );
      canvas.restore();
    }

    // Selection: brighten the rim that is already there.
    if (selected) {
      canvas.drawCircle(_centre, _r + 3, _selectionPaint);
    }

    // Reflected highlight along the upper rim.
    canvas.drawArc(
      Rect.fromCircle(center: _centre, radius: _r - 1),
      3.6,
      1.5,
      false,
      _highlightPaint,
    );

    // The Realm's own glyph, set in an anchor stud on the rim.
    final motif = _motifPainter;
    if (motif != null && placement.band != DistanceBand.far) {
      final stud = Offset(_centre.dx + _r * 0.70, _centre.dy + _r * 0.70);
      final studR = _metrics.crest * 0.155;
      canvas.drawCircle(stud, studR, _studFill);
      canvas.drawCircle(stud, studR, _studRim);
      motif.paint(
        canvas,
        Offset(stud.dx - motif.width / 2, stud.dy - motif.height / 2),
      );
    }
  }

  /// **03 · Attached label, never floating.** Drawn inside the same transform
  /// as the crest, so drift and breath move them together.
  void _paintLabel(Canvas canvas) {
    var y = _centre.dy + _r + 7;
    _namePainter.paint(canvas, Offset(size.x / 2 - _namePainter.width / 2, y));

    if (_showType) {
      y += _metrics.nameSize * 1.35;
      _typePainter.paint(canvas, Offset(size.x / 2 - _typePainter.width / 2, y));
    }

    // Hover identity: type · your role · stationed Ally. The reference shows
    // exactly these three facts and nothing more — hovering reveals standing,
    // never private activity.
    if (isHovered) {
      final w = _factsPainter.width + 16;
      final h = _factsPainter.height + 10;
      final rect = Rect.fromLTWH(size.x / 2 - w / 2, y + 20, w, h);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
      canvas.drawRRect(
        rrect,
        Paint()..color = Enamel.warmSurface.withValues(alpha: 0.96),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = accent.withValues(alpha: 0.5),
      );
      _factsPainter.paint(canvas, Offset(rect.left + 8, rect.top + 5));
    }
  }

  /// Keeps an overlong name attached to its node instead of letting it run
  /// into a neighbour. The full name still reaches inspection untouched.
  String _fit(String name, double fontSize) {
    final maxChars = (size.x / (fontSize * 0.52)).floor();
    if (name.length <= maxChars) return name;
    return '${name.substring(0, (maxChars - 1).clamp(1, name.length))}…';
  }
}

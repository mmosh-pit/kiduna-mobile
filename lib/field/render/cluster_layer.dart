/// Layer 2 · Geometry.
///
/// > Quiet orbital scaffolding establishes gravity.
///
/// The five clusters are **orbits**, and Realms are placed along them by
/// `placeRing()`. The ring is therefore the structure, not decoration around
/// it — which is why it is drawn at the reference's full weight, and why it is
/// the thing that carries the Field's ambient life.
///
/// Cluster atmospheres remain **restrained halos** — never hard containers,
/// never ranking boundaries. The interest tag sits **above** its ring, not
/// inside it.
library;

import 'dart:math' as math;
import 'dart:ui' show Picture, PictureRecorder;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../models.dart';
import 'layers.dart';
import '../../demo/nav_mode.dart';
import 'motion.dart';

class ClusterLayer extends PositionComponent {
  ClusterLayer(this.clusters, this.motion) : super(priority: Layer.geometry);

  final List<ClusterDef> clusters;
  final Motion motion;

  /// The interest tag sits **above** its orbit, not inside it.
  ///
  /// Measured from the live page's own DOM:
  ///   top   = ellipse top − 9px
  ///   left  = ellipse left + 12% of its width
  ///   7px · 700 · letter-spacing .77px · opacity .68
  ///   colour = color-mix(accent 46%, quiet)
  ///
  /// An earlier version centred it inside the ellipse, which read as a caption
  /// for empty space rather than a name for the ring.
  static const _labelOffsetY = -9.0;
  static const _labelOffsetXFraction = 0.12;

  /// The `--quiet` token the reference mixes each accent into. Derived from the
  /// rendered colours: every cluster solves to the same warm grey.
  static const _quiet = Color(0xFF8F8176);

  final Map<String, TextPaint> _labelPaints = {};

  TextPaint _labelFor(ClusterDef cluster) => _labelPaints.putIfAbsent(
        cluster.id,
        () => TextPaint(
          style: TextStyle(
            fontFamily: Type.body.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 7,
            letterSpacing: 0.77,
            color: Color.lerp(_quiet, cluster.accent, 0.46)!
                .withValues(alpha: 0.68),
          ),
        ),
      );

  /// Prototype: draw super-clusters instead of individual ones.
  bool _collapsed = false;
  set collapsed(bool value) {
    if (_collapsed == value) return;
    _collapsed = value;
    _recorded = null;
  }

  /// Prototype: draw every cluster as a star instead of an orbit.
  bool _starField = false;
  set starField(bool value) {
    if (_starField == value) return;
    _starField = value;
    _recorded = null;
  }

  /// How many Realms each cluster holds, for the star's size and its count.
  Map<String, int> realmCounts = const {};

  /// Prototype: when non-null, only these clusters are drawn.
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

  /// Groups the clusters by super-group for the collapse prototype, taking the
  /// bounding ellipse of each group.
  List<(String, Rect, Color, int)> _superClusters() {
    final groups = <String, List<ClusterDef>>{};
    for (final c in clusters) {
      if (c.isBranch) continue;
      groups.putIfAbsent(superGroupOf(c.id), () => []).add(c);
    }
    return [
      for (final entry in groups.entries)
        (
          entry.value.first.label.split(' · ').first,
          entry.value
              .map(_rectFor)
              .reduce((a, b) => a.expandToInclude(b))
              .inflate(18),
          entry.value.first.accent,
          entry.value.length,
        ),
    ];
  }

  /// The halo and label never change; the ring does. Recording the still part
  /// keeps the animated part cheap.
  Picture? _recorded;
  Vector2? _recordedFor;

  Rect _rectFor(ClusterDef cluster) => Rect.fromCenter(
        center: Offset(
          cluster.left / 100 * size.x,
          cluster.top / 100 * size.y,
        ),
        width: cluster.radiusX * 2 / 100 * size.x,
        height: cluster.radiusY * 2 / 100 * size.y,
      );

  @override
  void render(Canvas canvas) {
    if (_recorded == null || _recordedFor != size) {
      final recorder = PictureRecorder();
      _paintStill(Canvas(recorder));
      _recorded = recorder.endRecording();
      _recordedFor = size.clone();
    }
    canvas.drawPicture(_recorded!);
    _paintRings(canvas);
  }

  /// Halo and label — the parts that never move.
  void _paintStill(Canvas canvas) {
    if (_starField) {
      _paintStars(canvas);
      return;
    }
    if (_collapsed) {
      _paintSuperClusters(canvas);
      return;
    }
    for (final cluster in clusters) {
      // Branch carries no label and no halo in the root Field.
      if (cluster.isBranch || !_isVisible(cluster)) continue;

      final rect = _rectFor(cluster);
      final accent = cluster.accent;

      // A halo, not a container: it fades out entirely before its edge.
      // Matches the reference —
      //   background: radial-gradient(ellipse, accent 5%, transparent 69%)
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

      if (cluster.label.isEmpty) continue;
      _labelFor(cluster).render(
        canvas,
        cluster.label.toUpperCase(),
        Vector2(
          rect.left + rect.width * _labelOffsetXFraction,
          rect.top + _labelOffsetY,
        ),
        anchor: Anchor.topLeft,
      );
    }
  }

  /// Prototype: the same map, one scale coarser. Twenty rings become five,
  /// each carrying a count of what it holds. Nothing is removed — position is
  /// preserved, so a Realm stays where spatial memory expects it.
  void _paintSuperClusters(Canvas canvas) {
    for (final (label, rect, accent, count) in _superClusters()) {
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
      _labelPaints
          .putIfAbsent(
            'super-$label',
            () => TextPaint(
              style: TextStyle(
                fontFamily: Type.body.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 1.2,
                color: Color.lerp(_quiet, accent, 0.62)!,
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

  /// Prototype: the whole Ecosystem from above. Every cluster is a **star** —
  /// a mark, not a region — so all of them fit one screen however many there
  /// are. Travel toward one and it resolves into its orbit.
  ///
  /// Stars are **steady**. In this system moving light means *something
  /// changed there*, so a star that blinks to advertise itself would be making
  /// a claim it cannot back — the same error as a connector with no
  /// relationship behind it. What a star earns from its content is *size*,
  /// which encodes how much it holds and costs no motion at all.
  void _paintStars(Canvas canvas) {
    for (final cluster in clusters) {
      if (cluster.isBranch || !_isVisible(cluster)) continue;

      final centre = Offset(
        cluster.left / 100 * size.x,
        cluster.top / 100 * size.y,
      );
      final held = realmCounts[cluster.id] ?? 0;
      // Size carries content, within a tight range: the smallest star must
      // still read, the largest must not become a region again.
      final core = 3.4 + math.min(held, 8) * 0.42;
      final accent = cluster.accent;

      // Local reflected light — the ground gathering around meaning, which is
      // the one thing the canon says the dark field is *for*.
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

      // Four-point spike: a star, not a dot — and distinct from the eight-point
      // crossing glint, which means exchange and must stay unique to it.
      final spike = core * 3.1;
      canvas.drawPath(
        Path()
          ..moveTo(centre.dx, centre.dy - spike)
          ..quadraticBezierTo(
              centre.dx + core * 0.34, centre.dy - core * 0.34, centre.dx + spike, centre.dy)
          ..quadraticBezierTo(
              centre.dx + core * 0.34, centre.dy + core * 0.34, centre.dx, centre.dy + spike)
          ..quadraticBezierTo(
              centre.dx - core * 0.34, centre.dy + core * 0.34, centre.dx - spike, centre.dy)
          ..quadraticBezierTo(
              centre.dx - core * 0.34, centre.dy - core * 0.34, centre.dx, centre.dy - spike)
          ..close(),
        Paint()..color = accent.withValues(alpha: 0.62),
      );

      canvas.drawCircle(centre, core, Paint()..color = Enamel.cream);

      if (cluster.label.isEmpty) continue;
      _labelPaints
          .putIfAbsent(
            'star-${cluster.id}',
            () => TextPaint(
              style: TextStyle(
                fontFamily: Type.body.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 1.0,
                color: Color.lerp(_quiet, accent, 0.72)!
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

  /// The orbit itself: a ring that breathes, with one light travelling it.
  ///
  /// > Orbit — elliptical, object-centered. **One phase node brightens.**
  ///
  /// Realms do not move. Position is the encoding — a Realm's angle and radius
  /// say where it sits in the Source's attention — so a revolving Realm would
  /// stop meaning anything, and Gather would be unreadable against constant
  /// rotation. What moves is the *path* they sit on.
  void _paintRings(Canvas canvas) {
    if (_collapsed || _starField) return;
    for (var i = 0; i < clusters.length; i++) {
      final cluster = clusters[i];
      if (cluster.isBranch || !_isVisible(cluster)) continue;

      final rect = _rectFor(cluster);
      final accent = cluster.accent;

      // Breathe, kept well inside the 20% luminance ceiling: .24 ↔ .28.
      final breath = Verb.easeInOut(
        Verb.pingPong(motion.elapsed, 7 + i * 0.4, phase: i * -2.3),
      );
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          // The reference draws `1px solid color-mix(accent 24%, transparent)`.
          // An earlier version used 0.6px at 10% — under half — and the
          // orbital grouping barely read at all.
          ..color = accent.withValues(alpha: Verb.lerp(0.24, 0.28, breath)),
      );

      // The travelling light carries no information — it is the Field being
      // alive, not a fact about a Realm. So reduced motion removes it outright
      // rather than freezing a bright spot at an arbitrary angle. Nothing is
      // lost, which is the whole test.
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

      // One phase node, riding the ring it lights.
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

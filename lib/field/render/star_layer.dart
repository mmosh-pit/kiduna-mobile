/// Screen-space layer: the clusters you are **not** looking at.
///
/// A prototype for the twenty-cluster question, and deliberately outside the
/// contract. It answers the brief literally: only a handful of orbits are
/// reachable at once, the rest are stars, and a star is the way to them.
///
/// This layer lives on the **viewport**, not in the world, so its stars do not
/// pan, zoom, or drift with the Field. They are chrome — a border of
/// destinations around the region you currently occupy.
///
/// Each star keeps the *direction* of its real cluster: a cluster that lies to
/// the north-east of the active region appears on the north-east margin. The
/// position is a bearing, not a location, so spatial sense survives even though
/// the cluster itself cannot be reached by panning.
///
/// **Blinking is requested behaviour, not canon.** `05-ACCEPTANCE-CHECKLIST.md`
/// reserves moving light for real change ("a bright crossing glint means
/// exchange; it is never random sparkle"), so a star that pulses purely to
/// advertise itself is a deliberate departure. Recorded here so the departure
/// is visible to whoever rules on it, and confined to this file so removing it
/// is a one-line change.
library;

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../design/tokens.dart';
import '../models.dart';
import 'motion.dart';

/// A star drawn on the margin, and the cluster it stands for.
class StarTarget {
  StarTarget(this.cluster, this.centre, this.radius);

  final ClusterDef cluster;
  final Vector2 centre;
  final double radius;

  bool hit(Vector2 point) => centre.distanceTo(point) <= radius;
}

class StarLayer extends PositionComponent {
  StarLayer(this.motion) : super(priority: 900);

  final Motion motion;

  /// The clusters currently out of reach. Set by the game whenever the active
  /// window changes.
  List<ClusterDef> distant = const [];

  /// Where each distant cluster actually is, in world units, so the star can
  /// carry its bearing.
  Map<String, Vector2> worldCentres = const {};

  /// The centre of the active region in world units — the point bearings are
  /// measured from.
  Vector2 origin = Vector2.zero();

  /// Fades the whole layer during a traverse, so stars do not sit on top of a
  /// transition that is replacing everything beneath them.
  double opacity = 1;

  /// How far in from the viewport edge a star may sit.
  static const _margin = 64.0;

  /// The band of the sky the stars occupy, as a fraction of the half-extent.
  /// Inside 0.5 is where the active clusters are drawn, so nothing lands there.
  static const _innerBand = 0.58;
  static const _outerBand = 0.97;

  List<StarTarget> _targets = const [];

  /// The star under a viewport point, if any. Screen space — the game hit-tests
  /// with the raw canvas coordinate, no camera maths involved.
  ClusterDef? starAt(Vector2 viewportPoint) {
    for (final t in _targets) {
      if (t.hit(viewportPoint)) return t.cluster;
    }
    return null;
  }

  /// Scatters each distant cluster into the sky along its true bearing.
  ///
  /// Bearing gives direction — a cluster genuinely to the north-east appears in
  /// the north-east of the sky — while a deterministic depth, seeded from the
  /// cluster id, scatters them so they read as a star field rather than a row
  /// of buttons. Deterministic because a destination that moved between frames
  /// would be unaimable, and because spatial memory is the point.
  void _layout() {
    if (distant.isEmpty || size.x <= 0) {
      _targets = const [];
      return;
    }
    final rect = Rect.fromLTRB(
      _margin,
      _margin,
      size.x - _margin,
      size.y - _margin,
    );
    final centre = Vector2(rect.center.dx, rect.center.dy);
    final half = Vector2(rect.width / 2, rect.height / 2);

    final placed = <StarTarget>[];
    for (var i = 0; i < distant.length; i++) {
      final cluster = distant[i];
      final world = worldCentres[cluster.id];
      var angle = world == null
          ? (i / distant.length) * math.pi * 2
          : math.atan2(world.y - origin.y, world.x - origin.x);

      // A stable 0..1 from the id — no randomness, so the sky never reshuffles.
      final seed = cluster.id.codeUnits.fold<int>(17, (a, c) => (a * 31 + c) & 0xFFFF);
      final depth = _innerBand + (seed % 1000) / 1000 * (_outerBand - _innerBand);

      Vector2 at(double a, double d) => centre +
          Vector2(math.cos(a) * half.x * d, math.sin(a) * half.y * d);

      var point = at(angle, depth);
      // Nudge around the bearing until it clears its neighbours.
      var guard = 0;
      while (placed.any((p) => p.centre.distanceTo(point) < 62) && guard < 30) {
        angle += 0.21;
        point = at(angle, depth);
        guard++;
      }
      placed.add(StarTarget(cluster, point, 26));
    }
    _targets = placed;
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0.01) return;
    _layout();

    for (var i = 0; i < _targets.length; i++) {
      final target = _targets[i];
      final at = Offset(target.centre.x, target.centre.y);

      // The blink. Faster and far deeper than the ground's own 5.5s breathe,
      // which is what separates a destination from ordinary sky: same body,
      // different pulse. Reduced motion resolves it to full brightness, so no
      // destination is ever harder to find because someone turned motion off.
      final blink = motion.reduced
          ? 1.0
          : 0.12 +
              0.88 *
                  math.pow(
                    0.5 + 0.5 * math.sin(motion.elapsed * 2.6 + i * 1.9),
                    2.2,
                  ).toDouble();
      final a = blink * opacity;

      // Built exactly like a ground star — a cream core and two soft discs,
      // no mask blur — so it belongs to the same sky. Only the pulse and a
      // breath of the cluster's own enamel in the outer disc set it apart.
      const radius = 1.9;
      canvas.drawCircle(
        at,
        radius * 4.6,
        Paint()
          ..color = target.cluster.accent.withValues(alpha: a * 0.14),
      );
      canvas.drawCircle(
        at,
        radius * 2.5,
        Paint()..color = Enamel.cream.withValues(alpha: a * 0.16),
      );
      canvas.drawCircle(
        at,
        radius,
        Paint()..color = Enamel.cream.withValues(alpha: a * 0.95),
      );
    }
  }
}

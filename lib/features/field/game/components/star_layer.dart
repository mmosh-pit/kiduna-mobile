import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../enamel_tokens.dart';
import '../field_typography.dart';
import 'motion.dart';

class StaticStar {
  const StaticStar({
    required this.id,
    required this.label,
    required this.fractionX,
    required this.fractionY,
    required this.accent,
  });

  final String id;
  final String label;
  final double fractionX;
  final double fractionY;
  final Color accent;
}

const List<StaticStar> kStars = [
  StaticStar(
    id: 'organization',
    label: 'Organization',
    fractionX: 0.12,
    fractionY: 0.18,
    accent: Enamel.sunGold,
  ),
  StaticStar(
    id: 'agency',
    label: 'Agency',
    fractionX: 0.50,
    fractionY: 0.10,
    accent: Enamel.mint,
  ),
  StaticStar(
    id: 'community',
    label: 'Community',
    fractionX: 0.88,
    fractionY: 0.18,
    accent: Enamel.skyBlue,
  ),
  StaticStar(
    id: 'alliance',
    label: 'Alliance',
    fractionX: 0.14,
    fractionY: 0.85,
    accent: Enamel.camel,
  ),
  StaticStar(
    id: 'institution',
    label: 'Institution',
    fractionX: 0.86,
    fractionY: 0.85,
    accent: Enamel.cream,
  ),
];

class StarTarget {
  StarTarget(this.star, this.centre, this.radius);

  final StaticStar star;
  final Vector2 centre;
  final double radius;

  bool hit(Vector2 point) => centre.distanceTo(point) <= radius;
}

class StarLayer extends PositionComponent {
  StarLayer(this.motion) : super(priority: 900);

  final Motion motion;
  double opacity = 1;

  List<StarTarget> _targets = const [];
  final Map<String, TextPainter> _labels = {};

  StaticStar? starAt(Vector2 viewportPoint) {
    for (final t in _targets) {
      if (t.hit(viewportPoint)) {
        return t.star;
      }
    }
    return null;
  }

  void _layout() {
    if (size.x <= 0 || size.y <= 0) {
      _targets = const [];
      return;
    }
    _targets = [
      for (final star in kStars)
        StarTarget(
          star,
          Vector2(star.fractionX * size.x, star.fractionY * size.y),
          26,
        ),
    ];
  }

  TextPainter _labelFor(StaticStar star) =>
      _labels.putIfAbsent(star.id, () {
        final painter = TextPainter(
          text: TextSpan(
            text: star.label.toUpperCase(),
            style: TextStyle(
              fontFamily: Type.eyebrow.fontFamily,
              fontWeight: FontWeight.w800,
              fontSize: 8,
              letterSpacing: 1.4,
              color: star.accent,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        return painter;
      });

  @override
  void render(Canvas canvas) {
    if (opacity <= 0.01) {
      return;
    }
    _layout();

    for (var i = 0; i < _targets.length; i++) {
      final target = _targets[i];
      final at = Offset(target.centre.x, target.centre.y);

      final blink = motion.reduced
          ? 1.0
          : 0.12 +
              0.88 *
                  math.pow(
                    0.5 + 0.5 * math.sin(motion.elapsed * 2.6 + i * 1.9),
                    2.2,
                  ).toDouble();
      final a = blink * opacity;

      const radius = 1.9;
      canvas.drawCircle(
        at,
        radius * 4.6,
        Paint()..color = target.star.accent.withValues(alpha: a * 0.14),
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

      final label = _labelFor(target.star);
      label.paint(
        canvas,
        Offset(at.dx - label.width / 2, at.dy + 12),
      );
    }
  }
}

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../field_game.dart';

// One-off nebula colours from the prototype, not theme tokens.
const Color _nebulaWarm = Color.fromRGBO(64, 28, 15, 0.45);
const Color _nebulaTeal = Color.fromRGBO(7, 69, 72, 0.22);

/// A soft, blurred nebula ellipse that drifts horizontally over the loop.
class NebulaComponent extends Component with HasGameReference<FieldGame> {
  NebulaComponent({
    required this.centerFraction,
    required this.ellipse,
    required this.color,
  });

  /// The warm nebula in the upper-left of the prototype.
  NebulaComponent.warm()
    : centerFraction = const Offset(0.14, 0.16),
      ellipse = const Size(340, 150),
      color = _nebulaWarm;

  /// The teal nebula in the lower-right of the prototype.
  NebulaComponent.teal()
    : centerFraction = const Offset(0.86, 0.9),
      ellipse = const Size(290, 190),
      color = _nebulaTeal;

  final Offset centerFraction;
  final Size ellipse;
  final Color color;

  @override
  void render(Canvas canvas) {
    final Size size = Size(game.size.x, game.size.y);
    final Offset center = Offset(
      centerFraction.dx * size.width,
      centerFraction.dy * size.height,
    );
    final Paint paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 42)
      ..shader = Gradient.radial(center, ellipse.width / 2, [
        color.withValues(alpha: color.a * 0.23),
        color.withValues(alpha: 0),
      ]);
    final double drift = game.reduceMotion
        ? 0
        : math.sin(game.t * 2 * math.pi) * 8;
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(drift, 0),
        width: ellipse.width,
        height: ellipse.height,
      ),
      paint,
    );
  }
}

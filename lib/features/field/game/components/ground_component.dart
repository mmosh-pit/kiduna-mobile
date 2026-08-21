import 'dart:ui';

import 'package:flame/components.dart';

import '../field_game.dart';

// Decorative gradient and glow values taken verbatim from the prototype
// `.deepField` rules; one-off painting values, not theme tokens.
const Color _gradTop = Color(0xFF070403);
const Color _gradMid = Color(0xFF0A0604);
const Color _gradBottom = Color(0xFF0D0704);
const Color _warmGlow = Color.fromRGBO(77, 43, 23, 0.2);
const Color _skyGlow = Color.fromRGBO(3, 204, 217, 0.035);
const Color _goldGlow = Color.fromRGBO(234, 170, 0, 0.032);

/// The warm near-black gradient ground plus three soft radial glows. Rendered
/// first, so everything else sits on top.
class GroundComponent extends Component with HasGameReference<FieldGame> {
  @override
  void render(Canvas canvas) {
    final Size size = Size(game.size.x, game.size.y);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(size.width, size.height),
          const [_gradTop, _gradMid, _gradBottom],
          const [0, 0.48, 1],
        ),
    );
    _glow(canvas, size, const Offset(0.52, 0.48), _warmGlow, 0.29);
    _glow(canvas, size, const Offset(0.18, 0.24), _skyGlow, 0.24);
    _glow(canvas, size, const Offset(0.83, 0.71), _goldGlow, 0.22);
  }

  void _glow(
    Canvas canvas,
    Size size,
    Offset centerFraction,
    Color color,
    double radiusFraction,
  ) {
    final Offset center = Offset(
      centerFraction.dx * size.width,
      centerFraction.dy * size.height,
    );
    final double radius = radiusFraction * size.longestSide;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = Gradient.radial(center, radius, [
          color,
          color.withValues(alpha: 0),
        ]),
    );
  }
}

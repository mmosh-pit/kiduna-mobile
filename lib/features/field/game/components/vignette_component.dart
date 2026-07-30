import 'dart:ui';

import 'package:flame/components.dart';

import '../field_game.dart';

// One-off vignette colour from the prototype, not a theme token.
const Color _vignette = Color.fromRGBO(0, 0, 0, 0.68);

/// Radial darkening drawn last so it sits over every other layer.
class VignetteComponent extends Component with HasGameReference<FieldGame> {
  @override
  void render(Canvas canvas) {
    final Size size = Size(game.size.x, game.size.y);
    final Offset center = size.center(Offset.zero);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = Gradient.radial(
          center,
          size.longestSide * 0.72,
          [_vignette.withValues(alpha: 0), _vignette],
          const [0.55, 1],
        ),
    );
  }
}

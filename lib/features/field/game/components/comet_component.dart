import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../field_game.dart';

/// A distant comet — a short gradient trail with a bright head.
class CometComponent extends Component with HasGameReference<FieldGame> {
  @override
  void render(Canvas canvas) {
    final Size size = Size(game.size.x, game.size.y);
    final Offset start = Offset(size.width * 0.16, size.height * 0.81);
    canvas.save();
    canvas.translate(start.dx, start.dy);
    canvas.rotate(-27 * math.pi / 180);
    canvas.drawRect(
      const Rect.fromLTWH(0, -0.5, 78, 1),
      Paint()
        ..shader = Gradient.linear(Offset.zero, const Offset(78, 0), [
          game.palette.sky.withValues(alpha: 0),
          game.palette.cream.withValues(alpha: 0.36),
        ]),
    );
    canvas.drawCircle(
      const Offset(78, 0),
      2.5,
      Paint()..color = game.palette.cream.withValues(alpha: 0.7),
    );
    canvas.restore();
  }
}

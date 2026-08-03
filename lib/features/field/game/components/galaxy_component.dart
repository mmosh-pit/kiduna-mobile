import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../field_game.dart';

/// A faint distant galaxy — a tilted ring with a bright core dot.
class GalaxyComponent extends Component with HasGameReference<FieldGame> {
  @override
  void render(Canvas canvas) {
    final Size size = Size(game.size.x, game.size.y);
    final Offset center = Offset(size.width * 0.84, size.height * 0.24);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-18 * math.pi / 180);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 72, height: 25),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = game.palette.cream.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      const Offset(14, 0),
      1.5,
      Paint()..color = game.palette.gold.withValues(alpha: 0.55),
    );
    canvas.restore();
  }
}

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../field_game.dart';

/// Stars as `[left%, top%, size px, opacity, motion]` — the exact array from
/// the prototype plus additional stars for consistent density at all zoom
/// levels. `motion == 0` is a still star; any other value seeds a breathing,
/// drifting star.
const List<List<double>> _stars = [
  [5, 12, 1, .42, 0],
  [11, 68, 2, .74, 1],
  [16, 35, 1, .35, 0],
  [20, 84, 1, .52, 2],
  [25, 18, 2, .58, 0],
  [29, 57, 1, .3, 1],
  [34, 76, 1, .54, 0],
  [39, 27, 1, .48, 3],
  [43, 90, 2, .7, 0],
  [47, 44, 1, .32, 1],
  [52, 13, 1, .43, 0],
  [55, 68, 1, .6, 2],
  [60, 33, 2, .75, 0],
  [64, 82, 1, .34, 1],
  [69, 20, 1, .46, 0],
  [72, 57, 1, .56, 3],
  [77, 9, 2, .68, 0],
  [81, 73, 1, .42, 2],
  [85, 39, 1, .5, 0],
  [89, 88, 1, .33, 1],
  [94, 24, 2, .64, 0],
  [8, 47, 1, .26, 2],
  [14, 93, 1, .44, 0],
  [31, 8, 1, .38, 1],
  [37, 63, 2, .62, 0],
  [49, 79, 1, .28, 3],
  [58, 95, 1, .4, 0],
  [67, 47, 1, .3, 2],
  [75, 91, 2, .63, 0],
  [87, 59, 1, .39, 1],
  [96, 70, 1, .47, 0],
  [92, 6, 1, .35, 2],
  [3, 31, 1, .29, 0],
  [7, 78, 1, .36, 1],
  [13, 22, 1, .31, 0],
  [18, 55, 1, .44, 2],
  [22, 41, 1, .27, 0],
  [27, 72, 1, .38, 1],
  [33, 15, 1, .42, 0],
  [36, 88, 1, .33, 3],
  [41, 50, 1, .29, 0],
  [46, 65, 1, .37, 1],
  [50, 29, 1, .34, 0],
  [54, 85, 1, .41, 2],
  [57, 7, 1, .28, 0],
  [62, 53, 1, .35, 1],
  [66, 38, 1, .32, 0],
  [70, 74, 1, .39, 3],
  [74, 16, 1, .36, 0],
  [79, 62, 1, .3, 2],
  [83, 48, 1, .34, 0],
  [88, 25, 1, .37, 1],
  [91, 81, 1, .31, 0],
  [95, 42, 1, .28, 2],
  [2, 58, 1, .25, 0],
  [10, 3, 1, .33, 0],
  [24, 97, 1, .27, 1],
  [38, 42, 1, .3, 0],
  [45, 17, 1, .35, 2],
  [53, 73, 1, .29, 0],
  [61, 62, 1, .32, 1],
  [68, 5, 1, .26, 0],
  [76, 34, 1, .34, 3],
  [84, 86, 1, .3, 0],
  [90, 51, 1, .28, 1],
  [97, 14, 1, .31, 0],
  [15, 48, 1, .24, 0],
  [28, 33, 1, .27, 2],
  [42, 71, 1, .3, 0],
  [56, 22, 1, .26, 0],
  [73, 45, 1, .29, 1],
  [86, 67, 1, .25, 0],
];

/// The sparse living starfield — still stars plus breathing, drifting ones.
class StarFieldComponent extends Component with HasGameReference<FieldGame> {
  @override
  void render(Canvas canvas) {
    final Size size = Size(game.size.x, game.size.y);
    final bool reduceMotion = game.reduceMotion;
    final double t = game.t;
    final Color cream = game.palette.cream;

    for (final star in _stars) {
      final double baseOpacity = star[3];
      final int motion = star[4].toInt();
      double opacity = baseOpacity;
      double dx = 0;
      double dy = 0;
      if (motion != 0 && !reduceMotion) {
        final double phase = motion * 0.21;
        final double wave = (math.sin((t + phase) * 2 * math.pi) + 1) / 2;
        opacity = lerpDouble(0.24, 0.82, wave)!;
        dx = 9 * wave;
        dy = -5 * wave;
      } else if (motion != 0) {
        opacity = 0.53;
      }
      final Offset center = Offset(
        star[0] / 100 * size.width + dx,
        star[1] / 100 * size.height + dy,
      );
      canvas.drawCircle(
        center,
        star[2] / 2,
        Paint()..color = cream.withValues(alpha: opacity),
      );
    }
  }
}

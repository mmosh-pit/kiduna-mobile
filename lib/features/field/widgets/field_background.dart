import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../config/kiduna_colors.dart';
import '../../../core/extensions/context_extensions.dart';

// Decorative gradient and glow values taken verbatim from the prototype
// `.deepField` rules; they are one-off painting values, not theme tokens.
const Color _gradTop = Color(0xFF070403);
const Color _gradMid = Color(0xFF0A0604);
const Color _gradBottom = Color(0xFF0D0704);
const Color _warmGlow = Color.fromRGBO(77, 43, 23, 0.2);
const Color _skyGlow = Color.fromRGBO(3, 204, 217, 0.035);
const Color _goldGlow = Color.fromRGBO(234, 170, 0, 0.032);
const Color _nebulaWarm = Color.fromRGBO(64, 28, 15, 0.45);
const Color _nebulaTeal = Color.fromRGBO(7, 69, 72, 0.22);
const Color _vignette = Color.fromRGBO(0, 0, 0, 0.68);

/// Stars as `[left%, top%, size px, opacity, motion]` — the exact array from
/// the prototype. `motion == 0` is a still star; any other value seeds a
/// breathing, drifting star.
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
];

/// The deep Field ground: a warm near-black gradient with sparse living light —
/// stars, nebulae, a distant galaxy, and a comet.
///
/// Motion (breathing stars, drift) runs on a single looping controller and is
/// suppressed when the platform requests reduced motion, matching the
/// prototype's `prefers-reduced-motion` behaviour.
class FieldBackground extends StatefulWidget {
  const FieldBackground({super.key});

  @override
  State<FieldBackground> createState() => _FieldBackgroundState();
}

class _FieldBackgroundState extends State<FieldBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _DeepFieldPainter(
              t: _controller.value,
              reduceMotion: reduceMotion,
              colors: context.kiduna,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _DeepFieldPainter extends CustomPainter {
  const _DeepFieldPainter({
    required this.t,
    required this.reduceMotion,
    required this.colors,
  });

  final double t;
  final bool reduceMotion;
  final KidunaColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    _paintGround(canvas, rect, size);
    _paintGlow(canvas, size, const Offset(.52, .48), _warmGlow, .29);
    _paintGlow(canvas, size, const Offset(.18, .24), _skyGlow, .24);
    _paintGlow(canvas, size, const Offset(.83, .71), _goldGlow, .22);
    _paintNebula(
      canvas,
      size,
      const Offset(.14, .16),
      const Size(340, 150),
      _nebulaWarm,
    );
    _paintNebula(
      canvas,
      size,
      const Offset(.86, .9),
      const Size(290, 190),
      _nebulaTeal,
    );
    _paintGalaxy(canvas, size);
    _paintComet(canvas, size);
    _paintStars(canvas, size);
    _paintVignette(canvas, size);
  }

  void _paintGround(Canvas canvas, Rect rect, Size size) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        const [_gradTop, _gradMid, _gradBottom],
        const [0, .48, 1],
      );
    canvas.drawRect(rect, paint);
  }

  void _paintGlow(
    Canvas canvas,
    Size size,
    Offset centerFraction,
    Color color,
    double radiusFraction,
  ) {
    final center = Offset(
      centerFraction.dx * size.width,
      centerFraction.dy * size.height,
    );
    final radius = radiusFraction * size.longestSide;
    final paint = Paint()
      ..shader = ui.Gradient.radial(center, radius, [
        color,
        color.withValues(alpha: 0),
      ]);
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _paintNebula(
    Canvas canvas,
    Size size,
    Offset centerFraction,
    Size ellipse,
    Color color,
  ) {
    final center = Offset(
      centerFraction.dx * size.width,
      centerFraction.dy * size.height,
    );
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 42)
      ..shader = ui.Gradient.radial(center, ellipse.width / 2, [
        color.withValues(alpha: color.a * 0.23),
        color.withValues(alpha: 0),
      ]);
    final drift = reduceMotion ? 0.0 : math.sin(t * 2 * math.pi) * 8;
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(drift, 0),
        width: ellipse.width,
        height: ellipse.height,
      ),
      paint,
    );
  }

  void _paintGalaxy(Canvas canvas, Size size) {
    final center = Offset(size.width * .84, size.height * .24);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = colors.cream.withValues(alpha: .16);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-18 * math.pi / 180);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 72, height: 25),
      ring,
    );
    canvas.drawCircle(
      const Offset(14, 0),
      1.5,
      Paint()..color = colors.gold.withValues(alpha: .55),
    );
    canvas.restore();
  }

  void _paintComet(Canvas canvas, Size size) {
    final start = Offset(size.width * .16, size.height * .81);
    canvas.save();
    canvas.translate(start.dx, start.dy);
    canvas.rotate(-27 * math.pi / 180);
    final trail = Paint()
      ..shader = ui.Gradient.linear(Offset.zero, const Offset(78, 0), [
        colors.sky.withValues(alpha: 0),
        colors.cream.withValues(alpha: .36),
      ]);
    canvas.drawRect(const Rect.fromLTWH(0, -.5, 78, 1), trail);
    canvas.drawCircle(
      const Offset(78, 0),
      2.5,
      Paint()..color = colors.cream.withValues(alpha: .7),
    );
    canvas.restore();
  }

  void _paintStars(Canvas canvas, Size size) {
    for (final star in _stars) {
      final baseOpacity = star[3];
      final motion = star[4].toInt();
      var opacity = baseOpacity;
      var dx = 0.0;
      var dy = 0.0;
      if (motion != 0 && !reduceMotion) {
        final phase = motion * 0.21;
        final wave = (math.sin((t + phase) * 2 * math.pi) + 1) / 2;
        opacity = ui.lerpDouble(.24, .82, wave)!;
        dx = 9 * wave;
        dy = -5 * wave;
      } else if (motion != 0) {
        opacity = .53;
      }
      final center = Offset(
        star[0] / 100 * size.width + dx,
        star[1] / 100 * size.height + dy,
      );
      canvas.drawCircle(
        center,
        star[2] / 2,
        Paint()..color = colors.cream.withValues(alpha: opacity),
      );
    }
  }

  void _paintVignette(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        size.longestSide * .72,
        [_vignette.withValues(alpha: 0), _vignette],
        const [.55, 1],
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_DeepFieldPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.reduceMotion != reduceMotion ||
      oldDelegate.colors != colors;
}

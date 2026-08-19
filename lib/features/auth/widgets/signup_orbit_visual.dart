import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../config/assets.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../shared/animations/breathe_animation.dart';
import '../../../shared/animations/rotate_animation.dart';

class SignupOrbitVisual extends StatelessWidget {
  const SignupOrbitVisual({super.key, this.size = 300});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return SizedBox(
      width: size,
      height: size,
      child: BreatheAnimation(
        duration: const Duration(seconds: 6),
        minScale: 1.0,
        maxScale: 1.06,
        minOpacity: 0.7,
        maxOpacity: 1.0,
        child: Stack(
          children: [
            // Outer ring
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.sky.withValues(alpha: 0.12)),
                ),
              ),
            ),
            // Dashed middle ring
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(size * 0.14),
                child: RotateAnimation(
                  duration: const Duration(seconds: 45),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.camel.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Inner ring
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(size * 0.30),
                child: RotateAnimation(
                  duration: const Duration(seconds: 60),
                  reverse: true,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.mint.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Beam 1
            Center(
              child: _BeamFlash(
                width: size * 1.07,
                angle: -25,
                color: colors.sky.withValues(alpha: 0.30),
                duration: const Duration(seconds: 4),
              ),
            ),
            // Beam 2
            Center(
              child: _BeamFlash(
                width: size * 0.93,
                angle: 40,
                color: colors.camel.withValues(alpha: 0.25),
                duration: const Duration(seconds: 4),
                delay: const Duration(milliseconds: 1500),
              ),
            ),
            // Orbiting dots
            _OrbitingDot(
              orbitSize: size,
              radius: size * 0.433,
              dotSize: 12,
              color: colors.camel,
              duration: const Duration(seconds: 12),
              startAngle: 0,
            ),
            _OrbitingDot(
              orbitSize: size,
              radius: size * 0.317,
              dotSize: 9,
              color: colors.sky,
              duration: const Duration(seconds: 16),
              startAngle: 120,
            ),
            _OrbitingDot(
              orbitSize: size,
              radius: size * 0.533,
              dotSize: 7,
              color: colors.mint,
              duration: const Duration(seconds: 20),
              startAngle: 240,
            ),
            // Core glow
            Center(
              child: BreatheAnimation(
                duration: const Duration(seconds: 4),
                minOpacity: 0.5,
                maxOpacity: 1.0,
                minScale: 1.0,
                maxScale: 1.15,
                child: Container(
                  width: size * 0.533,
                  height: size * 0.533,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colors.sky.withValues(alpha: 0.14),
                        colors.gold.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.35, 0.7],
                    ),
                  ),
                ),
              ),
            ),
            // Kiduna mark
            Center(
              child: SvgPicture.asset(
                AppAssets.kidunaMark,
                width: size * 0.213,
                height: size * 0.213,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BeamFlash extends StatefulWidget {
  const _BeamFlash({
    required this.width,
    required this.angle,
    required this.color,
    this.duration = const Duration(seconds: 4),
    this.delay = Duration.zero,
  });

  final double width;
  final double angle;
  final Color color;
  final Duration duration;
  final Duration delay;

  @override
  State<_BeamFlash> createState() => _BeamFlashState();
}

class _BeamFlashState extends State<_BeamFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.delay == Duration.zero) {
      _controller.repeat();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) {
          _controller.repeat();
        }
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  double _beamOpacity(double t) {
    if (t < 0.3) return t / 0.3;
    if (t > 0.7) return (1 - t) / 0.3;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(opacity: _beamOpacity(_controller.value), child: child);
      },
      child: Transform.rotate(
        angle: widget.angle * math.pi / 180,
        child: Container(
          width: widget.width,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, widget.color, Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitingDot extends StatefulWidget {
  const _OrbitingDot({
    required this.orbitSize,
    required this.radius,
    required this.dotSize,
    required this.color,
    required this.duration,
    this.startAngle = 0,
  });

  final double orbitSize;
  final double radius;
  final double dotSize;
  final Color color;
  final Duration duration;
  final double startAngle;

  @override
  State<_OrbitingDot> createState() => _OrbitingDotState();
}

class _OrbitingDotState extends State<_OrbitingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final angle =
            (widget.startAngle + _controller.value * 360) * math.pi / 180;
        final center = widget.orbitSize / 2;
        final x = center + widget.radius * math.cos(angle) - widget.dotSize / 2;
        final y = center + widget.radius * math.sin(angle) - widget.dotSize / 2;

        return Positioned(
          left: x,
          top: y,
          child: Container(
            width: widget.dotSize,
            height: widget.dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

class RotateAnimation extends StatefulWidget {
  const RotateAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 45),
    this.reverse = false,
  });

  final Widget child;
  final Duration duration;
  final bool reverse;

  @override
  State<RotateAnimation> createState() => _RotateAnimationState();
}

class _RotateAnimationState extends State<RotateAnimation>
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
      builder: (context, child) {
        final angle = widget.reverse
            ? -_controller.value * 2 * math.pi
            : _controller.value * 2 * math.pi;
        return Transform.rotate(angle: angle, child: child);
      },
      child: widget.child,
    );
  }
}

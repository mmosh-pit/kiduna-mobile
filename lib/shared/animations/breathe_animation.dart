import 'package:flutter/material.dart';

class BreatheAnimation extends StatefulWidget {
  const BreatheAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 4),
    this.minOpacity = 0.22,
    this.maxOpacity = 0.45,
    this.minScale = 1.0,
    this.maxScale = 1.03,
    this.scaleEnabled = true,
    this.opacityEnabled = true,
  });

  final Widget child;
  final Duration duration;
  final double minOpacity;
  final double maxOpacity;
  final double minScale;
  final double maxScale;
  final bool scaleEnabled;
  final bool opacityEnabled;

  @override
  State<BreatheAnimation> createState() => _BreatheAnimationState();
}

class _BreatheAnimationState extends State<BreatheAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
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
        final t = Curves.easeInOut.transform(_controller.value);
        final scale = widget.scaleEnabled
            ? widget.minScale + (widget.maxScale - widget.minScale) * t
            : 1.0;
        final opacity = widget.opacityEnabled
            ? widget.minOpacity + (widget.maxOpacity - widget.minOpacity) * t
            : 1.0;
        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: opacity, child: child),
        );
      },
      child: widget.child,
    );
  }
}

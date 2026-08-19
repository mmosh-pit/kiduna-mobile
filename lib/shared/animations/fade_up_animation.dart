import 'dart:async';

import 'package:flutter/material.dart';

class FadeUpAnimation extends StatefulWidget {
  const FadeUpAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.offset = 18.0,
    this.curve = Curves.easeOut,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;
  final Curve curve;

  @override
  State<FadeUpAnimation> createState() => _FadeUpAnimationState();
}

class _FadeUpAnimationState extends State<FadeUpAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offset),
      end: Offset.zero,
    ).animate(curved);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) {
          _controller.forward();
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _slide.value,
          child: Opacity(opacity: _opacity.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}

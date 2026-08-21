import 'dart:math' as math;

import 'package:flutter/material.dart';

class SignupParticles extends StatefulWidget {
  const SignupParticles({super.key});

  @override
  State<SignupParticles> createState() => _SignupParticlesState();
}

class _SignupParticlesState extends State<SignupParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final _random = math.Random();

  static const List<Color> _colors = [
    Color.fromRGBO(3, 204, 217, 0.5),
    Color.fromRGBO(193, 154, 107, 0.4),
    Color.fromRGBO(143, 230, 198, 0.35),
    Color.fromRGBO(234, 170, 0, 0.35),
    Color.fromRGBO(255, 251, 245, 0.2),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    for (var i = 0; i < 15; i++) {
      _particles.add(_createParticle());
    }
  }

  _Particle _createParticle() {
    return _Particle(
      x: 0.1 + _random.nextDouble() * 0.8,
      y: _random.nextDouble(),
      size: 2 + _random.nextDouble() * 3,
      speed: 0.0005 + _random.nextDouble() * 0.001,
      color: _colors[_random.nextInt(_colors.length)],
      opacity: 0.3 + _random.nextDouble() * 0.5,
    );
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
        for (var particle in _particles) {
          particle.y -= particle.speed;
          if (particle.y < -0.05) {
            particle.y = 1.05;
            particle.x = 0.1 + _random.nextDouble() * 0.8;
          }
        }

        return CustomPaint(
          painter: _ParticlePainter(_particles),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final Color color;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.particles);

  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final distFromCenter = (p.y - 0.5).abs() * 2;
      final fadeOpacity = p.opacity * (1 - distFromCenter).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: fadeOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size / 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

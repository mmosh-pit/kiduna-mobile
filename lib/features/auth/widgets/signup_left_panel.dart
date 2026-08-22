import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../shared/animations/fade_up_animation.dart';
import 'signup_orbit_visual.dart';
import 'signup_particles.dart';

class SignupLeftPanel extends StatelessWidget {
  const SignupLeftPanel({
    super.key,
    this.tagline = 'The Genesis Ecosystem believes you belong here.',
    this.headingPrefix = 'Welcome ',
    this.headingAccent = 'Home',
    this.description = 'Join The Genesis Ecosystem and a trusted community of creators, builders, organizers, and intelligent agents shaping a network where everyone has a place and a part to play.',
  });

  final String tagline;
  final String headingPrefix;
  final String headingAccent;
  final String description;

  static const Color _panelBg = Color(0xFF060304);

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final isMobile = context.isMobile;
    final orbitSize = isMobile ? 260.0 : 300.0;

    return Container(
      color: _panelBg,
      child: Stack(
        children: [
          // Ambient gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.4, -0.6),
                  radius: 0.5,
                  colors: [
                    const Color(0xFF2A1A2B).withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.5, 0.6),
                  radius: 0.5,
                  colors: [
                    const Color(0xFF1C140D).withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Particles
          const Positioned.fill(child: SignupParticles()),
          // Bottom gradient
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 120,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    colors.surface.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24 : 56,
                        vertical: isMobile ? 44 : 48,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FadeUpAnimation(
                              delay: const Duration(milliseconds: 200),
                              child: SignupOrbitVisual(size: orbitSize),
                            ),
                            const SizedBox(height: 32),
                            FadeUpAnimation(
                              delay: const Duration(milliseconds: 400),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      tagline,
                                      style: text.eyebrow.copyWith(
                                        color: colors.sky,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '✦',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colors.gold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            FadeUpAnimation(
                              delay: const Duration(milliseconds: 500),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: text.displayLarge.copyWith(
                                    color: colors.text,
                                    fontSize: isMobile ? 32 : 48,
                                  ),
                                  children: [
                                    TextSpan(text: headingPrefix),
                                    TextSpan(
                                      text: headingAccent,
                                      style: TextStyle(color: colors.gold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            FadeUpAnimation(
                              delay: const Duration(milliseconds: 600),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 420,
                                ),
                                child: Text(
                                  description,
                                  style: text.body.copyWith(
                                    color: colors.muted,
                                    fontSize: 15,
                                    height: 1.6,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

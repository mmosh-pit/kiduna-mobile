import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// Premium animated progress bar — thicker track, gradient fill with shimmer
/// effect, bold labels.
class PresaleProgressBar extends StatelessWidget {
  const PresaleProgressBar({
    super.key,
    required this.sold,
    required this.total,
    required this.progress,
  });

  final String sold;
  final String total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final fraction = (progress / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Bar ──
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: colors.deep,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: colors.line,
              width: 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.gold.withValues(alpha: 0.5),
                          colors.gold.withValues(alpha: 0.8),
                          colors.gold,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: colors.gold.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        // ── Labels ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$sold sold',
              style: context.kidunaText.micro.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: colors.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${progress.toStringAsFixed(0)}%',
                style: context.kidunaText.micro.copyWith(
                  color: colors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

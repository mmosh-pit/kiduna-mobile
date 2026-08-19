import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../shared/animations/fade_up_animation.dart';

class CheckoutHowItWorks extends StatelessWidget {
  const CheckoutHowItWorks({super.key});

  static const _steps = [
    _StepData(
      title: 'Choose how to add \$100 to your Kiduna account',
      body: 'Buy \$USDC with a card below, or transfer it from a Solana wallet you already use.',
    ),
    _StepData(
      title: 'Your funds will purchase compute resources',
      body: 'Compute resources are stored on the blockchain to power global movements.',
    ),
    _StepData(
      title: 'Lock in the pre-launch price!',
      body: 'To protect our planetary ecosystem, compute supply will be responsibly limited by design.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return FadeUpAnimation(
      delay: const Duration(milliseconds: 100),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          border: Border.all(color: colors.camel.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFF1E150E).withValues(alpha: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('✦', style: TextStyle(color: colors.gold, fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  'How it works',
                  style: text.body.copyWith(
                    color: colors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ..._steps.asMap().entries.map(
              (entry) => Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key < _steps.length - 1 ? 15 : 0,
                ),
                child: _StepRow(number: entry.key + 1, data: entry.value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepData {
  const _StepData({required this.title, required this.body});
  final String title;
  final String body;
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.data});

  final int number;
  final _StepData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.sky.withValues(alpha: 0.1),
            border: Border.all(color: colors.sky.withValues(alpha: 0.22)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: text.eyebrow.copyWith(
              color: colors.sky,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: text.body.copyWith(
                  color: colors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.body,
                style: text.body.copyWith(
                  color: colors.muted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

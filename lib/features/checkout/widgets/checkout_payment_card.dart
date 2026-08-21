import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../shared/animations/fade_up_animation.dart';
import '../../../shared/widgets/kiduna_gold_button.dart';
import '../../../shared/widgets/kiduna_secondary_button.dart';

class CheckoutPaymentCard extends StatelessWidget {
  const CheckoutPaymentCard({
    super.key,
    required this.onBuyUsdc,
    required this.onConnectWallet,
  });

  final VoidCallback onBuyUsdc;
  final VoidCallback onConnectWallet;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final isMobile = context.isMobile;

    return FadeUpAnimation(
      delay: const Duration(milliseconds: 250),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          border: Border.all(color: colors.sky.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFF0A0805).withValues(alpha: 0.9),
          boxShadow: [
            BoxShadow(
              color: colors.sky.withValues(alpha: 0.05),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PaymentHeading(colors: colors, text: text, isMobile: isMobile),
            const SizedBox(height: 18),
            _PurchaseOption(
              label: 'Buy 100 USDC',
              description: 'Pay with your card. Your \$100 is moved to the blockchain where it becomes a resource for creating change.',
              badgeLabel: 'Easiest',
              badgeType: _BadgeType.gold,
              actionChild: KidunaGoldButton(
                label: 'Buy 100 USDC',
                onPressed: onBuyUsdc,
              ),
            ),
            const SizedBox(height: 10),
            _PurchaseOption(
              label: 'Use a Solana wallet',
              description: 'Already have USDC? Connect your wallet and transfer 100 USDC directly.',
              badgeLabel: 'Fastest',
              badgeType: _BadgeType.sky,
              actionChild: Padding(
                padding: const EdgeInsets.only(top: 13),
                child: KidunaSecondaryButton(
                  label: 'Connect Solana Wallet',
                  onPressed: onConnectWallet,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'This one-time compute purchase grants you a lifetime founding '
              'membership in the organizations of your choice. · Additional '
              'compute can be purchased later as needed.',
              style: text.label.copyWith(
                color: colors.quiet,
                fontSize: 10,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentHeading extends StatelessWidget {
  const _PaymentHeading({
    required this.colors,
    required this.text,
    required this.isMobile,
  });

  final dynamic colors;
  final dynamic text;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final kidunaColors = context.kiduna;
    final kidunaText = context.kidunaText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buy compute. Become a Founding Member.',
                style: kidunaText.h2.copyWith(
                  color: kidunaColors.text,
                  fontSize: isMobile ? 24 : 28,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Choose the option that’s right for you.',
                style: kidunaText.caption.copyWith(
                  color: kidunaColors.quiet,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$100',
              style: kidunaText.displayLarge.copyWith(
                color: kidunaColors.gold,
                fontSize: isMobile ? 30 : 34,
                height: 1,
              ),
            ),
            Text(
              '100 USDC',
              style: kidunaText.eyebrow.copyWith(
                color: kidunaColors.gold,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _BadgeType { gold, sky }

class _PurchaseOption extends StatelessWidget {
  const _PurchaseOption({
    required this.label,
    required this.description,
    required this.badgeLabel,
    required this.badgeType,
    required this.actionChild,
  });

  final String label;
  final String description;
  final String badgeLabel;
  final _BadgeType badgeType;
  final Widget actionChild;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    final badgeColor = badgeType == _BadgeType.gold ? colors.gold : colors.sky;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: colors.text.withValues(alpha: 0.11)),
        borderRadius: BorderRadius.circular(10),
        color: colors.text.withValues(alpha: 0.025),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: text.body.copyWith(
                        color: colors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: text.caption.copyWith(
                        color: colors.quiet,
                        fontSize: 12,
                        height: 1.48,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: badgeColor.withValues(alpha: 0.1),
                  border: Border.all(
                    color: badgeColor.withValues(
                      alpha: badgeType == _BadgeType.gold ? 0.22 : 0.3,
                    ),
                  ),
                ),
                child: Text(
                  badgeLabel.toUpperCase(),
                  style: text.eyebrow.copyWith(
                    color: badgeColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          actionChild,
        ],
      ),
    );
  }
}

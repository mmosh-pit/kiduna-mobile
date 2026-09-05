import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import 'kiduna_purchase_panel.dart';

/// Balance summary with a used/available progress bar.
///
/// The denominator is lifetime purchased, so the bar answers "how much of what
/// I have bought have I burned". A consequence worth knowing: buying more
/// KIDUNA drops the percentage, because the denominator grows.
class ComputeUsageBar extends StatelessWidget {
  const ComputeUsageBar({
    super.key,
    required this.balance,
    required this.totalPurchased,
    required this.totalSpent,
    required this.tokenPrice,
  });

  final double balance;
  final double totalPurchased;
  final double totalSpent;
  final double tokenPrice;

  double get _percentUsed {
    if (totalPurchased <= 0) return 0;
    return (totalSpent / totalPurchased * 100).clamp(0, 100);
  }

  String _formatUsd(double value) {
    if (value >= 1000) return '\$${value.toStringAsFixed(0)}';
    if (value >= 1) return '\$${value.toStringAsFixed(2)}';
    return '\$${value.toStringAsFixed(4)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final pct = _percentUsed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.deep.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.camel.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance + USD value
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AVAILABLE',
                    style: text.eyebrowSmall.copyWith(color: colors.quiet),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${KidunaPurchasePanel.formatKiduna(balance)} KIDUNA',
                    style: text.h4.copyWith(color: colors.gold),
                  ),
                ],
              ),
              Text(
                _formatUsd(balance * tokenPrice),
                style: text.body.copyWith(color: colors.muted, fontSize: 14),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Percentage label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Used',
                style: text.caption.copyWith(
                  color: colors.muted,
                  fontSize: 12,
                ),
              ),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: text.body.copyWith(
                  color: colors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8,
              backgroundColor: colors.camel.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(colors.gold),
            ),
          ),

          const SizedBox(height: 12),

          // Breakdown
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Spent',
                  value:
                      '${KidunaPurchasePanel.formatKiduna(totalSpent)} KIDUNA',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Stat(
                  label: 'Purchased',
                  value:
                      '${KidunaPurchasePanel.formatKiduna(totalPurchased)} KIDUNA',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.camel.withValues(alpha: 0.14)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.micro.copyWith(color: colors.quiet)),
          const SizedBox(height: 3),
          Text(value, style: text.label.copyWith(color: colors.cream)),
        ],
      ),
    );
  }
}

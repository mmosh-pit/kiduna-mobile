import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../data/field_fixtures.dart';

/// The Compute panel body: the Source's Compute balance, exchange rates, and a
/// link to Resources. Values are fixtures; Resources routing is added with that
/// Surface.
class ComputeCard extends StatelessWidget {
  const ComputeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.compute.toUpperCase(),
                style: text.eyebrowSmall.copyWith(color: colors.gold),
              ),
              Flexible(
                child: Text(
                  FieldFixtures.computeBalance,
                  textAlign: TextAlign.right,
                  style: text.body.copyWith(color: colors.cream),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(
                child: _Rate(
                  label: FieldFixtures.computeRateLabel,
                  value: FieldFixtures.computeRateValue,
                ),
              ),
              SizedBox(width: 7),
              Expanded(
                child: _Rate(
                  label: FieldFixtures.computeTotalLabel,
                  value: FieldFixtures.computeTotalValue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.openResources,
                style: text.label.copyWith(color: colors.sky),
              ),
              Icon(Icons.north_east, size: 12, color: colors.sky),
            ],
          ),
        ],
      ),
    );
  }
}

class _Rate extends StatelessWidget {
  const _Rate({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Container(
      padding: const EdgeInsets.only(top: 7),
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
          Text(value, style: text.label.copyWith(color: colors.muted)),
        ],
      ),
    );
  }
}

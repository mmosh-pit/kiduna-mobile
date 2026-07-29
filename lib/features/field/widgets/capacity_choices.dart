import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../controllers/field_controller.dart';
import '../data/field_fixtures.dart';

/// The Shape / Design-your-Ally panel body: the five Capacities, each openable,
/// plus an optional Portrait entry for an Ally.
class CapacityChoices extends ConsumerWidget {
  const CapacityChoices({
    super.key,
    required this.target,
    this.showPortrait = false,
  });

  final CapacityTarget target;
  final bool showPortrait;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(fieldControllerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final capacity in FieldFixtures.capacities)
            _CapacityRow(
              capacity: capacity,
              onOpen: () => controller.openCapacity(target, capacity.id),
            ),
          if (showPortrait) ...[
            const SizedBox(height: 12),
            _PortraitEntry(
              onDesign: () => controller.setAllyPortraitOpen(true),
            ),
          ],
        ],
      ),
    );
  }
}

class _CapacityRow extends StatelessWidget {
  const _CapacityRow({required this.capacity, required this.onOpen});

  final Capacity capacity;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            capacity.icon,
            style: TextStyle(color: colors.sky, fontSize: 15, height: 1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capacity.label,
                  style: text.bodySmall.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  capacity.detail,
                  style: text.micro.copyWith(color: colors.quiet),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onOpen,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 30),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              foregroundColor: colors.skyButtonInk,
              backgroundColor: colors.sky,
              side: BorderSide.none,
            ),
            child: Text(
              context.l10n.open,
              style: text.label.copyWith(
                color: colors.skyButtonInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortraitEntry extends StatelessWidget {
  const _PortraitEntry({required this.onDesign});

  final VoidCallback onDesign;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colors.camel.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(context.metrics.radiusMd),
      ),
      child: Row(
        children: [
          Text(
            '✺',
            style: TextStyle(color: colors.sky, fontSize: 22, height: 1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.design,
              style: context.kidunaText.bodySmall.copyWith(color: colors.cream),
            ),
          ),
          OutlinedButton(onPressed: onDesign, child: Text(context.l10n.design)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/capacity_target.dart';
import '../../../core/extensions/context_extensions.dart';
import '../controllers/field_controller.dart';
import '../data/field_fixtures.dart';

/// The Shape / Design-your-Ally panel body: the five Capacities, each openable,
/// plus an optional Portrait entry for an Ally.
class CapacityChoices extends ConsumerWidget {
  const CapacityChoices({
    super.key,
    required this.target,
    this.realmName,
    this.showPortrait = false,
  });

  final CapacityTarget target;
  final String? realmName;
  final bool showPortrait;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(fieldControllerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (realmName != null) ...[
            Text(
              context.l10n.whatRealmKnowsAndCanDo(realmName!),
              style: context.kidunaText.heading.copyWith(
                color: context.kiduna.cream,
              ),
            ),
            const SizedBox(height: 12),
          ],
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
    return Container(
      constraints: const BoxConstraints(minHeight: 61),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.camel.withValues(alpha: 0.13)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.sky.withValues(alpha: 0.05),
              border: Border.all(color: colors.sky.withValues(alpha: 0.38)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              capacity.icon,
              style: text.bodyBase.copyWith(color: colors.sky, height: 1),
            ),
          ),
          const SizedBox(width: 10),
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
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: onOpen,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 30),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              foregroundColor: colors.skyButtonInk,
              backgroundColor: colors.sky,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: Text(
              context.l10n.open,
              style: text.label.copyWith(
                color: colors.skyButtonInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: context.l10n.askKi,
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.sky.withValues(alpha: 0.05),
                border: Border.all(color: colors.sky.withValues(alpha: 0.28)),
              ),
              child: Text(
                '→',
                style: text.label.copyWith(color: colors.sky, height: 1),
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
            style: context.kidunaText.h4.copyWith(color: colors.sky, height: 1),
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

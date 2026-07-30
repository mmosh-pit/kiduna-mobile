import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/field_realm.dart';
import '../controllers/field_controller.dart';
import '../data/field_fixtures.dart';

/// The Inspect panel body: the Realm's identity and a list of facts. Selecting a
/// fact asks Ki to explain it.
class InspectPanel extends ConsumerWidget {
  const InspectPanel({super.key, required this.realm});

  final FieldRealm realm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final controller = ref.read(fieldControllerProvider.notifier);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 13),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colors.camel.withValues(alpha: 0.14)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                realm.type.toUpperCase(),
                style: text.eyebrowSmall.copyWith(color: colors.gold),
              ),
              const SizedBox(height: 4),
              Text(
                realm.name,
                style: text.heading.copyWith(color: colors.cream),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Text(
            context.l10n.selectAnyFactToExploreItWithKi,
            style: text.bodySmall.copyWith(color: colors.quiet),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 540),
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final fact in FieldFixtures.facts)
                  _FactRow(
                    fact: fact,
                    onTap: () {
                      controller.askAbout(fact.topic);
                      if (fact.label == 'Capacities') {
                        controller.openActionById('shape');
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.fact, required this.onTap});

  final FieldFact fact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 51),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colors.camel.withValues(alpha: 0.1)),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 102,
              child: Text(
                fact.label.toUpperCase(),
                style: text.eyebrowSmall.copyWith(
                  color: colors.quiet,
                  letterSpacing: 0.7,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fact.value,
                style: text.bodySmall.copyWith(color: colors.text),
              ),
            ),
            const SizedBox(width: 8),
            Text('→', style: text.bodySmall.copyWith(color: colors.sky)),
          ],
        ),
      ),
    );
  }
}

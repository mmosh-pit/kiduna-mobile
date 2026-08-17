import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/realm_model.dart';
import '../../../data/models/field_realm.dart';
import '../../../data/models/ki_topic.dart';
import '../controllers/ecosystem_controller.dart';
import '../controllers/field_controller.dart';
import '../data/field_fixtures.dart';

/// The Inspect panel body: the Realm's identity and a list of facts. Selecting a
/// fact asks Ki to explain it.
///
/// Facts are built dynamically from the genesis duna API response. When the API
/// hasn't loaded yet (or the duna has no data for a field), the static fixture
/// values from [FieldFixtures.facts] are used as fallback.
class InspectPanel extends ConsumerWidget {
  const InspectPanel({super.key, required this.realm});

  final FieldRealm realm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final controller = ref.read(fieldControllerProvider.notifier);
    final ecosystem = ref.watch(ecosystemControllerProvider);
    final genesis = ecosystem.genesis;

    // Build dynamic facts from the API response, falling back to fixture values.
    final facts = _buildFacts(genesis);

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
                for (final fact in facts)
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

/// Build the facts list from the API genesis duna.
///
/// When genesis is null (no ecosystem created yet), all values show "–"
/// instead of falling back to static fixture data.
List<FieldFact> _buildFacts(RealmModel? genesis) {
  // Index the static fixtures by label for Ki topic lookup only.
  final fixtureMap = {for (final f in FieldFixtures.facts) f.label: f};

  String val(String? apiValue) {
    if (apiValue != null && apiValue.isNotEmpty) return apiValue;
    return '–';
  }

  KiTopic topic(String label) =>
      fixtureMap[label]?.topic ?? const KiTopic(body: '');

  return [
    (
      label: 'Ecosystem ID',
      value: val(genesis?.ecosystemId),
      topic: topic('Ecosystem ID'),
    ),
    (
      label: 'Registration',
      value: val(genesis?.registration),
      topic: topic('Registration'),
    ),
    (label: 'Purpose', value: val(genesis?.purpose), topic: topic('Purpose')),
    (
      label: 'Capacities',
      value: val(genesis?.capacities),
      topic: topic('Capacities'),
    ),
    (
      label: 'Organizations',
      value: genesis != null ? '${genesis.members.length}' : '0',
      topic: topic('Organizations'),
    ),
    (label: 'Members', value: genesis != null ? '${genesis.members.length}' : '0', topic: topic('Members')),
    (
      label: 'Treasury',
      value: genesis != null
          ? (fixtureMap['Treasury']?.value ?? '0 KIDUNA')
          : '0 KIDUNA',
      topic: topic('Treasury'),
    ),
  ];
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

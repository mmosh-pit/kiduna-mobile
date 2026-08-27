import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/realm_model.dart';
import '../../../data/models/field_realm.dart';
import '../../../data/models/ki_topic.dart';
import '../controllers/ecosystem_controller.dart';
import '../controllers/field_controller.dart';
import '../data/field_fixtures.dart';

/// Labels whose values should show a copy button.
const _copyableLabels = {
  'Realm ID', 'Wallet', 'Vault', 'Catalyst',
};

class InspectPanel extends ConsumerWidget {
  const InspectPanel({super.key, required this.realm});

  final FieldRealm realm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final controller = ref.read(fieldControllerProvider.notifier);
    final fieldState = ref.watch(fieldControllerProvider);
    final ecoState = ref.watch(ecosystemControllerProvider);

    final currentId = fieldState.currentRealmId;
    RealmModel? currentRealm;
    if (currentId != 'kinship-duna') {
      currentRealm = ecoState.all.cast<RealmModel?>().firstWhere(
        (r) => r?.id == currentId,
        orElse: () => null,
      );
    }
    currentRealm ??= ecoState.genesis;

    final facts = _buildFacts(currentRealm, ecoState);

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
              if (currentRealm?.description != null &&
                  currentRealm!.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  currentRealm.description!,
                  style: text.bodySmall.copyWith(
                    color: colors.quiet,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
                    copyable: _copyableLabels.contains(fact.label),
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

String _truncate(String s) {
  if (s.length <= 14) return s;
  return '${s.substring(0, 6)}...${s.substring(s.length - 4)}';
}

List<FieldFact> _buildFacts(RealmModel? realm, EcosystemState ecoState) {
  final fixtureMap = {for (final f in FieldFixtures.facts) f.label: f};

  String val(String? v) => (v != null && v.isNotEmpty) ? v : '–';

  KiTopic topic(String label) =>
      fixtureMap[label]?.topic ?? const KiTopic(body: '');

  KiTopic rt(String label, String body) => KiTopic(title: label, body: body);

  if (realm == null) {
    return [(label: 'Status', value: '–', topic: topic('Status'))];
  }

  final type = realm.type;
  final config = realm.config;
  final economics = config['economics'] as Map<String, dynamic>? ?? {};

  // ── Common ──
  final common = <FieldFact>[
    (label: 'Realm ID', value: realm.id, topic: rt('Realm ID', 'Unique identifier: ${realm.id}')),
    (label: 'Handle', value: '@${realm.handle}', topic: rt('Handle', '@${realm.handle}')),
    (label: 'Purpose', value: val(realm.purpose), topic: topic('Purpose')),
    (label: 'Status', value: realm.status.toUpperCase(), topic: rt('Status', 'Currently ${realm.status}.')),
    (label: 'Visibility', value: realm.visibility.toUpperCase(), topic: rt('Visibility', '${realm.visibility} realm.')),
    (label: 'Members', value: '${realm.members.length}', topic: topic('Members')),
  ];

  // ── Type-specific ──
  final specific = <FieldFact>[];

  switch (type) {
    case 'ecosystem':
      final registration = config['registration'] as String?;
      final orgCount = ecoState.organizations.length;
      final ecoP = economics['ecosystemSharePct'];
      final orgP = economics['organizationSharePct'];
      final progP = economics['programSharePct'];

      specific.addAll([
        if (registration != null && registration.isNotEmpty)
          (label: 'Registration', value: registration, topic: topic('Registration')),
        (label: 'Organizations', value: '$orgCount', topic: topic('Organizations')),
        if (ecoP != null || orgP != null || progP != null)
          (
            label: 'Distribution',
            value: 'Eco ${ecoP ?? 0}% · Org ${orgP ?? 0}% · Prog ${progP ?? 0}%',
            topic: rt('Distribution', 'Compute rewards: Ecosystem $ecoP%, Organization $orgP%, Program $progP%.'),
          ),
      ]);

    case 'organization':
      final registration = config['registration'] as String?;
      final ecosystemId = config['ecosystemId'] as String?;
      final catalystWallet = economics['catalystWallet'] as String?;
      final orgPct = economics['organizerOngoingPct'];
      final compPct = economics['compensationPoolPct'];
      final agencyPct = economics['agencyPoolPct'];

      specific.addAll([
        if (registration != null && registration.isNotEmpty)
          (label: 'Registration', value: registration, topic: rt('Registration', 'Registered as: $registration')),
        if (ecosystemId != null && ecosystemId.isNotEmpty)
          (label: 'Ecosystem ID', value: ecosystemId, topic: rt('Ecosystem ID', 'Reference: $ecosystemId')),
        if (catalystWallet != null && catalystWallet.isNotEmpty)
          (label: 'Catalyst', value: catalystWallet, topic: rt('Catalyst', 'Catalyst wallet for this organization.')),
        if (orgPct != null)
          (label: 'Organizer %', value: '$orgPct% ongoing', topic: rt('Organizer', 'Organizers earn $orgPct% ongoing.')),
        if (compPct != null && agencyPct != null)
          (label: 'Economics', value: 'Comp ${compPct}% · Agency ${agencyPct}%', topic: rt('Economics', 'Compensation $compPct%, Agency $agencyPct%.')),
      ]);

    case 'alliance':
      final spendingRule = config['spendingRule'] as String?;
      final defaultTools = config['defaultTools'] as String?;
      specific.addAll([
        if (spendingRule != null && spendingRule.isNotEmpty)
          (label: 'Spending Rule', value: spendingRule, topic: rt('Spending Rule', spendingRule)),
        if (defaultTools != null && defaultTools.isNotEmpty)
          (label: 'Default Tools', value: defaultTools, topic: rt('Default Tools', defaultTools)),
      ]);

    case 'institution':
      final entityType = config['entityType'] as String?;
      final regDomain = config['registrationDomain'] as String?;
      final standingDoc = config['standingDocUrl'] as String?;
      specific.addAll([
        if (entityType != null && entityType.isNotEmpty)
          (label: 'Entity Type', value: entityType.toUpperCase(), topic: rt('Entity Type', 'A $entityType.')),
        if (regDomain != null && regDomain.isNotEmpty)
          (label: 'Domain', value: regDomain, topic: rt('Domain', regDomain)),
        if (standingDoc != null && standingDoc.isNotEmpty)
          (label: 'Standing Doc', value: 'View →', topic: rt('Standing Document', standingDoc)),
      ]);

    default:
      break;
  }

  // ── Theme ──
  final theme = <FieldFact>[];
  if (realm.primaryTheme != null && realm.primaryTheme!.isNotEmpty)
    theme.add((label: 'Theme', value: realm.primaryTheme!, topic: rt('Theme', realm.primaryTheme!)));
  if (realm.primaryFocus != null && realm.primaryFocus!.isNotEmpty)
    theme.add((label: 'Focus', value: realm.primaryFocus!, topic: rt('Focus', realm.primaryFocus!)));

  // ── Wallet ──
  final wallet = <FieldFact>[];
  if (realm.multisigPda != null && realm.multisigPda!.isNotEmpty)
    wallet.add((label: 'Wallet', value: realm.multisigPda!, topic: rt('Wallet', 'Squads multisig: ${realm.multisigPda}')));
  if (realm.vaultPda != null && realm.vaultPda!.isNotEmpty)
    wallet.add((label: 'Vault', value: realm.vaultPda!, topic: rt('Vault', 'Treasury vault: ${realm.vaultPda}')));

  return [...common, ...specific, ...theme, ...wallet];
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.fact,
    required this.onTap,
    this.copyable = false,
  });

  final FieldFact fact;
  final VoidCallback onTap;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    // For copyable rows, truncate long values (wallets, IDs)
    final displayValue = copyable && fact.value.length > 14
        ? _truncate(fact.value)
        : fact.value;

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
                displayValue,
                style: text.bodySmall.copyWith(
                  color: colors.text,
                  fontFamily: copyable ? 'monospace' : null,
                ),
              ),
            ),
            if (copyable) ...[
              const SizedBox(width: 4),
              _CopyButton(value: fact.value),
            ],
          ],
        ),
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.value});
  final String value;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return GestureDetector(
      onTap: _copy,
      child: Icon(
        _copied ? Icons.check : Icons.copy,
        size: 15,
        color: _copied ? colors.mint : colors.sky,
      ),
    );
  }
}

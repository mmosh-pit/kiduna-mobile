import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/ki_topic.dart';
import '../controllers/field_controller.dart';
import '../data/design_persona.dart';
import '../data/field_composition.dart';
import '../data/realm_atlas.dart';

String _gravityName(BuildContext context, int level) {
  final l10n = context.l10n;
  switch (level) {
    case 1:
      return l10n.gravityQuiet;
    case 2:
      return l10n.gravityAvailable;
    case 3:
      return l10n.gravityRelevant;
    case 4:
      return l10n.gravityCentral;
    case 5:
      return l10n.gravityVital;
    default:
      return l10n.gravityRelevant;
  }
}

String _gravityMeaning(BuildContext context, int level) {
  final l10n = context.l10n;
  switch (level) {
    case 1:
      return l10n.gravityQuietMeaning;
    case 2:
      return l10n.gravityAvailableMeaning;
    case 3:
      return l10n.gravityRelevantMeaning;
    case 4:
      return l10n.gravityCentralMeaning;
    case 5:
      return l10n.gravityVitalMeaning;
    default:
      return l10n.gravityRelevantMeaning;
  }
}

class AdvancedActionsPanel extends ConsumerWidget {
  const AdvancedActionsPanel({
    super.key,
    required this.placement,
    this.isCurrent = false,
    this.onEnter,
  });

  final FieldPlacement placement;
  final bool isCurrent;

  /// Called when the user taps "Enter [realm]". The host screen provides
  /// navigation logic (GoRouter push).
  final ValueChanged<AtlasRealm>? onEnter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(fieldControllerProvider.notifier);
    final gravity = ref.watch(
      fieldControllerProvider.select(
        (s) => s.realmGravity[placement.realm.id] ?? 3,
      ),
    );
    final realm = placement.realm;
    final nestedCount = visibleChildren(realm.id, DesignPersona.alice).length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(realm: realm, isCurrent: isCurrent),
          _FactGrid(realm: realm, nestedCount: nestedCount),
          _GravityControl(
            realmName: realm.name,
            gravity: gravity,
            onChanged: (level) => controller.setGravity(realm.id, level),
          ),
          if (placement.reason.isNotEmpty)
            _WhyButton(realm: realm, placement: placement, gravity: gravity),
          if (!isCurrent && onEnter != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: _EnterButton(
                label: l10n.enterRealmName(realm.name),
                onTap: () => onEnter!(realm),
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.realm, required this.isCurrent});

  final AtlasRealm realm;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = context.l10n;
    final label = isCurrent ? l10n.currentRealmLabel : l10n.selectedInTheField;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.camel.withValues(alpha: 0.14)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${label.toUpperCase()} · ${realm.type.label.toUpperCase()}',
            style: text.eyebrowSmall.copyWith(
              color: colors.sky,
              letterSpacing: 1.36,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            realm.name,
            style: text.display.copyWith(
              color: colors.cream,
              fontSize: 24,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            realm.purpose,
            style: text.bodySmall.copyWith(color: colors.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _FactGrid extends StatelessWidget {
  const _FactGrid({required this.realm, required this.nestedCount});

  final AtlasRealm realm;
  final int nestedCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final l10n = context.l10n;
    final border = BorderSide(color: colors.camel.withValues(alpha: 0.1));

    return Wrap(
      children: [
        _FactCell(label: l10n.yourRole, value: 'Catalyst', border: border),
        _FactCell(
          label: l10n.stationedAlly,
          value: l10n.noneStationed,
          border: border,
        ),
        _FactCell(
          label: l10n.nestedRealms,
          value: '$nestedCount',
          border: border,
        ),
        if (realm.fixture)
          _FactCell(
            label: l10n.legalStatus,
            value: l10n.designFixtureNotYetVerified,
            border: border,
          ),
      ],
    );
  }
}

class _FactCell extends StatelessWidget {
  const _FactCell({
    required this.label,
    required this.value,
    required this.border,
  });

  final String label;
  final String value;
  final BorderSide border;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        border: Border(right: border, bottom: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 8,
              color: colors.quiet,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 9,
              color: colors.cream,
            ),
          ),
        ],
      ),
    );
  }
}

class _GravityControl extends StatelessWidget {
  const _GravityControl({
    required this.realmName,
    required this.gravity,
    required this.onChanged,
  });

  final String realmName;
  final int gravity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final l10n = context.l10n;
    final name = _gravityName(context, gravity);
    final meaning = _gravityMeaning(context, gravity);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.camel.withValues(alpha: 0.12)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.gravityLabel.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.04,
                  color: colors.sky,
                ),
              ),
              Text(
                '$gravity · $name',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 10,
                  color: colors.cream,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colors.sky,
              inactiveTrackColor: colors.sky.withValues(alpha: 0.15),
              thumbColor: colors.sky,
              overlayColor: colors.sky.withValues(alpha: 0.12),
              trackHeight: 3,
            ),
            child: Slider(
              value: gravity.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              semanticFormatterCallback: (v) => l10n.gravityOfRealm(
                realmName,
                _gravityName(context, v.round()),
              ),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          Text(
            meaning,
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 9,
              color: colors.quiet,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final level = i + 1;
              final selected = level == gravity;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i > 0 ? 5 : 0),
                  child: _GravityButton(
                    level: level,
                    name: _gravityName(context, level),
                    selected: selected,
                    onTap: () => onChanged(level),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _GravityButton extends StatelessWidget {
  const _GravityButton({
    required this.level,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final int level;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        decoration: BoxDecoration(
          color: selected
              ? colors.sky.withValues(alpha: 0.07)
              : const Color(0x05FFF6D5),
          border: Border.all(
            color: selected
                ? colors.sky.withValues(alpha: 0.35)
                : colors.camel.withValues(alpha: 0.12),
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$level',
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: colors.sky,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: 7,
                color: colors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhyButton extends ConsumerWidget {
  const _WhyButton({
    required this.realm,
    required this.placement,
    required this.gravity,
  });

  final AtlasRealm realm;
  final FieldPlacement placement;
  final int gravity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.kiduna;
    final l10n = context.l10n;
    final controller = ref.read(fieldControllerProvider.notifier);
    final name = _gravityName(context, gravity);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 0),
      child: Material(
        color: colors.sky.withValues(alpha: 0.045),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: colors.sky.withValues(alpha: 0.22)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => controller.askAbout(
            KiTopic(
              title: l10n.whyRealmIsHere(realm.name),
              body: placement.reason,
              invitation: l10n.gravityIsContextual(gravity, name),
            ),
          ),
          child: Container(
            constraints: const BoxConstraints(minHeight: 38),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.whyIsThisHere,
                  style: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 10,
                    color: colors.sky,
                  ),
                ),
                Text('→', style: TextStyle(color: colors.sky)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnterButton extends StatelessWidget {
  const _EnterButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Material(
      color: colors.sky,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.skyButtonInk,
                ),
              ),
              Text('→', style: TextStyle(color: colors.skyButtonInk)),
            ],
          ),
        ),
      ),
    );
  }
}

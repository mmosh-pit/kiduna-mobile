import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/sentinel_rules_model.dart';

const _gold = Color(0xFFC8A24B);

class SentinelRulesSection extends StatelessWidget {
  const SentinelRulesSection({
    super.key,
    required this.rules,
    required this.canEdit,
    required this.onEdit,
  });

  final SentinelRules rules;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          colors: colors,
          canEdit: canEdit,
          onEdit: onEdit,
        ),
        const SizedBox(height: 8),
        if (rules.isEmpty)
          _EmptyState(colors: colors, canEdit: canEdit, onEdit: onEdit)
        else
          _RulesDisplay(colors: colors, rules: rules),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.colors,
    required this.canEdit,
    required this.onEdit,
  });
  final dynamic colors;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'SENTINEL RULES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colors.quiet as Color,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        if (canEdit)
          GestureDetector(
            onTap: onEdit,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_outlined, size: 13, color: colors.sky as Color),
                const SizedBox(width: 4),
                Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.sky as Color,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.colors,
    required this.canEdit,
    required this.onEdit,
  });
  final dynamic colors;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface as Color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (colors.camel as Color).withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.shield_outlined,
            size: 28,
            color: (colors.muted as Color).withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'No custom rules defined',
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: colors.muted as Color,
            ),
          ),
          if (canEdit) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 32,
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.add, size: 14),
                label: const Text(
                  'Add Rules',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _gold,
                  side: BorderSide(color: _gold.withValues(alpha: 0.50)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RulesDisplay extends StatelessWidget {
  const _RulesDisplay({required this.colors, required this.rules});
  final dynamic colors;
  final SentinelRules rules;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _gold.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rules.description != null) ...[
            Text(
              rules.description!,
              style: TextStyle(
                fontSize: 13,
                color: colors.cream as Color,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (rules.principles.isNotEmpty) ...[
            _SubLabel(label: 'Principles', colors: colors),
            const SizedBox(height: 4),
            for (final p in rules.principles) ...[
              _PrincipleRow(text: p, colors: colors),
              const SizedBox(height: 4),
            ],
            const SizedBox(height: 8),
          ],
          if (_hasConstraints) ...[
            _SubLabel(label: 'Constraints', colors: colors),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _constraintChips,
            ),
            const SizedBox(height: 8),
          ],
          if (_hasGuardrails) ...[
            _SubLabel(label: 'Guardrails', colors: colors),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _guardrailChips,
            ),
          ],
        ],
      ),
    );
  }

  bool get _hasConstraints =>
      rules.startingStack != null ||
      rules.maxBetAmount != null ||
      rules.minBetAmount != null ||
      rules.maxRaisesPerRound != null ||
      rules.turnTimeoutSeconds != null ||
      rules.maxPlayersPerTable != null ||
      rules.maxHoleCards != null ||
      rules.compChipsPerPlayer != null ||
      rules.powerDeckSize != null ||
      rules.levelDurationSeconds != null;

  bool get _hasGuardrails =>
      rules.bannedPowerCards.isNotEmpty ||
      rules.bannedCourtMembers.isNotEmpty ||
      rules.enablePowerCards != null ||
      rules.enableItems != null ||
      rules.enableJokers != null ||
      rules.enableSuddenDeath != null ||
      rules.timedLevels != null;

  List<Widget> get _constraintChips {
    final chips = <Widget>[];
    if (rules.startingStack != null) {
      chips.add(_Chip(label: 'Stack: ${rules.startingStack}'));
    }
    if (rules.maxBetAmount != null) {
      chips.add(_Chip(label: 'Max Bet: ${rules.maxBetAmount}'));
    }
    if (rules.minBetAmount != null) {
      chips.add(_Chip(label: 'Min Bet: ${rules.minBetAmount}'));
    }
    if (rules.maxRaisesPerRound != null) {
      chips.add(_Chip(label: 'Max Raises: ${rules.maxRaisesPerRound}'));
    }
    if (rules.turnTimeoutSeconds != null) {
      chips.add(_Chip(label: 'Turn: ${rules.turnTimeoutSeconds}s'));
    }
    if (rules.maxPlayersPerTable != null) {
      chips.add(_Chip(label: 'Players: ${rules.maxPlayersPerTable}'));
    }
    if (rules.maxHoleCards != null) {
      chips.add(_Chip(label: 'Hole Cards: ${rules.maxHoleCards}'));
    }
    if (rules.compChipsPerPlayer != null) {
      chips.add(_Chip(label: 'Comp Chips: ${rules.compChipsPerPlayer}'));
    }
    if (rules.powerDeckSize != null) {
      chips.add(_Chip(label: 'Power Deck: ${rules.powerDeckSize}'));
    }
    if (rules.levelDurationSeconds != null) {
      chips.add(_Chip(label: 'Level: ${rules.levelDurationSeconds}s'));
    }
    return chips;
  }

  List<Widget> get _guardrailChips {
    final chips = <Widget>[];
    if (rules.enablePowerCards == false) {
      chips.add(const _Chip(label: 'No Power Cards', isBan: true));
    }
    if (rules.enableItems == false) {
      chips.add(const _Chip(label: 'No Items', isBan: true));
    }
    if (rules.enableJokers == false) {
      chips.add(const _Chip(label: 'No Jokers', isBan: true));
    }
    if (rules.enableSuddenDeath == true) {
      chips.add(const _Chip(label: 'Sudden Death'));
    }
    if (rules.timedLevels == true) {
      chips.add(const _Chip(label: 'Timed Levels'));
    }
    for (final card in rules.bannedPowerCards) {
      chips.add(_Chip(label: 'Ban: $card', isBan: true));
    }
    for (final member in rules.bannedCourtMembers) {
      chips.add(_Chip(label: 'Ban: $member', isBan: true));
    }
    return chips;
  }
}

class _SubLabel extends StatelessWidget {
  const _SubLabel({required this.label, required this.colors});
  final String label;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _gold.withValues(alpha: 0.8),
        letterSpacing: 0.3,
      ),
    );
  }
}

class _PrincipleRow extends StatelessWidget {
  const _PrincipleRow({required this.text, required this.colors});
  final String text;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Icon(
            Icons.shield_outlined,
            size: 12,
            color: _gold.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: colors.cream as Color,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.isBan = false});
  final String label;
  final bool isBan;

  @override
  Widget build(BuildContext context) {
    final bgColor = isBan
        ? const Color(0xFF6B2A2A).withValues(alpha: 0.3)
        : _gold.withValues(alpha: 0.12);
    final textColor = isBan ? const Color(0xFFE57373) : _gold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

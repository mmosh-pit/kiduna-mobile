/// The Field state control.
///
/// Four states, four motion verbs. This exists so the states can be *judged by
/// looking* rather than read about — in the product they follow context, not a
/// switch.
///
/// It is deliberately a presentation control and says so on its face. The
/// canon draws a hard line here: expressive state is never evidence of legal
/// intent or authorization, and no state may be inferred from a camera, a
/// face, demographics, or private activity. A visible switch the member owns
/// is the honest form of that rule.
library;

import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../design/typography.dart';
import '../field/models.dart';

/// The verb each state selects, quoted from the motion canon.
const stateVerbs = <AllyState, (String, String)>{
  AllyState.open: ('Breathe', 'A Realm at rest remains available'),
  AllyState.engaged: ('Relate', 'Existing paths brighten'),
  AllyState.focused: ('Gather', 'Everything settles again, 900ms'),
  AllyState.dreaming: ('Drift', 'Possibility wanders, ±8px'),
};

class FieldStateBar extends StatelessWidget {
  const FieldStateBar({
    required this.current,
    required this.onSelect,
    super.key,
  });

  final AllyState current;
  final ValueChanged<AllyState> onSelect;

  @override
  Widget build(BuildContext context) {
    final verb = stateVerbs[current]!;

    return Positioned(
      left: 24,
      top: 24,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
        decoration: BoxDecoration(
          color: Enamel.warmSurface.withValues(alpha: 0.94),
          border: Border.all(color: Enamel.raisedUmber),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('FIELD STATE', style: Type.eyebrow),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final state in AllyState.values) ...[
                  if (state != AllyState.values.first)
                    const SizedBox(width: 6),
                  _StateButton(
                    state: state,
                    selected: state == current,
                    onTap: () => onSelect(state),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 9),
            // The verb is named, because the state is only meaningful as the
            // motion it selects.
            Row(
              children: [
                Text(
                  verb.$1.toUpperCase(),
                  style: Type.eyebrow.copyWith(color: Enamel.sunGold),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 210),
                  child: Text(verb.$2, style: Type.bodyQuiet),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StateButton extends StatelessWidget {
  const _StateButton({
    required this.state,
    required this.selected,
    required this.onTap,
  });

  final AllyState state;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: '${state.label}. ${state.meaning}.',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: selected
                  ? Enamel.skyBlue.withValues(alpha: 0.16)
                  : const Color(0x00000000),
              border: Border.all(
                color: Enamel.skyBlue.withValues(alpha: selected ? 0.9 : 0.34),
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              state.label,
              style: Type.control.copyWith(
                color: selected
                    ? Enamel.cream
                    : Enamel.skyBlue.withValues(alpha: 0.75),
              ),
            ),
          ),
        ),
      );
}

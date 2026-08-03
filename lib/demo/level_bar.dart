/// Which window of the Field you are in, and how to reach the others.
///
/// A prototype control for the twenty-cluster question, and outside the
/// contract. It exists because traverse deliberately makes most of the Field
/// unreachable by panning: with the map gone and the stars unlabelled, a member
/// needs somewhere plain to see how many windows there are and which one they
/// occupy.
///
/// Numbered rather than named on purpose. A window is a slice of an ordering,
/// not a place with an identity — naming it would invent a container the
/// taxonomy does not have.
library;

import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../design/typography.dart';

class LevelBar extends StatelessWidget {
  const LevelBar({
    required this.count,
    required this.current,
    required this.onSelect,
    super.key,
  });

  final int count;
  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();

    return Positioned(
      left: 24,
      bottom: 24,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Enamel.warmSurface.withValues(alpha: 0.94),
          border: Border.all(color: Enamel.raisedUmber),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('LEVEL', style: Type.eyebrow),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < count; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  _LevelButton(
                    label: '${i + 1}',
                    selected: i == current,
                    onTap: () => onSelect(i),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelButton extends StatelessWidget {
  const _LevelButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Enamel.skyBlue;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Level $label',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(3),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.16)
                : const Color(0x00000000),
            border: Border.all(
              color: accent.withValues(alpha: selected ? 0.9 : 0.34),
            ),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            label,
            style: Type.heading.copyWith(
              fontSize: 14,
              color: selected ? Enamel.cream : accent.withValues(alpha: 0.72),
            ),
          ),
        ),
      ),
    );
  }
}

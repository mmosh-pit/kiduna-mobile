import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../controllers/field_controller.dart';
import '../data/field_fixtures.dart';

/// The Possible Actions panel body: a 2×2 grid of the Actions available now.
/// Selecting one asks Ki about it (opening its working panel arrives in a later
/// phase).
class PossibleActions extends ConsumerWidget {
  const PossibleActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const actions = FieldFixtures.actions;
    final controller = ref.read(fieldControllerProvider.notifier);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(19, 18, 19, 15),
          child: Text(
            context.l10n.aFewActionsYouCanTakeNow,
            style: context.kidunaText.headingLarge.copyWith(
              color: context.kiduna.cream,
            ),
          ),
        ),
        for (var row = 0; row < actions.length; row += 2)
          Row(
            children: [
              for (var column = row; column < row + 2; column++)
                Expanded(
                  child: _ActionButton(
                    action: actions[column],
                    onTap: () => controller.chooseAction(actions[column]),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.onTap});

  final FieldAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: colors.camel.withValues(alpha: 0.1)),
            bottom: BorderSide(color: colors.camel.withValues(alpha: 0.1)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.sky.withValues(alpha: 0.12),
                    colors.raised.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(
                  context.metrics.radiusPanel,
                ),
                border: Border.all(color: colors.sky.withValues(alpha: 0.52)),
              ),
              child: Text(
                action.icon,
                style: TextStyle(color: colors.sky, fontSize: 17, height: 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                action.label,
                style: text.body.copyWith(color: colors.text),
              ),
            ),
            const SizedBox(width: 8),
            Text('→', style: text.body.copyWith(color: colors.sky)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../controllers/field_controller.dart';
import '../data/field_fixtures.dart';
import '../data/field_models.dart';

/// The Possible Actions panel body: a grid of the Actions available to the
/// user based on their role in the current Realm.
/// Selecting one opens its working panel and asks Ki about it.
class PossibleActions extends ConsumerWidget {
  const PossibleActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldState = ref.watch(fieldControllerProvider);
    final currentRealmId = fieldState.currentRealmId;

    // Determine the user's role in the current realm.
    // If no realm selected or user is the ecosystem creator → catalyst.
    final role = currentRealmId != null
        ? fieldState.viewerRoleIn(currentRealmId)
        : Role.catalyst;

    // Filter actions based on role permissions.
    final actions = FieldFixtures.actions
        .where((a) => a.canAccess(role))
        .toList();

    if (actions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No actions available for your current role.',
          style: context.kidunaText.body.copyWith(
            color: context.kiduna.muted,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final controller = ref.read(fieldControllerProvider.notifier);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(19, 18, 19, 15),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.kiduna.camel.withValues(alpha: 0.14),
              ),
            ),
          ),
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
              for (var column = row;
                  column < row + 2 && column < actions.length;
                  column++)
                Expanded(
                  child: _ActionButton(
                    action: actions[column],
                    onTap: () {
                      if (actions[column].id == 'alliance') {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const DashboardScreen(initialTab: 3),
                          ),
                        );
                      } else {
                        controller.chooseAction(actions[column]);
                      }
                    },
                    // Only internal dividers: right border on the left column,
                    // bottom border on the top row.
                    rightBorder: column.isEven && column + 1 < actions.length,
                    bottomBorder: column < 2 && row + 2 < actions.length,
                  ),
                ),
              // Fill empty cell when odd count lands on last row.
              if (row + 1 >= actions.length)
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.onTap,
    required this.rightBorder,
    required this.bottomBorder,
  });

  final FieldAction action;
  final VoidCallback onTap;
  final bool rightBorder;
  final bool bottomBorder;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final line = colors.camel.withValues(alpha: 0.1);
    return Semantics(
      button: true,
      label: action.label,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              right: rightBorder ? BorderSide(color: line) : BorderSide.none,
              bottom: bottomBorder ? BorderSide(color: line) : BorderSide.none,
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
                  boxShadow: [
                    BoxShadow(
                      color: colors.sky.withValues(alpha: 0.1),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Text(
                  action.icon,
                  style: text.bodyLg.copyWith(
                    color: colors.sky,
                    height: 1,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  action.label,
                  style: text.body.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('→', style: text.caption.copyWith(color: colors.sky)),
            ],
          ),
        ),
      ),
    );
  }
}
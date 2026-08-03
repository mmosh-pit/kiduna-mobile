/// The Possible Actions panel.
///
/// Floating Studio chrome, not a Field object: it never pans, never scales
/// with the camera, and never becomes something a connector can attach to.
///
/// It shows **offers**, and offers only. Nothing here executes: every Action in
/// this product is a deterministic operation behind the command boundary, and a
/// panel that appeared to perform one would be lying about where authority
/// lives. Tapping reports the intent and stops.
library;

import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../design/typography.dart';
import '../field/models.dart';
import '../field/possible_actions.dart';

class PossibleActionsPanel extends StatelessWidget {
  const PossibleActionsPanel({
    required this.realmName,
    required this.realmType,
    required this.role,
    required this.onAction,
    this.onClose,
    super.key,
  });

  /// The Realm the offers belong to. Always named, because an Action with no
  /// stated subject is the kind of ambiguity that gets something signed by
  /// accident.
  final String realmName;
  final String realmType;

  /// The role the viewer holds **in this Realm**, which is what gates the list.
  final Role? role;

  final ValueChanged<PossibleAction> onAction;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final actions = actionsFor(role);
    final grouped = <ActionGroup, List<PossibleAction>>{};
    for (final action in actions) {
      grouped.putIfAbsent(action.group, () => []).add(action);
    }

    return Positioned(
      right: 24,
      top: 24,
      width: 320,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 560),
        decoration: BoxDecoration(
          color: Enamel.warmSurface.withValues(alpha: 0.96),
          border: Border.all(color: Enamel.raisedUmber),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              realmName: realmName,
              realmType: realmType,
              role: role,
              onClose: onClose,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final entry in grouped.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 12, 0, 7),
                        child: Text(
                          entry.key.label.toUpperCase(),
                          style: Type.eyebrow,
                        ),
                      ),
                      for (final action in entry.value)
                        _ActionRow(action: action, onTap: () => onAction(action)),
                    ],
                    if (actions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'Nothing is offered here at this role.',
                          style: Type.bodyQuiet,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.realmName,
    required this.realmType,
    required this.role,
    required this.onClose,
  });

  final String realmName;
  final String realmType;
  final Role? role;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Enamel.raisedUmber)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('POSSIBLE ACTIONS', style: Type.eyebrow),
                  const SizedBox(height: 5),
                  Text(realmName, style: Type.realmName),
                  const SizedBox(height: 3),
                  Text(
                    // The role is stated, because it is the reason the list is
                    // the length it is.
                    '${realmType.toUpperCase()}  ·  ${(role ?? Role.guest).label.toUpperCase()}',
                    style: Type.eyebrow.copyWith(color: Enamel.camel),
                  ),
                ],
              ),
            ),
            if (onClose != null)
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(3),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    '×',
                    style: Type.heading.copyWith(
                      fontSize: 16,
                      color: Enamel.camel,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action, required this.onTap});

  final PossibleAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '${action.label}. ${action.group.label}.'
            '${action.sovereign ? ' Sovereign act, press and hold.' : ''}'
            '${action.webOnly ? ' Web surface only.' : ''}',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(3),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 26,
                  child: Text(
                    action.motif,
                    style: Type.heading.copyWith(
                      fontSize: 15,
                      color: Enamel.skyBlue,
                    ),
                  ),
                ),
                Expanded(child: Text(action.label, style: Type.body)),
                // Sovereign and web-only are stated, not implied by styling
                // alone — status is never carried by colour on its own.
                if (action.sovereign)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(
                      'HOLD',
                      style: Type.eyebrow.copyWith(color: Enamel.sunGold),
                    ),
                  ),
                if (action.webOnly)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(
                      'WEB',
                      style: Type.eyebrow.copyWith(color: Enamel.camel),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

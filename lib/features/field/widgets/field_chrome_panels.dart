import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../controllers/field_controller.dart';
import 'field_panel.dart';
import 'inspect_panel.dart';
import 'navigation_panel.dart';
import 'possible_actions.dart';

/// The permanent chrome panels: Navigation, Compute, Possible Actions, Inspect.
class FieldChromePanels extends StatelessWidget {
  const FieldChromePanels({
    super.key,
    required this.state,
    required this.controller,
    required this.bounds,
    required this.opacity,
    this.realmNames = const {},
  });

  final FieldState state;
  final FieldController controller;
  final Size bounds;
  final double opacity;
  final Map<String, String> realmNames;

  double _clampLeft(double left) =>
      left.clamp(8.0, (bounds.width - 40).clamp(8.0, double.infinity));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final realm = state.currentRealm;

    final navWidth = (bounds.width - 840).clamp(220.0, 620.0);

    return Stack(
      children: [
        FieldPanel(
          key: const ValueKey('panel-navigation'),
          label: l10n.navigation,
          bounds: bounds,
          width: navWidth,
          opacity: opacity,
          initialOffset: Offset(
            _clampLeft((bounds.width - navWidth) / 2),
            (bounds.height * 0.3).clamp(8.0, double.infinity),
          ),
          child: NavigationPanel(
            realmPath: state.realmPath,
            realmNames: realmNames,
            onBreadcrumbTap: controller.navigateToBreadcrumb,
          ),
        ),
        FieldPanel(
          key: const ValueKey('panel-actions'),
          label: l10n.possibleActions,
          bounds: bounds,
          width: 540,
          opacity: opacity,
          accent: true,
          initialMode: FieldPanelMode.collapsed,
          initialOffset: Offset(
            _clampLeft((bounds.width - 540) / 2),
            (bounds.height * 0.3).clamp(8.0, double.infinity),
          ),
          minimizedOffset: const Offset(22, 110),
          child: const PossibleActions(),
        ),
        if (state.inspectOpen)
          FieldPanel(
            key: const ValueKey('panel-inspect'),
            label: '${l10n.inspect} ${realm.name}',
            summary: realm.name,
            bounds: bounds,
            width: 430,
            opacity: opacity,
            initialOffset: Offset(
              _clampLeft((bounds.width - 430) / 2),
              (bounds.height * 0.3).clamp(8.0, double.infinity),
            ),
            onClose: controller.toggleInspect,
            child: InspectPanel(realm: realm),
          ),
      ],
    );
  }
}

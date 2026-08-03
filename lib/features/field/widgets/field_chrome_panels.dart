import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../controllers/field_controller.dart';
import '../data/field_fixtures.dart';
import 'compute_card.dart';
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
  });

  final FieldState state;
  final FieldController controller;
  final Size bounds;
  final double opacity;

  double _clampLeft(double left) =>
      left.clamp(8.0, (bounds.width - 40).clamp(8.0, double.infinity));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final realm = state.currentRealm;

    return Stack(
      children: [
        FieldPanel(
          key: const ValueKey('panel-navigation'),
          label: l10n.navigation,
          bounds: bounds,
          width: (bounds.width - 840).clamp(220.0, 620.0),
          opacity: opacity,
          initialOffset: Offset(_clampLeft(540), 22),
          child: NavigationPanel(
            realmPath: state.realmPath,
            onBreadcrumbTap: controller.navigateToBreadcrumb,
          ),
        ),
        FieldPanel(
          key: const ValueKey('panel-compute'),
          label: l10n.compute,
          summary: FieldFixtures.computeBalance,
          bounds: bounds,
          width: 256,
          opacity: opacity,
          initialOffset: Offset(_clampLeft(bounds.width - 256 - 22), 22),
          child: const ComputeCard(),
        ),
        if (state.actionsVisible)
          FieldPanel(
            key: const ValueKey('panel-actions'),
            label: l10n.possibleActions,
            bounds: bounds,
            width: 540,
            opacity: opacity,
            accent: true,
            initialOffset: Offset(
              _clampLeft((bounds.width - 540) / 2),
              bounds.height * 0.28,
            ),
            onClose: controller.closeActions,
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
            initialOffset: const Offset(22, 96),
            onClose: controller.toggleInspect,
            child: InspectPanel(realm: realm),
          ),
      ],
    );
  }
}

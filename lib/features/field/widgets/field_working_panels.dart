import 'package:flutter/material.dart';

import '../../../core/enums/capacity_target.dart';
import '../../../core/extensions/context_extensions.dart';
import '../controllers/field_controller.dart';
import '../data/field_fixtures.dart';
import 'automations_panel.dart';
import 'capacity_choices.dart';
import 'connections_panel.dart';
import 'field_panel.dart';
import 'invite_panel.dart';
import 'portrait_designer.dart';
import 'presence_panel_cap.dart';
import 'present_panel.dart';
import 'realm_panel.dart';
import 'skill_create_form.dart';
import 'skills_panel.dart';
import 'tool_credential_form.dart';
import 'wisdom_panel.dart';

/// The dynamically opened working panels: open actions, capacity panels,
/// and portrait designers.
class FieldWorkingPanels extends StatelessWidget {
  const FieldWorkingPanels({
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

  Offset _staggeredOffset(double width, int index) {
    return Offset(
      _clampLeft(bounds.width * 0.5 - width / 2 + index * 26),
      (bounds.height * 0.2 + index * 26).clamp(8.0, double.infinity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final children = <Widget>[];
    var stagger = 0;

    for (final id in state.openActions) {
      final action = FieldFixtures.actions.firstWhere((a) => a.id == id);
      children.add(
        FieldPanel(
          key: ValueKey('action-$id'),
          label: action.panelLabel,
          bounds: bounds,
          width: 620,
          opacity: opacity,
          initialOffset: _staggeredOffset(620, stagger++),
          onClose: () => controller.closeAction(id),
          child: _actionBody(id),
        ),
      );
    }

    for (final id in state.realmCapacities) {
      children.add(_capacityPanel(id, CapacityTarget.realm, stagger++));
    }
    for (final id in state.allyCapacities) {
      children.add(_capacityPanel(id, CapacityTarget.ally, stagger++));
    }

    if (state.realmPortraitOpen) {
      children.add(
        FieldPanel(
          key: const ValueKey('portrait-realm'),
          label: l10n.realmName,
          bounds: bounds,
          width: 380,
          opacity: opacity,
          initialOffset: _staggeredOffset(380, stagger++),
          onClose: () => controller.setRealmPortraitOpen(false),
          child: const PortraitDesigner(kind: PortraitKind.realm),
        ),
      );
    }
    if (state.allyPortraitOpen) {
      children.add(
        FieldPanel(
          key: const ValueKey('portrait-ally'),
          label: l10n.design,
          bounds: bounds,
          width: 380,
          opacity: opacity,
          initialOffset: _staggeredOffset(380, stagger++),
          onClose: () => controller.setAllyPortraitOpen(false),
          child: const PortraitDesigner(kind: PortraitKind.ally),
        ),
      );
    }

    if (state.skillFormOpen) {
      final isEditing = state.editingSkill != null;
      children.add(
        FieldPanel(
          key: ValueKey('skill-${isEditing ? 'edit' : 'create'}'),
          label: isEditing
              ? 'Edit ${state.editingSkill!.name}'
              : l10n.createNewSkillWithKi,
          bounds: bounds,
          width: 620,
          opacity: opacity,
          initialOffset: _staggeredOffset(620, stagger++),
          onClose: controller.closeSkillForm,
          child: SkillCreateForm(onClose: controller.closeSkillForm),
        ),
      );
    }

    if (state.connectingTool != null) {
      final toolName = state.connectingTool!;
      final displayName =
          {
            'bluesky': 'Bluesky',
            'google': 'Google',
            'telegram': 'Telegram',
            'solana': 'Solana Wallet',
          }[toolName] ??
          toolName;
      children.add(
        FieldPanel(
          key: ValueKey('connect-$toolName'),
          label: 'Connect $displayName',
          bounds: bounds,
          width: 480,
          opacity: opacity,
          initialOffset: _staggeredOffset(480, stagger++),
          onClose: controller.cancelConnectingTool,
          child: ToolCredentialForm(
            toolName: toolName,
            isVerifying: state.toolVerifying,
            error: state.toolVerifyError,
            onSubmit: (credentials) => controller.connectTool(
              toolName: toolName,
              credentials: credentials,
            ),
            onCancel: controller.cancelConnectingTool,
          ),
        ),
      );
    }

    return Stack(children: children);
  }

  Widget _actionBody(String id) {
    switch (id) {
      case 'invite':
        return InvitePanel(askAbout: controller.askAbout);
      case 'realm':
        return const RealmPanel();
      case 'shape':
        return CapacityChoices(
          target: CapacityTarget.realm,
          realmName: state.currentRealm.name,
        );
      case 'present':
        return const PresentPanel();
      default:
        return const SizedBox.shrink();
    }
  }

  FieldPanel _capacityPanel(String id, CapacityTarget target, int index) {
    final capacity = FieldFixtures.capacities.firstWhere((c) => c.id == id);
    final prefix = target == CapacityTarget.ally ? 'ally' : 'realm';
    return FieldPanel(
      key: ValueKey('$prefix-cap-$id'),
      label: capacity.label,
      bounds: bounds,
      width: 760,
      opacity: opacity,
      initialOffset: _staggeredOffset(760, index),
      onClose: () => controller.closeCapacity(target, id),
      child: _capacityBody(id),
    );
  }

  Widget _capacityBody(String id) {
    final realmName = state.currentRealm.name;
    switch (id) {
      case 'wisdom':
        return WisdomPanel(realmName: realmName);
      case 'presence':
        return PresenceCapacityPanel(realmName: realmName);
      case 'connections':
        return ConnectionsPanel(realmName: realmName);
      case 'automations':
        return AutomationsPanel(realmName: realmName);
      case 'skills':
        return SkillsPanel(realmName: realmName);
      default:
        return const SizedBox.shrink();
    }
  }
}

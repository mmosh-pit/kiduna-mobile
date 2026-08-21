import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/capacity_target.dart';
import '../../../core/extensions/context_extensions.dart';
import '../controllers/field_controller.dart';
import '../controllers/knowledge_controller.dart';
import '../controllers/presence_controller.dart';
import '../data/field_fixtures.dart';
import 'approvals_panel.dart';
import 'automations_panel.dart';
import 'capacity_choices.dart';
import 'connections_panel.dart';
import 'field_panel.dart';
import 'invite_panel.dart';
import 'kb_detail_panel.dart';
import 'portrait_designer.dart';
import 'presence_detail_panel.dart';
import 'presence_panel_cap.dart';
import 'present_panel.dart';
import 'realm_panel.dart';
import 'skill_create_form.dart';
import 'skills_panel.dart';
import 'tool_credential_form.dart';
import 'wisdom_panel.dart';

/// The dynamically opened working panels: open actions, capacity panels,
/// and portrait designers.
class FieldWorkingPanels extends ConsumerWidget {
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
      (bounds.height * 0.3 + index * 26).clamp(8.0, double.infinity),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          width: 560,
          opacity: opacity,
          initialOffset: Offset(
            _clampLeft(bounds.width * 0.5 - 560 / 2 + stagger * 26),
            (bounds.height * 0.05).clamp(8.0, double.infinity),
          ),
          onClose: controller.closeSkillForm,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: bounds.height * 0.85,
            ),
            child: SkillCreateForm(onClose: controller.closeSkillForm),
          ),
        ),
      );
      stagger++;
    }

    if (state.approvalsOpen) {
      children.add(
        FieldPanel(
          key: const ValueKey('approvals'),
          label: 'Pending Approvals',
          bounds: bounds,
          width: 480,
          opacity: opacity,
          initialOffset: _staggeredOffset(480, stagger++),
          onClose: controller.closeApprovals,
          child: const ApprovalsPanel(),
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

    final kbState = ref.watch(knowledgeControllerProvider);
    if (kbState.kbDetailOpen) {
      final kbCtrl = ref.read(knowledgeControllerProvider.notifier);
      final kbLabel = kbState.isCreateMode
          ? l10n.createKnowledgeBase
          : kbState.activeKb?.name ?? l10n.wisdom;
      children.add(
        FieldPanel(
          key: ValueKey('kb-detail-${kbState.activeKb?.id ?? 'create'}'),
          label: kbLabel,
          bounds: bounds,
          width: 420,
          opacity: opacity,
          initialOffset: Offset((bounds.width - 420) / 2, 60),
          onClose: kbCtrl.closeKbDetail,
          child: KbDetailPanel(onClose: kbCtrl.closeKbDetail),
        ),
      );
    }

    final pState = ref.watch(presenceControllerProvider);
    if (pState.detailOpen) {
      final pCtrl = ref.read(presenceControllerProvider.notifier);
      final pLabel = pState.isCreateMode
          ? 'Create Instruct'
          : pState.activeInstruct?.name ?? 'Presence';
      children.add(
        FieldPanel(
          key: ValueKey('presence-detail-${pState.activeInstruct?.id ?? 'create'}'),
          label: pLabel,
          bounds: bounds,
          width: 420,
          opacity: opacity,
          initialOffset: Offset((bounds.width - 420) / 2, 60),
          onClose: pCtrl.closeDetail,
          child: PresenceDetailPanel(onClose: pCtrl.closeDetail),
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
    final panelWidth = (id == 'wisdom' || id == 'presence') ? 480.0 : 760.0;
    final offset = (id == 'wisdom' || id == 'presence')
        ? Offset((bounds.width - panelWidth) / 2, 120)
        : _staggeredOffset(panelWidth, index);
    return FieldPanel(
      key: ValueKey('$prefix-cap-$id'),
      label: capacity.label,
      bounds: bounds,
      width: panelWidth,
      opacity: opacity,
      initialOffset: offset,
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
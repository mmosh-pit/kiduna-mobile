import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_header.dart';
import '../controllers/field_controller.dart';
import '../widgets/advanced_actions_panel.dart';
import '../widgets/compute_card.dart';
import '../widgets/enamel_icon.dart';
import '../widgets/field_background.dart';
import '../widgets/field_panel.dart';
import '../widgets/inspect_panel.dart';
import '../widgets/navigation_panel.dart';
import '../widgets/possible_actions.dart';
import '../widgets/realm_constellation.dart';
import '../widgets/realm_context_pill.dart';

// One-off Ki-rail ground values from the prototype `.kiRegion`.
const Color _kiGround = Color(0xFF100B08);

/// The Advanced Ecosystem View (AEV) — recreation of the prototype's
/// `T1 · S1 · 1.1`.
///
/// Desktop-first, mirroring the prototype: the full view needs at least
/// [Breakpoints.desktop] px of width; below that a "reopen wider" notice is
/// shown. On desktop the Field (constellation + overlaid panels) and Ki sit
/// side by side.
///
/// First pass: the constellation, overlaid panels, and Ki rail render with the
/// prototype's fixture content. Panel dragging works; pan/zoom, node selection,
/// and the gravity slider are wired in a following pass.
class AevScreen extends StatelessWidget {
  const AevScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.kiduna.field,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < Breakpoints.desktop) {
                  return const _NarrowWarning();
                }
                return const _AevWorkspace();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The Field / boundary / Ki split.
class _AevWorkspace extends StatelessWidget {
  const _AevWorkspace();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(flex: 70, child: _AevField()),
        _Boundary(),
        Expanded(flex: 30, child: _AevKi()),
      ],
    );
  }
}

/// The pannable Field: deep-field ground, the realm constellation, and the
/// overlaid panels.
class _AevField extends ConsumerWidget {
  const _AevField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fieldControllerProvider);
    final controller = ref.read(fieldControllerProvider.notifier);
    final realm = state.currentRealm;
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bounds = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          children: [
            const Positioned.fill(child: FieldBackground()),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 96,
                  left: 26,
                  right: 26,
                  bottom: 28,
                ),
                child: RealmConstellation(
                  currentRealmId: state.currentRealmId,
                  selectedRealmId: state.selectedRealmId,
                  onSelect: controller.selectAtlasRealm,
                ),
              ),
            ),
            Positioned(
              top: 22,
              left: 22,
              child: RealmContextPill(
                realm: realm,
                inspectOpen: state.inspectOpen,
                onInspect: controller.toggleInspect,
                width: 620,
                viewToggle: const _AtlasSceneToggle(),
              ),
            ),
            FieldPanel(
              label: l10n.navigation,
              bounds: bounds,
              width: 360,
              initialOffset: Offset(
                (constraints.maxWidth > 1020)
                    ? 644
                    : constraints.maxWidth - 382,
                16,
              ),
              child: NavigationPanel(realmName: realm.name),
            ),
            FieldPanel(
              label: l10n.compute,
              bounds: bounds,
              width: 256,
              initialOffset: Offset(constraints.maxWidth - 256 - 22, 22),
              child: const ComputeCard(),
            ),
            FieldPanel(
              label: l10n.possibleActions,
              bounds: bounds,
              width: 260,
              accent: true,
              initialMode: FieldPanelMode.collapsed,
              initialOffset: const Offset(22, 100),
              onClose: () {},
              child: const PossibleActions(),
            ),
            if (state.inspectOpen)
              FieldPanel(
                key: const ValueKey('panel-inspect'),
                label: '${l10n.inspect} ${realm.name}',
                bounds: bounds,
                width: 430,
                initialOffset: const Offset(22, 96),
                onClose: controller.toggleInspect,
                child: InspectPanel(realm: realm),
              ),
            if (state.selectedPlacement != null)
              FieldPanel(
                key: ValueKey(
                  'panel-advanced-${state.selectedRealmId}',
                ),
                label: state.selectedPlacement!.realm.name,
                bounds: bounds,
                width: 520,
                initialOffset: Offset(
                  (constraints.maxWidth > 1020)
                      ? constraints.maxWidth * 0.35
                      : 22,
                  96,
                ),
                onClose: controller.clearSelection,
                child: AdvancedActionsPanel(
                  placement: state.selectedPlacement!,
                  isCurrent:
                      state.selectedRealmId == state.currentRealmId,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The Atlas / Scene segmented toggle. Atlas is selected; Scene is present but
/// disabled at this View (matching the prototype).
class _AtlasSceneToggle extends StatelessWidget {
  const _AtlasSceneToggle();

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.deep.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.camel.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: colors.sky,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              context.l10n.atlas,
              style: text.labelStrong.copyWith(color: colors.skyButtonInk),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              context.l10n.scene,
              style: text.labelStrong.copyWith(color: colors.quiet),
            ),
          ),
        ],
      ),
    );
  }
}

/// The resizable boundary between Field and Ki (static in this pass).
class _Boundary extends StatelessWidget {
  const _Boundary();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      color: const Color(0xFF100A06),
      alignment: Alignment.center,
      child: Container(
        width: 2,
        height: 34,
        decoration: BoxDecoration(
          color: context.kiduna.sky.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// The Ki rail — static content matching the AEV prototype.
class _AevKi extends StatelessWidget {
  const _AevKi();

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _kiGround,
        border: Border(
          left: BorderSide(color: colors.sky.withValues(alpha: 0.12)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _KiHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.aevKiWelcome,
                      style: text.bodyLarge.copyWith(color: colors.text),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.aevKiWelcomeDetail,
                      style: text.body.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _KiChip(label: context.l10n.whatShouldIDoFirst),
                _KiChip(label: context.l10n.tellMeMoreAboutKinshipDuna),
              ],
            ),
            const SizedBox(height: 14),
            const _KiComposer(),
          ],
        ),
      ),
    );
  }
}

class _KiHeader extends StatelessWidget {
  const _KiHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Column(
      children: [
        Row(
          children: [
            const EnamelIcon(kind: EnamelKind.ki, size: 52),
            const SizedBox(width: 12),
            Text(
              context.l10n.ki,
              style: text.display.copyWith(color: colors.cream),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.sky.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: colors.sky.withValues(alpha: 0.4)),
              ),
              child: Text(
                '${context.l10n.yourAllies}  2',
                style: text.bodySmall.copyWith(color: colors.sky),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${context.l10n.fieldFocus.toUpperCase()}  100%',
              style: text.eyebrowSmall.copyWith(color: colors.quiet),
            ),
            const SizedBox(width: 10),
            Container(
              width: 96,
              height: 3,
              decoration: BoxDecoration(
                color: colors.sky,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KiChip extends StatelessWidget {
  const _KiChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: colors.raised.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.line),
      ),
      child: Text(
        label,
        style: context.kidunaText.bodySmall.copyWith(color: colors.cream),
      ),
    );
  }
}

class _KiComposer extends StatelessWidget {
  const _KiComposer();

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.messageKi,
              style: context.kidunaText.body.copyWith(color: colors.quiet),
            ),
          ),
          Icon(Icons.mic_none, size: 20, color: colors.quiet),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.sky,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_upward,
              size: 18,
              color: colors.skyButtonInk,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown below the desktop breakpoint — the prototype's "needs more room"
/// message over the deep-field ground.
class _NarrowWarning extends StatelessWidget {
  const _NarrowWarning();

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return ColoredBox(
      color: colors.field,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.studioNeedsMoreRoom,
                textAlign: TextAlign.center,
                style: context.kidunaText.heading.copyWith(color: colors.cream),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.reopenAtWiderWidth,
                textAlign: TextAlign.center,
                style: context.kidunaText.body.copyWith(color: colors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

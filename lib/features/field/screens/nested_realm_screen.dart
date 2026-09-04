import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/assets.dart';
import '../../../config/kiduna_colors.dart';
import '../../../config/kiduna_text.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/field_realm.dart';
import '../../../data/models/ki_topic.dart';
import '../../../shared/widgets/app_header.dart';
import '../controllers/field_controller.dart';
import '../data/design_persona.dart';
import '../data/realm_atlas.dart';
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

const Color _kiGround = Color(0xFF100B08);

/// Nested Realm view — shows the children of a specific realm on its own page.
/// Navigated to via `/studio/aev/realm/:realmId`.
class NestedRealmScreen extends ConsumerStatefulWidget {
  const NestedRealmScreen({super.key, required this.realmId});

  final String realmId;

  @override
  ConsumerState<NestedRealmScreen> createState() => _NestedRealmScreenState();
}

class _NestedRealmScreenState extends ConsumerState<NestedRealmScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final realm = realmAtlas[widget.realmId];
      if (realm == null) return;
      final hasChildren = visibleChildren(
        realm.id,
        DesignPersona.alice,
      ).isNotEmpty;
      final invitation = hasChildren
          ? 'Possible Actions shows what can be done here. Inspect any '
                'nested Realm or use the breadcrumb to go back.'
          : 'No nested Realms are visible here. Use Navigation to return, '
                'or ask Ki what could be formed here.';
      ref.read(fieldControllerProvider.notifier)
        ..clearSelection()
        ..askAbout(
          KiTopic(
            title: 'Inside ${realm.name}',
            body:
                'Alice is now inside ${realm.name}, a ${realm.type.label}. '
                '${realm.purpose}',
            invitation: invitation,
          ),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final realm = realmAtlas[widget.realmId];
    if (realm == null) {
      return Scaffold(
        backgroundColor: context.kiduna.field,
        body: const Column(
          children: [
            AppHeader(),
            Expanded(child: _NarrowWarning()),
          ],
        ),
      );
    }

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
                return _NestedRealmWorkspace(realm: realm);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NestedRealmWorkspace extends StatelessWidget {
  const _NestedRealmWorkspace({required this.realm});

  final AtlasRealm realm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 70, child: _NestedRealmField(realm: realm)),
        const _Boundary(),
        Expanded(flex: 30, child: _NestedRealmKi(realm: realm)),
      ],
    );
  }
}

class _NestedRealmField extends ConsumerWidget {
  const _NestedRealmField({required this.realm});

  final AtlasRealm realm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fieldControllerProvider);
    final controller = ref.read(fieldControllerProvider.notifier);
    final l10n = context.l10n;

    final emblem =
        realm.type == AtlasRealmType.institution ||
            realm.type == AtlasRealmType.ecosystem
        ? 'conceptual'
        : realm.type.emblemKey;
    final fieldRealm = FieldRealm(
      name: realm.name,
      type: realm.type.label,
      emblemAsset: AppAssets.realmEmblem(emblem),
    );
    final breadcrumb = breadcrumbPathFor(realm.id);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bounds = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(child: FieldBackground()),
            Positioned.fill(
              child: InteractiveViewer(
                scaleEnabled: false,
                boundaryMargin: const EdgeInsets.all(200),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 96,
                    left: 26,
                    right: 26,
                    bottom: 28,
                  ),
                  child: RealmConstellation(
                    currentRealmId: realm.id,
                    selectedRealmId: state.selectedRealmId,
                    onSelect: controller.selectAtlasRealm,
                    showHoverDetails: true,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 22,
              left: 22,
              child: RealmContextPill(
                realm: fieldRealm,
                inspectOpen: state.inspectOpen,
                onInspect: controller.toggleInspect,
                width: 620,
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
              child: NavigationPanel(
                realmPath: breadcrumb,
                onBreadcrumbTap: (index) {
                  if (index == 0) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => NestedRealmScreen(realmId: breadcrumb[index]),
                      ),
                    );
                  }
                },
              ),
            ),
            FieldPanel(
              label: l10n.compute,
              bounds: bounds,
              width: 256,
              initialOffset: Offset(
                (constraints.maxWidth > 1020)
                    ? 644
                    : constraints.maxWidth - 278,
                160,
              ),
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
                label: '${l10n.inspect} ${fieldRealm.name}',
                bounds: bounds,
                width: 430,
                initialOffset: const Offset(22, 96),
                onClose: controller.toggleInspect,
                child: InspectPanel(realm: fieldRealm),
              ),
            if (state.selectedPlacement != null)
              FieldPanel(
                key: ValueKey('panel-advanced-${state.selectedRealmId}'),
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
                  onEnter: (enterRealm) {
                    controller.clearSelection();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => NestedRealmScreen(realmId: enterRealm.id),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

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

class _NestedRealmKi extends ConsumerWidget {
  const _NestedRealmKi({required this.realm});

  final AtlasRealm realm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final kiTopic = ref.watch(fieldControllerProvider.select((s) => s.kiTopic));

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
            _KiHeader(realmName: realm.name),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kiTopic.body,
                      style: text.bodyLarge.copyWith(color: colors.text),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      kiTopic.invitation,
                      style: text.body.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _KiComposer(colors: colors, text: text),
          ],
        ),
      ),
    );
  }
}

class _KiHeader extends StatelessWidget {
  const _KiHeader({required this.realmName});

  final String realmName;

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
            // "Your Allies 2" pill and "Focus 100%" bar removed — they were
            // non-functional hardcoded placeholders causing ghost UI.  (Bug #98)
          ],
        ),
      ],
    );
  }
}

class _KiComposer extends StatelessWidget {
  const _KiComposer({required this.colors, required this.text});

  final KidunaColors colors;
  final KidunaText text;

  @override
  Widget build(BuildContext context) {
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
              style: text.body.copyWith(color: colors.quiet),
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
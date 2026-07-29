import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../shared/layouts/responsive_layout.dart';
import '../controllers/field_controller.dart';
import '../data/field_fixtures.dart';
import '../widgets/capacity_choices.dart';
import '../widgets/capacity_panel.dart';
import '../widgets/compute_card.dart';
import '../widgets/field_background.dart';
import '../widgets/field_panel.dart';
import '../widgets/inspect_panel.dart';
import '../widgets/invite_panel.dart';
import '../widgets/ki_region.dart';
import '../widgets/portrait_designer.dart';
import '../widgets/possible_actions.dart';
import '../widgets/realm_context_pill.dart';
import '../widgets/realm_panel.dart';

/// The Studio Field — recreation of `the-field-01` (Newly Created Ecosystem
/// View). On desktop the Field and Ki sit side by side with a resizable
/// boundary; on narrow surfaces the Field sits above Ki. Movable panels
/// (Compute, Possible Actions, Inspect, and the working panels) overlay the
/// pannable deep-field canvas.
class FieldScreen extends StatelessWidget {
  const FieldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.kiduna.field,
      body: ResponsiveLayout(
        desktop: (_) => const _FieldKiWide(),
        mobile: (_) => const _FieldKiNarrow(),
      ),
    );
  }
}

class _FieldKiWide extends ConsumerWidget {
  const _FieldKiWide();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fraction = ref.watch(
      fieldControllerProvider.select((state) => state.kiFraction),
    );
    final controller = ref.read(fieldControllerProvider.notifier);
    return LayoutBuilder(
      key: const ValueKey('field-wide'),
      builder: (context, constraints) {
        final boundary = context.metrics.boundaryWidth;
        final kiWidth = constraints.maxWidth * fraction;
        final fieldWidth = (constraints.maxWidth - kiWidth - boundary).clamp(
          0.0,
          constraints.maxWidth,
        );
        return Row(
          children: [
            SizedBox(width: fieldWidth, child: const _FieldStack()),
            _Boundary(
              width: boundary,
              onDrag: (dx) => controller.setKiFraction(
                fraction - dx / constraints.maxWidth,
              ),
            ),
            SizedBox(width: kiWidth, child: const KiRegion()),
          ],
        );
      },
    );
  }
}

class _Boundary extends StatelessWidget {
  const _Boundary({required this.width, required this.onDrag});

  final double width;
  final ValueChanged<double> onDrag;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
        child: Semantics(
          label: 'Resize Field and Ki',
          child: Container(
            width: width,
            color: colors.deep,
            alignment: Alignment.center,
            child: Container(
              width: 2,
              height: 34,
              decoration: BoxDecoration(
                color: colors.sky.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldKiNarrow extends StatelessWidget {
  const _FieldKiNarrow();

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: ValueKey('field-narrow'),
      children: [
        Expanded(flex: 3, child: _FieldStack()),
        Expanded(flex: 2, child: KiRegion()),
      ],
    );
  }
}

/// The pannable Field canvas with the movable panels overlaid.
class _FieldStack extends ConsumerWidget {
  const _FieldStack();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fieldControllerProvider);
    final controller = ref.read(fieldControllerProvider.notifier);
    final realm = state.currentRealm;
    final opacity = (state.fieldFocus / 100).clamp(0.0, 1.0);
    final l10n = context.l10n;

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bounds = Size(constraints.maxWidth, constraints.maxHeight);
          double clampLeft(double left) =>
              left.clamp(8.0, (bounds.width - 40).clamp(8.0, double.infinity));

          final children = <Widget>[
            Positioned.fill(
              child: ColoredBox(
                color: context.kiduna.field,
                child: InteractiveViewer(
                  minScale: 0.68,
                  maxScale: 1.45,
                  boundaryMargin: const EdgeInsets.all(160),
                  child: const FieldBackground(),
                ),
              ),
            ),
            Positioned(
              top: 22,
              left: 22,
              child: Opacity(
                opacity: opacity,
                child: RealmContextPill(
                  realm: realm,
                  inspectOpen: state.inspectOpen,
                  onInspect: controller.toggleInspect,
                ),
              ),
            ),
            FieldPanel(
              key: const ValueKey('panel-compute'),
              label: l10n.compute,
              summary: FieldFixtures.computeBalance,
              bounds: bounds,
              width: 256,
              opacity: opacity,
              initialOffset: Offset(clampLeft(bounds.width - 256 - 22), 22),
              child: const ComputeCard(),
            ),
            FieldPanel(
              key: const ValueKey('panel-actions'),
              label: l10n.possibleActions,
              bounds: bounds,
              width: 380,
              opacity: opacity,
              initialOffset: Offset(
                clampLeft((bounds.width - 380) / 2),
                bounds.height * 0.24,
              ),
              child: const PossibleActions(),
            ),
            if (state.inspectOpen)
              FieldPanel(
                key: const ValueKey('panel-inspect'),
                label: '${l10n.inspect} · ${realm.name}',
                summary: realm.name,
                bounds: bounds,
                width: 360,
                opacity: opacity,
                initialOffset: const Offset(22, 96),
                onClose: controller.toggleInspect,
                child: InspectPanel(realm: realm),
              ),
          ];

          var stagger = 0;
          Offset nextOffset(double width) {
            final offset = Offset(
              clampLeft(bounds.width * 0.5 - width / 2 + stagger * 26),
              (bounds.height * 0.2 + stagger * 26).clamp(8.0, double.infinity),
            );
            stagger++;
            return offset;
          }

          for (final id in state.openActions) {
            final action = FieldFixtures.actions.firstWhere((a) => a.id == id);
            children.add(
              FieldPanel(
                key: ValueKey('action-$id'),
                label: action.topic.title,
                bounds: bounds,
                width: 420,
                opacity: opacity,
                initialOffset: nextOffset(420),
                onClose: () => controller.closeAction(id),
                child: _actionBody(id),
              ),
            );
          }

          for (final id in state.realmCapacities) {
            children.add(
              _capacityPanel(
                context,
                id: id,
                target: CapacityTarget.realm,
                bounds: bounds,
                opacity: opacity,
                offset: nextOffset(340),
                controller: controller,
              ),
            );
          }
          for (final id in state.allyCapacities) {
            children.add(
              _capacityPanel(
                context,
                id: id,
                target: CapacityTarget.ally,
                bounds: bounds,
                opacity: opacity,
                offset: nextOffset(340),
                controller: controller,
              ),
            );
          }

          if (state.realmPortraitOpen) {
            children.add(
              FieldPanel(
                key: const ValueKey('portrait-realm'),
                label: l10n.realmName,
                bounds: bounds,
                width: 380,
                opacity: opacity,
                initialOffset: nextOffset(380),
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
                initialOffset: nextOffset(380),
                onClose: () => controller.setAllyPortraitOpen(false),
                child: const PortraitDesigner(kind: PortraitKind.ally),
              ),
            );
          }

          return Stack(children: children);
        },
      ),
    );
  }

  Widget _actionBody(String id) {
    switch (id) {
      case 'invite':
        return const InvitePanel();
      case 'realm':
        return const RealmPanel();
      case 'shape':
        return const CapacityChoices(target: CapacityTarget.realm);
      case 'ally':
        return const CapacityChoices(
          target: CapacityTarget.ally,
          showPortrait: true,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  FieldPanel _capacityPanel(
    BuildContext context, {
    required String id,
    required CapacityTarget target,
    required Size bounds,
    required double opacity,
    required Offset offset,
    required FieldController controller,
  }) {
    final capacity = FieldFixtures.capacities.firstWhere((c) => c.id == id);
    final prefix = target == CapacityTarget.ally ? 'ally' : 'realm';
    return FieldPanel(
      key: ValueKey('$prefix-cap-$id'),
      label: capacity.label,
      bounds: bounds,
      width: 340,
      opacity: opacity,
      initialOffset: offset,
      onClose: () => controller.closeCapacity(target, id),
      child: CapacityPanel(detail: capacity.detail),
    );
  }
}

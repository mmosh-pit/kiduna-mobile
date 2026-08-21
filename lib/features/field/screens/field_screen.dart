import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/field_realm.dart';
import '../../../shared/layouts/responsive_layout.dart';
import '../../../shared/models/section_item.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/section_bar.dart';
import '../../../shared/widgets/section_placeholder.dart';
import '../../exchange/screens/exchange_screen.dart';
import '../controllers/field_controller.dart';
import '../widgets/advanced_actions_panel.dart';
import '../widgets/field_background.dart';
import '../widgets/field_chrome_panels.dart';
import '../widgets/field_panel.dart';
import '../widgets/field_working_panels.dart';
import '../widgets/ki_region.dart';
import '../widgets/realm_constellation.dart';
import '../widgets/realm_context_pill.dart';

/// The main app screen. The header and section bar sit at the top; the active
/// section's content fills the remaining space with Ki alongside.
///
/// * Exchange (index 0, default) — presale exchange UI.
/// * Studio  (index 3) — the original NCEV field with panels and Ki.
/// * Others  — "Coming Soon" placeholder with Ki.
///
/// Existing widgets (_FieldKiWide, _FieldKiNarrow, _FieldStack, _FieldCanvas,
/// _RealmIdentity, _Boundary) are completely untouched below.
class FieldScreen extends StatefulWidget {
  const FieldScreen({super.key});

  @override
  State<FieldScreen> createState() => _FieldScreenState();
}

class _FieldScreenState extends State<FieldScreen> {
  /// Active section index. Exchange (0) is the default.
  int _activeSection = SectionIndex.exchange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.kiduna.field,
      body: Column(
        children: [
          const AppHeader(),
          SectionBar(
            sections: kSections,
            activeIndex: _activeSection,
            onChanged: (i) => setState(() => _activeSection = i),
          ),
          Expanded(child: _buildSectionContent()),
        ],
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_activeSection) {
      case SectionIndex.studio:
        // Original NCEV — existing layout, untouched.
        return ResponsiveLayout(
          desktop: (_) => const _FieldKiWide(),
          mobile: (_) => const _FieldKiNarrow(),
        );
      case SectionIndex.exchange:
        // Presale exchange UI with Ki chat.
        return ResponsiveLayout(
          desktop: (_) => const _ContentKiWide(content: ExchangeScreen()),
          mobile: (_) => const _ContentKiNarrow(content: ExchangeScreen()),
        );
      default:
        // Other sections: placeholder with Ki chat.
        final placeholder = SectionPlaceholder(
          sectionName: kSections[_activeSection].label,
        );
        return ResponsiveLayout(
          desktop: (_) => _ContentKiWide(content: placeholder),
          mobile: (_) => _ContentKiNarrow(content: placeholder),
        );
    }
  }
}

/// Desktop layout for non-Studio sections: content + boundary + Ki side by side.
/// Mirrors _FieldKiWide but accepts any content widget instead of _FieldStack.
class _ContentKiWide extends ConsumerWidget {
  const _ContentKiWide({required this.content});

  final Widget content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kiFraction = ref.watch(
      fieldControllerProvider.select((s) => s.kiFraction),
    );
    final boundaryW = context.metrics.boundaryWidth;
    return LayoutBuilder(
      builder: (context, constraints) {
        final total = constraints.maxWidth;
        final kiWidth = max(280.0, kiFraction * total);
        final contentWidth = max(0.0, total - boundaryW - kiWidth);
        return Row(
          children: [
            SizedBox(width: contentWidth, child: content),
            SizedBox(
              width: boundaryW,
              child: _Boundary(totalWidth: total),
            ),
            SizedBox(width: kiWidth, child: const KiRegion()),
          ],
        );
      },
    );
  }
}

/// Mobile layout for non-Studio sections: content on top, Ki below.
/// Mirrors _FieldKiNarrow but accepts any content widget.
class _ContentKiNarrow extends StatelessWidget {
  const _ContentKiNarrow({required this.content});

  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(flex: 3, child: content),
        const Expanded(flex: 2, child: KiRegion()),
      ],
    );
  }
}

class _FieldKiWide extends ConsumerWidget {
  const _FieldKiWide();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kiFraction = ref.watch(
      fieldControllerProvider.select((s) => s.kiFraction),
    );
    final boundaryW = context.metrics.boundaryWidth;
    return LayoutBuilder(
      key: const ValueKey('field-wide'),
      builder: (context, constraints) {
        final total = constraints.maxWidth;
        final kiWidth = max(280.0, kiFraction * total);
        final fieldWidth = max(0.0, total - boundaryW - kiWidth);
        return Row(
          children: [
            SizedBox(width: fieldWidth, child: const FieldStack()),
            SizedBox(
              width: boundaryW,
              child: _Boundary(totalWidth: total),
            ),
            SizedBox(width: kiWidth, child: const KiRegion()),
          ],
        );
      },
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
        Expanded(flex: 3, child: FieldStack()),
        Expanded(flex: 2, child: KiRegion()),
      ],
    );
  }
}

/// The pannable Field canvas with the movable panels overlaid.
class FieldStack extends ConsumerWidget {
  const FieldStack({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fieldControllerProvider);
    final controller = ref.read(fieldControllerProvider.notifier);
    final realm = state.currentRealm;
    final opacity = (state.fieldFocus / 100).clamp(0.0, 1.0);

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bounds = Size(constraints.maxWidth, constraints.maxHeight);

          return Stack(
            children: [
              const _FieldCanvas(),
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
                      currentRealmId: state.currentRealmId,
                      selectedRealmId: state.selectedRealmId,
                      onSelect: controller.selectAtlasRealm,
                      showHoverDetails: true,
                    ),
                  ),
                ),
              ),
              _RealmIdentity(
                realm: realm,
                inspectOpen: state.inspectOpen,
                onInspect: controller.toggleInspect,
                bounds: bounds,
                opacity: opacity,
              ),
              FieldChromePanels(
                state: state,
                controller: controller,
                bounds: bounds,
                opacity: opacity,
              ),
              FieldWorkingPanels(
                state: state,
                controller: controller,
                bounds: bounds,
                opacity: opacity,
              ),
              if (state.selectedPlacement != null)
                FieldPanel(
                  key: ValueKey('panel-advanced-${state.selectedRealmId}'),
                  label: state.selectedPlacement!.realm.name,
                  bounds: bounds,
                  width: 520,
                  opacity: opacity,
                  initialOffset: Offset(
                    ((bounds.width - 520) / 2).clamp(8.0, double.infinity),
                    (bounds.height * 0.3).clamp(8.0, double.infinity),
                  ),
                  onClose: controller.clearSelection,
                  child: AdvancedActionsPanel(
                    placement: state.selectedPlacement!,
                    onEnter: (enterRealm) {
                      controller.clearSelection();
                      controller.enterAtlasRealm(enterRealm);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FieldCanvas extends StatelessWidget {
  const _FieldCanvas();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: context.kiduna.field,
        child: const FieldBackground(),
      ),
    );
  }
}

class _RealmIdentity extends StatelessWidget {
  const _RealmIdentity({
    required this.realm,
    required this.inspectOpen,
    required this.onInspect,
    required this.bounds,
    required this.opacity,
  });

  final FieldRealm realm;
  final bool inspectOpen;
  final VoidCallback onInspect;
  final Size bounds;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 22,
      left: 22,
      child: Opacity(
        opacity: opacity,
        child: RealmContextPill(
          realm: realm,
          inspectOpen: inspectOpen,
          onInspect: onInspect,
          width: (bounds.width * 0.4).clamp(320.0, 500.0),
        ),
      ),
    );
  }
}

/// The 7px resizable boundary between the Field region and Ki.
///
/// CSS: `.boundaryControl` — bg #100a06, camel left border, sky right border,
/// centered 2px×34px sky handle with glow.
class _Boundary extends ConsumerStatefulWidget {
  const _Boundary({required this.totalWidth});

  final double totalWidth;

  @override
  ConsumerState<_Boundary> createState() => _BoundaryState();
}

class _BoundaryState extends ConsumerState<_Boundary> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final skyHandle = _hovered
        ? colors.sky
        : colors.sky.withValues(alpha: 0.32);
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          final delta = -details.delta.dx / widget.totalWidth;
          final current = ref.read(fieldControllerProvider).kiFraction;
          ref
              .read(fieldControllerProvider.notifier)
              .setKiFraction(current + delta);
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF100A06),
            border: Border(
              left: BorderSide(color: colors.camel.withValues(alpha: 0.18)),
              right: BorderSide(color: colors.sky.withValues(alpha: 0.12)),
            ),
          ),
          child: Center(
            child: Container(
              width: 2,
              height: 34,
              decoration: BoxDecoration(
                color: skyHandle,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    color: colors.sky.withValues(alpha: 0.18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

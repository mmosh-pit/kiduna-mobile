import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/field_realm.dart';
import '../../../shared/layouts/responsive_layout.dart';
import '../../../shared/widgets/app_header.dart';
import '../controllers/field_controller.dart';
import '../widgets/field_background.dart';
import '../widgets/field_chrome_panels.dart';
import '../widgets/field_working_panels.dart';
import '../widgets/ki_region.dart';
import '../widgets/realm_context_pill.dart';

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
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: ResponsiveLayout(
              desktop: (_) => const _FieldKiWide(),
              mobile: (_) => const _FieldKiNarrow(),
            ),
          ),
        ],
      ),
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
            SizedBox(width: fieldWidth, child: const _FieldStack()),
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

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bounds = Size(constraints.maxWidth, constraints.maxHeight);

          return Stack(
            children: [
              const _FieldCanvas(),
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

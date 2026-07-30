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
          label: context.l10n.resizeFieldAndKi,
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
        child: InteractiveViewer(
          minScale: 0.68,
          maxScale: 1.45,
          boundaryMargin: const EdgeInsets.all(160),
          child: const FieldBackground(),
        ),
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

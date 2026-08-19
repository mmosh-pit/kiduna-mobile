import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/apiary_controller.dart';
import '../data/bee_manifest.dart';
import '../data/task_model.dart';
import 'bee_entity.dart';
import 'task_overlay.dart';

/// The Apiary task board — spatial bee scene on a beehive background.
///
/// Bees are positioned within their stage zones. Tapping a bee opens
/// a floating task overlay. No card lists — just bees on honeycomb.
class ApiaryBoard extends ConsumerWidget {
  const ApiaryBoard({super.key});

  // Zone boundaries as fractions of scene width.
  static const _zoneBounds = <TaskStage, (double start, double end)>{
    TaskStage.ready: (0.0, 0.2),
    TaskStage.build: (0.2, 0.4),
    TaskStage.test: (0.4, 0.6),
    TaskStage.release: (0.6, 0.8),
    TaskStage.live: (0.8, 1.0),
  };

  /// Stage header accent colors.
  static Color _stageColor(TaskStage s) => switch (s) {
    TaskStage.ready => const Color(0xFF94A3B8),
    TaskStage.build => const Color(0xFF38BDF8),
    TaskStage.test => const Color(0xFFF59E0B),
    TaskStage.release => const Color(0xFFAB68FF),
    TaskStage.live => const Color(0xFF4ADE80),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(apiaryControllerProvider);
    final controller = ref.read(apiaryControllerProvider.notifier);

    if (state.isLoading && state.tasks.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFDAB875),
          strokeWidth: 2,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final sceneW = constraints.maxWidth;
        final sceneH = constraints.maxHeight;

        const headerH = 36.0;
        const maxReveal = 5;

        // Bee size scales with scene.
        final beeSize = (sceneW / 10).clamp(48.0, 80.0);

        // Pre-compute bee positions for every task.
        final beePositions = _computeBeePositions(
          state.tasks, sceneW, sceneH, headerH, beeSize,
        );

        return Stack(
          children: [
            // ── Layer 1: Beehive background ─────────────────────
            Positioned.fill(
              child: Image.asset(
                'assets/images/beehive_bg.png',
                fit: BoxFit.fill,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: Color(0xFF0A0807)),
              ),
            ),

            // ── Layer 2: Dark overlays per zone ─────────────────
            Positioned.fill(
              child: Row(
                children: [
                  for (final stage in TaskStage.values)
                    Expanded(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        opacity: _overlayOpacity(
                          state.countForStage(stage), maxReveal,
                        ),
                        child: const ColoredBox(color: Color(0xFF0A0807)),
                      ),
                    ),
                ],
              ),
            ),

            // ── Layer 3: Zone headers ───────────────────────────
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: headerH,
              child: Row(
                children: [
                  for (final stage in TaskStage.values)
                    Expanded(child: _zoneHeader(stage, state, sceneW)),
                ],
              ),
            ),

            // ── Layer 4: Wall dividers ──────────────────────────
            for (var i = 1; i < 5; i++)
              Positioned(
                left: sceneW * (i / 5),
                top: headerH,
                bottom: 0,
                child: Container(
                  width: 1,
                  color: const Color(0xFFF2EADF).withValues(alpha: 0.06),
                ),
              ),

            // ── Layer 5: Dismiss tap catcher (behind bees) ────
            if (state.expandedTaskId != null)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => controller.collapseTask(),
                ),
              ),

            // ── Layer 6: Bee entities ───────────────────────────
            for (final entry in beePositions.entries)
              Positioned(
                left: entry.value.dx - beeSize / 2,
                top: entry.value.dy - beeSize / 2,
                child: BeeEntity(
                  beeType: BeeManifest.forCategory(
                    state.tasks
                        .firstWhere((t) => t.id == entry.key)
                        .category,
                  ),
                  headingDeg: _stableHeading(entry.key),
                  size: beeSize,
                  isSelected: state.expandedTaskId == entry.key,
                  onTap: () => controller.expandTask(entry.key),
                ),
              ),

            // ── Layer 7: Task overlay ───────────────────────────
            if (state.expandedTaskId != null &&
                beePositions.containsKey(state.expandedTaskId))
              Builder(builder: (context) {
                final task = state.tasks.firstWhere(
                  (t) => t.id == state.expandedTaskId,
                );
                final beePos = beePositions[state.expandedTaskId]!;

                // Position overlay near the bee, clamped to scene.
                const overlayW = 280.0;
                const overlayH = 260.0;

                // Prefer right side of the bee.
                var ox = beePos.dx + beeSize / 2 + 8;
                if (ox + overlayW > sceneW - 8) {
                  // Not enough room on right — place on left.
                  ox = beePos.dx - beeSize / 2 - overlayW - 8;
                }
                ox = ox.clamp(8.0, sceneW - overlayW - 8);

                // Center vertically on the bee.
                var oy = beePos.dy - overlayH / 2;
                oy = oy.clamp(headerH + 4, sceneH - overlayH - 8);

                return Positioned(
                  left: ox,
                  top: oy,
                  child: TaskOverlay(
                    task: task,
                    onClose: () => controller.collapseTask(),
                    onFieldTap: (field) =>
                        controller.sendTaskContext(task.id, field),
                  ),
                );
              }),

          ],
        );
      },
    );
  }

  /// Zone header — thin bar with stage label + count.
  Widget _zoneHeader(TaskStage stage, ApiaryState state, double sceneW) {
    final accent = _stageColor(stage);
    final count = state.countForStage(stage);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0807).withValues(alpha: 0.6),
        border: Border(
          bottom: BorderSide(color: accent.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            stage.label,
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 6),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: accent.withValues(alpha: 0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Compute pixel positions for all bees within their zones.
  Map<String, Offset> _computeBeePositions(
    List<TaskModel> tasks,
    double sceneW,
    double sceneH,
    double headerH,
    double beeSize,
  ) {
    final positions = <String, Offset>{};

    // Group tasks by stage.
    final grouped = <TaskStage, List<TaskModel>>{};
    for (final t in tasks) {
      grouped.putIfAbsent(t.stage, () => []).add(t);
    }

    for (final stage in TaskStage.values) {
      final zoneTasks = grouped[stage] ?? [];
      if (zoneTasks.isEmpty) continue;

      final bounds = _zoneBounds[stage]!;
      final zoneLeft = sceneW * bounds.$1;
      final zoneRight = sceneW * bounds.$2;
      final zoneW = zoneRight - zoneLeft;
      final availH = sceneH - headerH;

      // How many columns fit in this zone.
      final cols = (zoneW / (beeSize * 1.3)).floor().clamp(1, 4);
      final spacingX = zoneW / (cols + 1);
      final spacingY = (beeSize * 1.5).clamp(60.0, 100.0);

      for (var i = 0; i < zoneTasks.length; i++) {
        final col = i % cols;
        final row = i ~/ cols;

        final x = zoneLeft + spacingX * (col + 1);
        final y = headerH + spacingY * (row + 1);

        // Clamp within scene bounds.
        final clampedY = y.clamp(headerH + beeSize, sceneH - beeSize);

        positions[zoneTasks[i].id] = Offset(x, clampedY);
      }
    }

    return positions;
  }

  /// Generate a stable heading per task (based on ID hash, not random).
  double _stableHeading(String taskId) {
    return (taskId.hashCode % 360).toDouble();
  }

  /// Dark overlay opacity: 0 tasks = fully dark, maxReveal = fully revealed.
  double _overlayOpacity(int count, int max) {
    if (count <= 0) return 1.0;
    if (count >= max) return 0.0;
    return 1.0 - (count / max);
  }
}
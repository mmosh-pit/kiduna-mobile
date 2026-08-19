import 'package:flutter/material.dart';

import '../data/task_model.dart';
import 'task_card.dart';

/// Accent color for each stage column header.
Color _stageColor(TaskStage stage) => switch (stage) {
  TaskStage.ready => const Color(0xFF94A3B8),
  TaskStage.build => const Color(0xFF38BDF8),
  TaskStage.test => const Color(0xFFF59E0B),
  TaskStage.release => const Color(0xFFAB68FF),
  TaskStage.live => const Color(0xFF4ADE80),
};

/// A single stage column on the Apiary board.
///
/// Displays a header with the stage label and task count, followed by
/// a scrollable list of [TaskCard]s.
class StageColumn extends StatelessWidget {
  const StageColumn({
    super.key,
    required this.stage,
    required this.tasks,
    required this.expandedTaskId,
    required this.onTaskTap,
    required this.onTaskFieldTap,
    this.isLast = false,
  });

  final TaskStage stage;
  final List<TaskModel> tasks;
  final String? expandedTaskId;
  final ValueChanged<String> onTaskTap;

  /// Called with (taskId, fieldName) when a field inside an expanded card
  /// is tapped.
  final void Function(String taskId, String field) onTaskFieldTap;

  /// Whether this is the rightmost column (no right border).
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final accent = _stageColor(stage);

    return Container(
      decoration: BoxDecoration(
        // Transparent background so the beehive image shows through.
        // The dark overlay layer controls zone visibility.
        color: const Color(0xFF0A0807).withValues(alpha: 0.3),
        border: isLast
            ? null
            : Border(
                right: BorderSide(
                  color: const Color(0xFFF2EADF).withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0807).withValues(alpha: 0.5),
              border: Border(
                bottom: BorderSide(
                  color: accent.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stage.label,
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: accent.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Task list ───────────────────────────────────────────
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No tasks',
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFFF2EADF)
                              .withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskCard(
                        key: ValueKey(task.id),
                        task: task,
                        isExpanded: expandedTaskId == task.id,
                        onTap: () => onTaskTap(task.id),
                        onFieldTap: (field) =>
                            onTaskFieldTap(task.id, field),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../data/task_model.dart';

/// Icon mapping for sigil categories.
IconData _categoryIcon(String category) => switch (category.toLowerCase()) {
  'compass' => Icons.explore_outlined,
  'shield' => Icons.shield_outlined,
  'spark' => Icons.auto_awesome_outlined,
  'loom' => Icons.hub_outlined,
  'portal' => Icons.door_front_door_outlined,
  'wind' => Icons.air_outlined,
  'flower' => Icons.local_florist_outlined,
  'eye' => Icons.visibility_outlined,
  _ => Icons.hexagon_outlined,
};

/// Accent color for sigil categories.
Color _categoryColor(String category) => switch (category.toLowerCase()) {
  'compass' => const Color(0xFF03CCD9),
  'shield' => const Color(0xFFF59E0B),
  'spark' => const Color(0xFFAB68FF),
  'loom' => const Color(0xFF38BDF8),
  'portal' => const Color(0xFF4ADE80),
  'wind' => const Color(0xFF94A3B8),
  'flower' => const Color(0xFFFB7185),
  'eye' => const Color(0xFFEAAA00),
  _ => const Color(0xFF94A3B8),
};

/// A single task card on the Apiary board.
///
/// Collapsed: shows title, category icon, and assignee.
/// Expanded: shows full description, all fields tappable to send context to Ki.
class TaskCard extends StatefulWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.isExpanded,
    required this.onTap,
    required this.onFieldTap,
  });

  final TaskModel task;
  final bool isExpanded;

  /// Called when the card itself is tapped (expand/collapse).
  final VoidCallback onTap;

  /// Called when a specific field is tapped — sends context to Ki.
  /// The [String] is the field name: 'title', 'assignee', 'category',
  /// 'stage', 'advance'.
  final ValueChanged<String> onFieldTap;

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final accent = _categoryColor(task.category);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hovered || widget.isExpanded
                ? const Color(0xFF1A1714)
                : const Color(0xFF13100D),
            border: Border(
              left: BorderSide(color: accent, width: 2.5),
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
            boxShadow: _hovered || widget.isExpanded
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(task, accent),
              if (widget.isExpanded) ...[
                const SizedBox(height: 10),
                _buildExpandedContent(task, accent),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TaskModel task, Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          _categoryIcon(task.category),
          size: 14,
          color: accent,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE2D9CC),
                  height: 1.3,
                ),
                maxLines: widget.isExpanded ? null : 2,
                overflow:
                    widget.isExpanded ? null : TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (task.isAssigned) ...[
                    Icon(
                      Icons.person_outline,
                      size: 11,
                      color: context.kiduna.camel.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      task.assignee!,
                      style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: context.kiduna.camel.withValues(alpha: 0.7),
                      ),
                    ),
                  ] else
                    Text(
                      'Unassigned',
                      style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: context.kiduna.camel.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent(TaskModel task, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subtitle
        if (task.subtitle != null && task.subtitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              task.subtitle!,
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: accent.withValues(alpha: 0.8),
                letterSpacing: 0.5,
              ),
            ),
          ),

        // Description
        if (task.description.isNotEmpty)
          GestureDetector(
            onTap: () => widget.onFieldTap('title'),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                task.description,
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: context.kiduna.cream.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ),
          ),

        // Metadata row
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            // Category chip — tappable
            _MetaChip(
              icon: _categoryIcon(task.category),
              label: task.category.isNotEmpty ? task.category : 'general',
              color: accent,
              onTap: () => widget.onFieldTap('category'),
            ),

            // Assignee chip — tappable
            _MetaChip(
              icon: Icons.person_outline,
              label: task.isAssigned ? task.assignee! : 'Unassigned',
              color: task.isAssigned
                  ? const Color(0xFF4ADE80)
                  : const Color(0xFF94A3B8),
              onTap: () => widget.onFieldTap('assignee'),
            ),

            // Estimated hours
            if (task.estimatedHours != null && task.estimatedHours! > 0)
              _MetaChip(
                icon: Icons.schedule_outlined,
                label: '${task.estimatedHours!.toStringAsFixed(0)}h',
                color: const Color(0xFF94A3B8),
              ),
          ],
        ),

        const SizedBox(height: 10),

        // Advance button — move to next stage
        if (task.stage.next != null)
          GestureDetector(
            onTap: () => widget.onFieldTap('advance'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: accent.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_forward, size: 12, color: accent),
                  const SizedBox(width: 5),
                  Text(
                    'Move to ${task.stage.next!.label}',
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A small metadata chip used in the expanded card.
class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: child,
        ),
      );
    }
    return child;
  }
}
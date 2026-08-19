import 'package:flutter/material.dart';

import '../data/task_model.dart';

/// Icon for sigil category.
IconData _sigIcon(String c) => switch (c.toLowerCase()) {
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

/// Accent color for sigil category.
Color _sigColor(String c) => switch (c.toLowerCase()) {
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

/// Floating task detail panel shown when a bee is tapped.
///
/// Positioned near the bee, clamped to screen edges. Shows task info
/// and action buttons. Every field tap sends context to Ki.
class TaskOverlay extends StatelessWidget {
  const TaskOverlay({
    super.key,
    required this.task,
    required this.onClose,
    required this.onFieldTap,
  });

  final TaskModel task;
  final VoidCallback onClose;
  final ValueChanged<String> onFieldTap;

  @override
  Widget build(BuildContext context) {
    final accent = _sigColor(task.category);

    return Container(
      width: 280,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF13100D).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accent.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: sigil + title + close ──────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_sigIcon(task.category), size: 16, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.category.isNotEmpty
                          ? task.category[0].toUpperCase() +
                              task.category.substring(1)
                          : 'General',
                      style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: accent.withValues(alpha: 0.7),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () => onFieldTap('title'),
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE2D9CC),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: const Color(0xFFF2EADF).withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),

          // ── Description ────────────────────────────────────────
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => onFieldTap('title'),
              child: Text(
                task.description,
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFF2EADF).withValues(alpha: 0.6),
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // ── Metadata chips ─────────────────────────────────────
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              // Assignee.
              GestureDetector(
                onTap: () => onFieldTap('assignee'),
                child: _chip(
                  Icons.person_outline,
                  task.isAssigned ? task.assignee! : 'Unassigned',
                  task.isAssigned
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFF94A3B8),
                ),
              ),
              // Stage.
              GestureDetector(
                onTap: () => onFieldTap('stage'),
                child: _chip(
                  Icons.circle,
                  task.stage.label,
                  accent,
                  iconSize: 6,
                ),
              ),
              // Estimated hours.
              if (task.estimatedHours != null && task.estimatedHours! > 0)
                _chip(
                  Icons.schedule_outlined,
                  '${task.estimatedHours!.toStringAsFixed(0)}h',
                  const Color(0xFF94A3B8),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Action buttons ─────────────────────────────────────
          Row(
            children: [
              // Advance to next stage.
              if (task.stage.next != null)
                Expanded(
                  child: GestureDetector(
                    onTap: () => onFieldTap('advance'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: accent.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_forward,
                              size: 12, color: accent),
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
                ),

              if (task.stage.next != null) const SizedBox(width: 8),

              // Send to Ki.
              GestureDetector(
                onTap: () => onFieldTap('title'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDAB875).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'Send to Ki',
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFDAB875).withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color, {double iconSize = 11}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: color.withValues(alpha: 0.7)),
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
  }
}

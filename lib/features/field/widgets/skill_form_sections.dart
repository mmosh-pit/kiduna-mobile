import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// Compact row of suggestion chips that fill a text input on tap.
class QuickPickChips extends StatelessWidget {
  const QuickPickChips({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: [
        for (final s in suggestions)
          GestureDetector(
            onTap: () => onSelected(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: colors.sky.withValues(alpha: 0.06),
                border: Border.all(color: colors.sky.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                s,
                style: text.micro.copyWith(color: colors.sky, fontSize: 8),
              ),
            ),
          ),
      ],
    );
  }
}

/// Compact multi-select tool chips.
class ToolChips extends StatelessWidget {
  const ToolChips({
    super.key,
    required this.tools,
    required this.selected,
    required this.onToggle,
  });

  final List<String> tools;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.toolsDescription,
          style: text.micro.copyWith(color: colors.muted, fontSize: 8),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 5,
          runSpacing: 4,
          children: [
            for (final tool in tools)
              GestureDetector(
                onTap: () => onToggle(tool),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: selected.contains(tool)
                        ? colors.sky.withValues(alpha: 0.12)
                        : Colors.transparent,
                    border: Border.all(
                      color: selected.contains(tool)
                          ? colors.sky
                          : colors.camel.withValues(alpha: 0.22),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tool,
                    style: text.micro.copyWith(
                      color: selected.contains(tool)
                          ? colors.sky
                          : colors.muted,
                      fontSize: 8,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Toggle row for the "Requires approval" option.
class ApprovalToggle extends StatelessWidget {
  const ApprovalToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.requiresApprovalLabel,
                style: text.label.copyWith(color: colors.cream),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.requiresApprovalDescription,
                style: text.micro.copyWith(color: colors.muted, fontSize: 9),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 24,
          child: Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: colors.sky,
          ),
        ),
      ],
    );
  }
}

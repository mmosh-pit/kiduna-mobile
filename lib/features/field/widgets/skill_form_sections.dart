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

/// Shows auto-detected tool providers with connected/missing status.
class DetectedToolsInfo extends StatelessWidget {
  const DetectedToolsInfo({
    super.key,
    required this.detectedTools,
    required this.connectedTools,
    required this.missingTools,
  });

  /// Tool providers detected from when/then text (e.g., {'google', 'bluesky'}).
  final Set<String> detectedTools;

  /// Tool providers the user has connected in Empower.
  final Set<String> connectedTools;

  /// Tool providers detected but NOT connected.
  final List<String> missingTools;

  static const _toolColors = {
    'google': Color(0xFF34D399),
    'bluesky': Color(0xFF38BDF8),
    'telegram': Color(0xFF60A5FA),
    'solana': Color(0xFFA78BFA),
  };

  static const _toolNames = {
    'google': 'Google',
    'bluesky': 'Bluesky',
    'telegram': 'Telegram',
    'solana': 'Solana',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    if (detectedTools.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '🔧 Detected:',
              style: text.micro.copyWith(color: colors.muted, fontSize: 9),
            ),
            for (final tool in detectedTools)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: connectedTools.contains(tool)
                      ? (_toolColors[tool] ?? colors.sky).withValues(alpha: 0.1)
                      : const Color(0xFFEF4444).withValues(alpha: 0.1),
                  border: Border.all(
                    color: connectedTools.contains(tool)
                        ? (_toolColors[tool] ?? colors.sky).withValues(alpha: 0.3)
                        : const Color(0xFFEF4444).withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  connectedTools.contains(tool)
                      ? '${_toolNames[tool] ?? tool} ✓'
                      : '${_toolNames[tool] ?? tool} ✗',
                  style: text.micro.copyWith(
                    color: connectedTools.contains(tool)
                        ? (_toolColors[tool] ?? colors.sky)
                        : const Color(0xFFEF4444),
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        if (missingTools.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Please connect ${missingTools.map((t) => _toolNames[t] ?? t).join(', ')} in Empower section',
            style: text.micro.copyWith(
              color: const Color(0xFFEF4444),
              fontSize: 9,
            ),
          ),
        ],
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

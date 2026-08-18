import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// Colour-coded category chip for a scene.
///
/// * productivity → sky
/// * game         → gold
/// * wellness     → mint
/// * finance      → camel
/// * lifestyle    → quiet
class SceneCategoryBadge extends StatelessWidget {
  const SceneCategoryBadge({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final (bg, fg) = _resolve(colors);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Text(
        _label,
        style: context.kidunaText.micro.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  String get _label {
    switch (category) {
      case 'productivity': return 'Productivity';
      case 'game':         return 'Game';
      case 'wellness':     return 'Wellness';
      case 'finance':      return 'Finance';
      case 'lifestyle':    return 'Lifestyle';
      default:             return category;
    }
  }

  (Color bg, Color fg) _resolve(dynamic colors) {
    switch (category) {
      case 'productivity':
        return (colors.sky.withValues(alpha: 0.12), colors.sky);
      case 'game':
        return (colors.gold.withValues(alpha: 0.12), colors.gold);
      case 'wellness':
        return (colors.mint.withValues(alpha: 0.12), colors.mint);
      case 'finance':
        return (colors.camel.withValues(alpha: 0.12), colors.camel);
      case 'lifestyle':
        return (colors.quiet.withValues(alpha: 0.15), colors.quiet);
      default:
        return (colors.muted.withValues(alpha: 0.12), colors.muted);
    }
  }
}

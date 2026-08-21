import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';

/// Placeholder shown for sections that have no content yet.
///
/// Displays the section name and a "Coming Soon" subtitle, centred in the
/// available space. Uses Kiduna design tokens for consistent styling.
class SectionPlaceholder extends StatelessWidget {
  const SectionPlaceholder({super.key, required this.sectionName});

  final String sectionName;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.construction_rounded,
            size: 48,
            color: colors.muted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            sectionName,
            style: context.kidunaText.heading.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: context.kidunaText.bodySm.copyWith(color: colors.quiet),
          ),
        ],
      ),
    );
  }
}

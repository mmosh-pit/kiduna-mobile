import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';
import '../models/section_item.dart';

/// Header-matching dark background for the section bar.
const Color _sectionBarBg = Color.fromRGBO(18, 12, 7, 0.97);

/// Horizontal scrollable section bar — sits between AppHeader and section
/// content. Active section shows a sky-coloured label with a bottom indicator;
/// inactive sections are muted.
///
/// Fully reusable: pass any `List<SectionItem>`, an `activeIndex`, and an
/// `onChanged` callback.
class SectionBar extends StatelessWidget {
  const SectionBar({
    super.key,
    required this.sections,
    required this.activeIndex,
    required this.onChanged,
  });

  final List<SectionItem> sections;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        color: _sectionBarBg,
        border: Border(
          bottom: BorderSide(
            color: colors.camel.withValues(alpha: 0.28),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 24),
        child: Row(
          children: [
            for (int i = 0; i < sections.length; i++)
              _SectionTab(
                label: sections[i].label,
                isActive: i == activeIndex,
                onTap: () => onChanged(i),
              ),
          ],
        ),
      ),
    );
  }
}

/// Individual section tab with active indicator.
class _SectionTab extends StatelessWidget {
  const _SectionTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final textStyle = context.kidunaText.label;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Text(
              label,
              style: textStyle.copyWith(
                color: isActive ? colors.sky : colors.muted,
              ),
            ),
            const Spacer(),
            // Active indicator — 2px sky line at bottom
            Container(
              height: 2,
              width: label.length * 8.0 + 16, // proportional to text
              decoration: BoxDecoration(
                color: isActive ? colors.sky : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

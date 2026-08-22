import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../data/realm_atlas.dart';

class NavigationPanel extends StatelessWidget {
  const NavigationPanel({
    super.key,
    required this.realmPath,
    this.realmNames = const {},
    this.onBreadcrumbTap,
  });

  final List<String> realmPath;
  final Map<String, String> realmNames;
  final ValueChanged<int>? onBreadcrumbTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
      child: Semantics(
        label: context.l10n.realmBreadcrumb,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < realmPath.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '›',
                      style: context.kidunaText.bodySmall.copyWith(
                        color: colors.quiet,
                      ),
                    ),
                  ),
                _BreadcrumbChip(
                  label: realmAtlas[realmPath[i]]?.name ?? realmNames[realmPath[i]] ?? realmPath[i],
                  isCurrent: i == realmPath.length - 1,
                  onTap: onBreadcrumbTap != null && i < realmPath.length - 1
                      ? () => onBreadcrumbTap!(i)
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BreadcrumbChip extends StatelessWidget {
  const _BreadcrumbChip({
    required this.label,
    required this.isCurrent,
    this.onTap,
  });

  final String label;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Semantics(
      button: onTap != null,
      label: onTap != null ? context.l10n.navigateToRealm(label) : label,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isCurrent
                  ? colors.raised.withValues(alpha: 0.5)
                  : colors.raised.withValues(alpha: 0.25),
              border: Border.all(
                color: isCurrent
                    ? colors.camel.withValues(alpha: 0.24)
                    : colors.camel.withValues(alpha: 0.14),
              ),
              borderRadius: BorderRadius.circular(context.metrics.radiusSm),
            ),
            child: Text(
              label,
              style: context.kidunaText.bodySmall.copyWith(
                color: isCurrent ? colors.cream : colors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

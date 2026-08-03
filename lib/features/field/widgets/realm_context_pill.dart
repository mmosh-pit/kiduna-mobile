import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/field_realm.dart';
import 'enamel_icon.dart';

/// The realm-context pill anchored top-left of the Field: the current Realm's
/// enamel emblem, its type eyebrow and name, and the Inspect toggle.
class RealmContextPill extends StatelessWidget {
  const RealmContextPill({
    super.key,
    required this.realm,
    required this.inspectOpen,
    required this.onInspect,
    this.width,
    this.viewToggle,
  });

  final FieldRealm realm;
  final bool inspectOpen;
  final VoidCallback onInspect;

  /// Fixed pill width; when null the pill sizes to its content.
  final double? width;

  /// Optional control shown before Inspect (the AEV Atlas/Scene toggle).
  final Widget? viewToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.fromLTRB(0, 6, 7, 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.raised.withValues(alpha: 0.86),
            colors.field.withValues(alpha: 0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(context.metrics.radiusPill),
        border: Border.all(color: colors.camel.withValues(alpha: 0.28)),
        boxShadow: context.shadows.realmPill,
      ),
      child: Row(
        children: [
          EnamelIcon(
            kind: EnamelKind.ecosystem,
            size: context.metrics.enamelIcon,
            emblemAsset: realm.emblemAsset,
            fallbackInitial: realm.name.isNotEmpty
                ? realm.name.characters.first
                : null,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  realm.type.toUpperCase(),
                  style: text.eyebrow.copyWith(
                    color: colors.sky,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  realm.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.heading.copyWith(color: colors.cream),
                ),
              ],
            ),
          ),
          if (viewToggle != null) ...[const SizedBox(width: 13), viewToggle!],
          const SizedBox(width: 13),
          _InspectButton(active: inspectOpen, onTap: onInspect),
        ],
      ),
    );
  }
}

class _InspectButton extends StatelessWidget {
  const _InspectButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final tint = active ? colors.sky : colors.cream;
    return Semantics(
      button: true,
      expanded: active,
      label: context.l10n.inspect,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(Icons.remove_red_eye_outlined, size: 16, color: tint),
        label: Text(
          context.l10n.inspect,
          style: context.kidunaText.bodySmall.copyWith(color: tint),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          side: BorderSide(
            color: active
                ? colors.sky.withValues(alpha: 0.42)
                : colors.camel.withValues(alpha: 0.28),
          ),
          shape: const StadiumBorder(),
          backgroundColor: active
              ? colors.sky.withValues(alpha: 0.06)
              : colors.cream.withValues(alpha: 0.035),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../session/lobby_client.dart';

/// A player's court rank, shown beside their rating.
///
/// The colour climbs from muted earth through to gold, so relative standing
/// reads at a glance without having to compare the numbers.
class TierBadge extends StatelessWidget {
  const TierBadge({super.key, required this.tier, this.compact = false});

  final RatingTier tier;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = AppLocalizations.of(context)!;

    final (Color tint, String label) = switch (tier) {
      RatingTier.peasant => (colors.muted, l10n.tierPeasant),
      RatingTier.squire => (colors.camel, l10n.tierSquire),
      RatingTier.knight => (colors.sky, l10n.tierKnight),
      RatingTier.baron => (colors.mint, l10n.tierBaron),
      RatingTier.duke => (colors.orange, l10n.tierDuke),
      RatingTier.royal => (colors.gold, l10n.tierRoyal),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(color: tint.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: (compact ? text.micro : text.caption).copyWith(
          color: tint,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

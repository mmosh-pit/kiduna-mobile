import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../tournament_models.dart';

/// One tournament in the browse list.
class TournamentCard extends StatelessWidget {
  const TournamentCard({super.key, required this.tournament, this.onTap});

  final TournamentSummary tournament;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = AppLocalizations.of(context)!;

    final subtitle = switch (tournament.status) {
      TournamentStatus.registering => l10n.playersRegistered(
        tournament.registered,
        tournament.size,
      ),
      TournamentStatus.running => l10n.roundOfTotal(
        tournament.currentRound,
        tournament.totalRounds,
      ),
      _ => l10n.tournamentFinished,
    };

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.deep,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: tournament.isRegistered
                  ? colors.gold.withValues(alpha: 0.7)
                  : colors.camel.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              _SizeChip(size: tournament.size),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournament.name,
                      overflow: TextOverflow.ellipsis,
                      style: text.body.copyWith(
                        color: colors.cream,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: text.caption.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
              if (tournament.isRegistered)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: colors.mint,
                  ),
                ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.gold.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({required this.size});

  final int size;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.gold.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$size',
        style: text.body.copyWith(
          color: colors.gold,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

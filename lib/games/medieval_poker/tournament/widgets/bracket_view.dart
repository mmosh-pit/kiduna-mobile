import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../tournament_models.dart';

/// The bracket, laid out for the space available.
///
/// Wide viewports get rounds side by side, which is how a bracket is normally
/// read. Narrow ones stack the rounds vertically instead of shrinking the
/// cards past legibility — the same information, reflowed rather than cramped.
class BracketView extends StatelessWidget {
  const BracketView({
    super.key,
    required this.rounds,
    required this.viewerUserId,
    this.totalRounds,
    this.onEnterMatch,
  });

  final List<BracketRound> rounds;
  final String? viewerUserId;

  /// How many rounds the whole bracket has.
  ///
  /// Only the rounds that already exist are passed in [rounds] — the next one
  /// is not created until the current one finishes — so without this, round 1
  /// of a two-round bracket gets labelled "Final" purely for being the last
  /// one so far.
  final int? totalRounds;

  /// Called when the viewer taps their own live heat.
  final void Function(BracketMatch match)? onEnterMatch;

  /// Below this the side-by-side layout would squeeze the cards past reading
  /// size, so the rounds stack instead.
  static const double _sideBySideMinWidth = Breakpoints.tablet;

  @override
  Widget build(BuildContext context) {
    if (rounds.isEmpty) return const SizedBox.shrink();

    final lastRound = totalRounds ?? rounds.last.round;
    final columns = [
      for (final r in rounds)
        _RoundColumn(
          round: r,
          isFinal: r.round >= lastRound,
          viewerUserId: viewerUserId,
          onEnterMatch: onEnterMatch,
        ),
    ];

    // This sits inside a resizable panel, so it reflows on the space it
    // actually has rather than on the size of the window.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _sideBySideMinWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final c in columns)
                Padding(padding: const EdgeInsets.only(bottom: 24), child: c),
            ],
          );
        }

        // Rounds side by side, scrolling horizontally on their own so a deep
        // bracket never forces the whole page sideways.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final c in columns)
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: SizedBox(width: 260, child: c),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RoundColumn extends StatelessWidget {
  const _RoundColumn({
    required this.round,
    required this.isFinal,
    required this.viewerUserId,
    required this.onEnterMatch,
  });

  final BracketRound round;
  final bool isFinal;
  final String? viewerUserId;
  final void Function(BracketMatch match)? onEnterMatch;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isFinal ? l10n.finalLabel : l10n.roundLabel(round.round),
          style: text.eyebrow.copyWith(color: colors.gold),
        ),
        const SizedBox(height: 8),
        for (final m in round.matches)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MatchCard(
              match: m,
              viewerUserId: viewerUserId,
              onEnter: onEnterMatch,
            ),
          ),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.match,
    required this.viewerUserId,
    required this.onEnter,
  });

  final BracketMatch match;
  final String? viewerUserId;
  final void Function(BracketMatch match)? onEnter;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = AppLocalizations.of(context)!;

    final isMine = match.contains(viewerUserId);
    final canEnter =
        isMine && match.status == MatchStatus.active && onEnter != null;

    final statusLabel = switch (match.status) {
      MatchStatus.pending => l10n.awaitingPlayers,
      MatchStatus.active => l10n.matchInProgress,
      MatchStatus.finished => l10n.matchFinished,
    };

    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.deep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMine
              ? colors.gold.withValues(alpha: 0.8)
              : colors.camel.withValues(alpha: 0.3),
          width: isMine ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  statusLabel,
                  style: text.micro.copyWith(color: colors.muted),
                ),
              ),
              if (isMine)
                Text(
                  l10n.yourHeat,
                  style: text.micro.copyWith(
                    color: colors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (final p in match.players)
            _PlayerRow(
              player: p,
              isWinner:
                  match.winnerUserId != null && p.userId == match.winnerUserId,
              isViewer: p.userId != null && p.userId == viewerUserId,
            ),
          if (canEnter) ...[
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => onEnter!(match),
              style: FilledButton.styleFrom(
                backgroundColor: colors.gold,
                foregroundColor: colors.black,
                minimumSize: const Size.fromHeight(36),
              ),
              child: Text(l10n.enterYourTable),
            ),
          ],
        ],
      ),
    );

    if (!canEnter) return card;
    return MouseRegion(cursor: SystemMouseCursors.click, child: card);
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.isWinner,
    required this.isViewer,
  });

  final MatchPlayer player;
  final bool isWinner;
  final bool isViewer;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isWinner ? Icons.emoji_events_rounded : Icons.circle_outlined,
            size: 14,
            color: isWinner ? colors.gold : colors.muted.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              player.label,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall.copyWith(
                color: player.isAi
                    ? colors.muted
                    : (isWinner ? colors.gold : colors.cream),
                fontWeight: isViewer || isWinner
                    ? FontWeight.w700
                    : FontWeight.w400,
                fontStyle: player.isAi ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

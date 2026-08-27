import 'package:flutter/material.dart';

import '../../poker_palette.dart';
import '../tournament_models.dart';
import 'start_countdown.dart';

/// One tournament in the list.
///
/// The line under the name answers the only question that matters at a glance:
/// can I still get in, and when does it go? A scheduled tournament counts down;
/// everything else states where it got to.
class TournamentCard extends StatelessWidget {
  final TournamentSummary summary;

  /// Injected so the countdown renders deterministically in tests.
  final DateTime now;

  final VoidCallback? onTap;

  const TournamentCard({
    super.key,
    required this.summary,
    required this.now,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '${summary.name}, ${_semanticState()}',
      excludeSemantics: true,
      child: Material(
        color: kPokerPanel,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: summary.isRegistered ? kPokerGold : kPokerPanelBorder,
                width: summary.isRegistered ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        summary.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'GoudyHeavyface',
                          fontSize: 20,
                          color: kPokerGold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StateChip(summary: summary, now: now),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${summary.registered} of ${summary.capacity} entered',
                      style: const TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 13,
                        color: Colors.white60,
                      ),
                    ),
                    if (summary.isRegistered) ...[
                      const SizedBox(width: 10),
                      const Text(
                        'you are in',
                        style: TextStyle(
                          fontFamily: 'IBMPlexSans',
                          fontSize: 11,
                          color: kPokerGold,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (summary.isScheduled && !summary.hasQuorum)
                      const Text(
                        'needs more players',
                        style: TextStyle(
                          fontFamily: 'IBMPlexSans',
                          fontSize: 11,
                          color: kPokerDanger,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _semanticState() => switch (summary.status) {
    TournamentStatus.scheduled =>
      'starts in ${formatCountdown(summary.timeUntilStart(now))}, '
          '${summary.registered} of ${summary.capacity} entered',
    TournamentStatus.running => 'under way',
    TournamentStatus.finished => 'finished',
    TournamentStatus.cancelled => 'cancelled',
  };
}

class _StateChip extends StatelessWidget {
  final TournamentSummary summary;
  final DateTime now;
  const _StateChip({required this.summary, required this.now});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (summary.status) {
      TournamentStatus.scheduled => (
        _startLabel(),
        summary.hasQuorum ? kPokerGold : kPokerMuted,
      ),
      TournamentStatus.running => ('playing', kPokerLive),
      TournamentStatus.finished => ('finished', kPokerMuted),
      TournamentStatus.cancelled => ('cancelled', kPokerDanger),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'IBMPlexSans',
          fontSize: 11,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  String _startLabel() {
    final left = summary.timeUntilStart(now);
    // Past its time but not yet flipped to running — the server is seating it.
    if (left.isNegative) return 'starting';
    return formatCountdown(left);
  }
}

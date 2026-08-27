import 'package:flutter/material.dart';

import '../../poker_palette.dart';
import '../tournament_models.dart';

/// Time until the clock fires.
///
/// A tournament starts on a schedule, not when the field fills — so a full
/// tournament still waits, and a nearly empty one still starts. This says which
/// is about to happen, and warns when the field is short.
class StartCountdown extends StatelessWidget {
  final TournamentSummary summary;

  /// Injected so this renders deterministically in tests and goldens.
  final DateTime now;

  const StartCountdown({super.key, required this.summary, required this.now});

  @override
  Widget build(BuildContext context) {
    final left = summary.timeUntilStart(now);
    final overdue = left.isNegative;

    return Column(
      children: [
        Text(
          overdue ? 'STARTING' : 'STARTS IN',
          style: const TextStyle(
            fontFamily: 'IBMPlexSans',
            fontSize: 11,
            letterSpacing: 2.2,
            color: kPokerMuted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          overdue ? '—' : formatCountdown(left),
          style: const TextStyle(
            fontFamily: 'IBMPlexSans',
            fontSize: 40,
            height: 1.0,
            fontWeight: FontWeight.w500,
            color: kPokerGold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 10),
        _FieldLine(summary: summary),
      ],
    );
  }
}

/// `1:04:09`, `4:09`, or `0:09` — the largest unit present, no padding on it.
String formatCountdown(Duration d) {
  if (d.isNegative) return '0:00';
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
  return '$m:$ss';
}

class _FieldLine extends StatelessWidget {
  final TournamentSummary summary;
  const _FieldLine({required this.summary});

  @override
  Widget build(BuildContext context) {
    final short = !summary.hasQuorum;
    return Column(
      children: [
        Text(
          '${summary.registered} of ${summary.capacity} entered',
          style: const TextStyle(
            fontFamily: 'Avenir',
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        if (short) ...[
          const SizedBox(height: 6),
          Text(
            'Needs ${summary.minEntrants} to run',
            style: const TextStyle(
              fontFamily: 'Avenir',
              fontSize: 12.5,
              color: kPokerDanger,
            ),
          ),
        ] else if (summary.isFull) ...[
          const SizedBox(height: 6),
          const Text(
            'Field is full — it still starts on the clock',
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 12.5,
              color: kPokerMuted,
            ),
          ),
        ],
      ],
    );
  }
}

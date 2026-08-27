import 'package:flutter/material.dart';

import '../../poker_palette.dart';
import '../tournament_models.dart';

/// The bracket as it actually is, round by round.
///
/// Deliberately not a tree. The shape is not known until the clock fires — a
/// sixteen-player sign-up can open as one heads-up table — so drawing a fixed
/// tree of empty slots would promise rounds that may never exist. Rounds appear
/// as they are seated.
class BracketView extends StatelessWidget {
  final TournamentDetail tournament;

  /// Marks the viewer's own rows and their current table.
  final String viewerId;

  /// Tapped when the viewer's table is playable.
  final void Function(TableView table)? onEnterTable;

  const BracketView({
    super.key,
    required this.tournament,
    required this.viewerId,
    this.onEnterTable,
  });

  @override
  Widget build(BuildContext context) {
    if (tournament.rounds.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final round in tournament.rounds) ...[
          _RoundHeader(round: round),
          const SizedBox(height: 8),
          for (final table in round.tables)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TableCard(
                table: table,
                seatsPerTable: tournament.seatsPerTable,
                viewerId: viewerId,
                onEnter: onEnterTable,
              ),
            ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _RoundHeader extends StatelessWidget {
  final RoundView round;
  const _RoundHeader({required this.round});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          round.label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'IBMPlexSans',
            fontSize: 11,
            letterSpacing: 2.0,
            color: kPokerMuted,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: const Color(0x336B5533))),
        const SizedBox(width: 10),
        Text(
          '${round.tables.length} ${round.tables.length == 1 ? "table" : "tables"}',
          style: const TextStyle(
            fontFamily: 'IBMPlexSans',
            fontSize: 11,
            color: Colors.white38,
          ),
        ),
      ],
    );
  }
}

class _TableCard extends StatelessWidget {
  final TableView table;
  final int seatsPerTable;
  final String viewerId;
  final void Function(TableView table)? onEnter;

  const _TableCard({
    required this.table,
    required this.seatsPerTable,
    required this.viewerId,
    this.onEnter,
  });

  bool get _hasViewer => table.includes(viewerId);
  bool get _playable =>
      _hasViewer && table.status == TableStatus.active && onEnter != null;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _hasViewer ? const Color(0x14EDC169) : kPokerPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasViewer ? kPokerGold : kPokerPanelBorder,
          width: _hasViewer ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Table ${table.index + 1}',
                style: const TextStyle(
                  fontFamily: 'Avenir',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              if (table.isShortHanded(seatsPerTable))
                const _Chip(label: 'short-handed', color: kPokerMuted),
              const Spacer(),
              _StatusChip(status: table.status),
            ],
          ),
          const SizedBox(height: 10),
          for (final p in table.players)
            _SeatRow(
              player: p,
              isViewer: p.userId == viewerId,
              isWinner: p.userId == table.winnerUserId,
            ),
          if (_playable) ...[
            const SizedBox(height: 10),
            _EnterButton(onTap: () => onEnter!(table)),
          ],
        ],
      ),
    );

    return Semantics(
      label:
          'Table ${table.index + 1}, ${table.seats} players, '
          '${table.status.name}${_hasViewer ? ", you are seated here" : ""}',
      child: card,
    );
  }
}

class _SeatRow extends StatelessWidget {
  final EntrantView player;
  final bool isViewer;
  final bool isWinner;

  const _SeatRow({
    required this.player,
    required this.isViewer,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // Drawn rather than a Unicode glyph: the brand fonts do not carry
          // the diamond, so a text marker falls back inconsistently.
          SizedBox(
            width: 16,
            child: Center(
              child: isWinner
                  ? Transform.rotate(
                      angle: 0.785398, // 45 degrees
                      child: Container(width: 7, height: 7, color: kPokerGold),
                    )
                  : Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
          ),
          Expanded(
            child: Text(
              isViewer ? 'You' : player.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: 13,
                fontWeight: isViewer || isWinner
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: isWinner
                    ? kPokerGold
                    : (isViewer ? Colors.white : Colors.white70),
              ),
            ),
          ),
          if (player.finalRank != null)
            Text(
              '#${player.finalRank}',
              style: const TextStyle(
                fontFamily: 'IBMPlexSans',
                fontSize: 11,
                color: Colors.white38,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TableStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) => switch (status) {
    TableStatus.pending => const _Chip(label: 'seated', color: Colors.white38),
    TableStatus.active => const _Chip(label: 'playing', color: kPokerLive),
    TableStatus.finished => const _Chip(label: 'done', color: kPokerMuted),
  };
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'IBMPlexSans',
          fontSize: 9.5,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}

class _EnterButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EnterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: kPokerGold,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Take your seat',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Avenir',
                fontWeight: FontWeight.w800,
                color: kPokerInk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../poker_palette.dart';
import 'game_session.dart';

const _gold = kPokerGold;
const _ink = kPokerInk;
const _panel = kPokerPanel;
const _panelBorder = kPokerPanelBorder;
const _defeat = kPokerDanger;

const _maxWidth = 560.0;

/// The end-of-table standings.
///
/// Replaces the flat "name · chips" list the game-over overlay used to show.
/// Every row carries a finishing place, because busted players all end on or
/// near zero chips — chip count alone cannot separate third from fourth. The
/// rank comes from the engine's elimination order (see `PokerGame.finalStandings`).
///
/// Renders inside the HUD stack rather than as a pushed route, matching how
/// every other overlay in this game works.
class StandingsScreen extends StatelessWidget {
  /// The finished table, best finish first.
  final GameOverView view;

  /// Which seat is looking at this, so their row can be marked.
  final int viewerSeat;

  final VoidCallback onExit;

  /// Offline only — restart the match. Null online.
  final VoidCallback? onPlayAgain;

  /// Tournament only — move on to the next round. Null when there is nowhere
  /// to go (knocked out, or this was the final table).
  final VoidCallback? onContinue;

  const StandingsScreen({
    super.key,
    required this.view,
    required this.viewerSeat,
    required this.onExit,
    this.onPlayAgain,
    this.onContinue,
  });

  TournamentOutcomeView? get _tournament => view.tournament;

  /// Headline: champion beats a plain table win, which beats going out.
  String get _title {
    final t = _tournament;
    if (t != null) {
      if (t.isChampion) return 'Champion';
      return t.advanced ? 'You advance' : 'Knocked out';
    }
    return view.youWon ? 'Victory' : 'Defeat';
  }

  Color get _titleColor {
    final t = _tournament;
    if (t != null) return t.isChampion || t.advanced ? _gold : _defeat;
    return view.youWon ? _gold : _defeat;
  }

  @override
  Widget build(BuildContext context) {
    final t = _tournament;

    return Container(
      color: Colors.black.withValues(alpha: 0.86),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (t != null) _RoundEyebrow(label: t.roundLabel),
                  Text(
                    _title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'GoudyHeavyface',
                      fontSize: 38,
                      height: 1.1,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    view.detail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Avenir',
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Flexible(
                    child: _StandingsList(
                      rows: view.standings,
                      viewerSeat: viewerSeat,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _Actions(
                    onExit: onExit,
                    onPlayAgain: onPlayAgain,
                    onContinue: onContinue,
                    continueLabel: t?.nextRoundLabel,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Round 1" above the headline, so a tournament table says where it sat.
class _RoundEyebrow extends StatelessWidget {
  final String label;
  const _RoundEyebrow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'IBMPlexSans',
          fontSize: 11,
          letterSpacing: 2.2,
          color: Color(0xFF9C8459),
        ),
      ),
    );
  }
}

class _StandingsList extends StatelessWidget {
  final List<StandingView> rows;
  final int viewerSeat;
  const _StandingsList({required this.rows, required this.viewerSeat});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _panelBorder, width: 1.5),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: rows.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, thickness: 1, color: Color(0x226B5533)),
        itemBuilder: (context, i) {
          final row = rows[i];
          // Servers predating ranking send ordered rows with no rank.
          final place = row.rank > 0 ? row.rank : i + 1;
          return _StandingRow(
            row: row,
            place: place,
            isViewer: row.seat == viewerSeat,
          );
        },
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  final StandingView row;
  final int place;
  final bool isViewer;
  const _StandingRow({
    required this.row,
    required this.place,
    required this.isViewer,
  });

  /// Out on a known hand, or played to the finish.
  String get _status {
    if (row.survived) return 'still standing';
    return 'out on hand ${row.eliminatedAtHand}';
  }

  @override
  Widget build(BuildContext context) {
    final isChampion = place == 1;
    final name = isViewer ? 'You' : row.label;

    return Semantics(
      label: '$name, place $place, ${row.stack} chips, $_status',
      excludeSemantics: true,
      child: Container(
        color: isViewer ? const Color(0x1AEDC169) : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            _PlaceBadge(place: place, isChampion: isChampion),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 15,
                      fontWeight: isViewer || isChampion
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isChampion ? _gold : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _status,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexSans',
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${row.stack}',
              style: TextStyle(
                fontFamily: 'IBMPlexSans',
                fontSize: 16,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: isChampion ? _gold : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The finishing place. Gold and filled for the winner, outlined for everyone
/// else — the one row that reads differently at a glance.
class _PlaceBadge extends StatelessWidget {
  final int place;
  final bool isChampion;
  const _PlaceBadge({required this.place, required this.isChampion});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isChampion ? _gold : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isChampion ? _gold : _panelBorder,
          width: 1.5,
        ),
      ),
      child: Text(
        '$place',
        style: TextStyle(
          fontFamily: 'IBMPlexSans',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isChampion ? _ink : Colors.white60,
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final VoidCallback onExit;
  final VoidCallback? onPlayAgain;
  final VoidCallback? onContinue;
  final String? continueLabel;

  const _Actions({
    required this.onExit,
    this.onPlayAgain,
    this.onContinue,
    this.continueLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Advancing outranks replaying: in a tournament there is no "again".
    final primary = onContinue != null
        ? _PrimaryButton(
            label: continueLabel == null
                ? 'Continue'
                : 'Continue to $continueLabel',
            onTap: onContinue!,
          )
        : onPlayAgain != null
        ? _PrimaryButton(label: 'Play Again', onTap: onPlayAgain!)
        : null;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        ?primary,
        _GhostButton(label: 'Leave', onTap: onExit),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _gold,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Avenir',
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GhostButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _panelBorder),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Avenir',
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

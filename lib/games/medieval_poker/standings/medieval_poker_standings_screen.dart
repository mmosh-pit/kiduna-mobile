import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../l10n/app_localizations.dart';
import '../medieval_poker_leaderboard_screen.dart';
import '../tournament/tournament_client.dart';
import '../tournament/tournament_models.dart';

/// Standings — where a player finds out where they placed.
///
/// Two boards under one roof. **Leaderboard** is the standing global picture
/// (rating and wins, across every rated game). **Tournaments** is the settled
/// history: every bracket that has actually finished, and who took the crown.
///
/// They live together because they answer the same question at two time
/// scales, and splitting them across the mode selector made the leaderboard
/// look like the only kind of ranking the game has.
enum StandingsTab { leaderboard, tournaments }

class MedievalPokerStandingsScreen extends StatefulWidget {
  const MedievalPokerStandingsScreen({
    super.key,
    this.viewerUserId,
    this.initialTab = StandingsTab.leaderboard,
    this.tournamentClient,
  });

  /// The signed-in player, used to highlight their row on both boards.
  final String? viewerUserId;

  final StandingsTab initialTab;

  /// Injected in tests; defaults to the real REST client.
  final TournamentClient? tournamentClient;

  @override
  State<MedievalPokerStandingsScreen> createState() =>
      _MedievalPokerStandingsScreenState();
}

class _MedievalPokerStandingsScreenState
    extends State<MedievalPokerStandingsScreen> {
  late StandingsTab _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: colors.field,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SegmentedButton<StandingsTab>(
              key: const Key('standings-tabs'),
              segments: [
                ButtonSegment(
                  value: StandingsTab.leaderboard,
                  label: Text(l10n.standingsLeaderboardTab),
                ),
                ButtonSegment(
                  value: StandingsTab.tournaments,
                  label: Text(l10n.standingsTournamentsTab),
                ),
              ],
              selected: {_tab},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
          Expanded(
            child: switch (_tab) {
              StandingsTab.leaderboard => MedievalPokerLeaderboardScreen(
                key: const Key('standings-leaderboard'),
                viewerUserId: widget.viewerUserId,
              ),
              StandingsTab.tournaments => _TournamentStandings(
                key: const Key('standings-tournaments'),
                viewerUserId: widget.viewerUserId,
                client: widget.tournamentClient,
              ),
            },
          ),
        ],
      ),
    );
  }
}

/// Finished brackets, newest first, each with its final order.
///
/// The list endpoint only carries `championUserId`, so the placings come from
/// a detail call per tournament. Those are issued together rather than in
/// sequence, and the list is capped, so the tab costs one round trip plus a
/// bounded fan-out instead of growing with the tournament history.
class _TournamentStandings extends StatefulWidget {
  const _TournamentStandings({super.key, this.viewerUserId, this.client});

  final String? viewerUserId;
  final TournamentClient? client;

  @override
  State<_TournamentStandings> createState() => _TournamentStandingsState();
}

class _TournamentStandingsState extends State<_TournamentStandings> {
  /// How many finished tournaments to resolve placings for.
  static const int _maxDetailed = 10;

  late final TournamentClient _client = widget.client ?? TournamentClient();

  List<TournamentDetail> _finished = const [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summaries = await _client.list(
        status: 'finished',
        limit: _maxDetailed,
      );
      final details = await Future.wait(
        summaries.take(_maxDetailed).map((s) async {
          try {
            return await _client.detail(s.id);
          } catch (_) {
            return null;
          }
        }),
      );
      if (!mounted) return;
      setState(() {
        _finished = details.whereType<TournamentDetail>().toList();
        _loading = false;
      });
    } on TournamentException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: colors.gold));
    }

    if (_error != null) {
      return _Empty(
        icon: Icons.error_outline_rounded,
        title: l10n.couldNotLoadTournaments,
        detail: _error!,
        onRetry: _load,
      );
    }

    if (_finished.isEmpty) {
      return _Empty(
        key: const Key('standings-tournaments-empty'),
        icon: Icons.emoji_events_outlined,
        title: l10n.noFinishedTournaments,
        detail: l10n.noFinishedTournamentsDetail,
        onRetry: _load,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: colors.gold,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _finished.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _FinishedTournamentCard(
          detail: _finished[i],
          viewerUserId: widget.viewerUserId,
          championLabel: l10n.tournamentChampion,
          text: text,
          colors: colors,
        ),
      ),
    );
  }
}

class _FinishedTournamentCard extends StatelessWidget {
  const _FinishedTournamentCard({
    required this.detail,
    required this.viewerUserId,
    required this.championLabel,
    required this.text,
    required this.colors,
  });

  final TournamentDetail detail;
  final String? viewerUserId;
  final String championLabel;
  final dynamic text;
  final dynamic colors;

  /// Final order: anyone with a `finalRank` first and in rank order, then the
  /// rest by how late they were knocked out. A bracket that finished without
  /// writing ranks still reads as a standings table rather than a jumble.
  List<Entrant> get _placed {
    final ranked = detail.entrants.where((e) => e.finalRank != null).toList()
      ..sort((a, b) => a.finalRank!.compareTo(b.finalRank!));
    final rest = detail.entrants.where((e) => e.finalRank == null).toList()
      ..sort((a, b) => (b.eliminatedRound ?? 0).compareTo(a.eliminatedRound ?? 0));
    return [...ranked, ...rest];
  }

  @override
  Widget build(BuildContext context) {
    final placed = _placed;

    return Container(
      decoration: BoxDecoration(
        color: colors.deep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.gold.withValues(alpha: 0.18)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  detail.tournament.name,
                  style: text.h5.copyWith(color: colors.gold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${detail.tournament.size} players',
                style: text.micro.copyWith(
                  color: colors.gold.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < placed.length; i++)
            _PlacingRow(
              position: i + 1,
              entrant: placed[i],
              isViewer: placed[i].userId == viewerUserId,
              isChampion: i == 0,
              championLabel: championLabel,
              text: text,
              colors: colors,
            ),
        ],
      ),
    );
  }
}

class _PlacingRow extends StatelessWidget {
  const _PlacingRow({
    required this.position,
    required this.entrant,
    required this.isViewer,
    required this.isChampion,
    required this.championLabel,
    required this.text,
    required this.colors,
  });

  final int position;
  final Entrant entrant;
  final bool isViewer;
  final bool isChampion;
  final String championLabel;
  final dynamic text;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    final name = entrant.username ?? entrant.name ?? '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$position',
              style: text.bodySmall.copyWith(
                color: colors.gold.withValues(alpha: isChampion ? 1 : 0.5),
                fontWeight: isChampion ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          if (isChampion) ...[
            Icon(Icons.emoji_events_rounded, size: 15, color: colors.gold),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              name,
              style: text.body.copyWith(
                color: isViewer ? colors.mint : colors.cream,
                fontWeight: isViewer ? FontWeight.w700 : FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isChampion)
            Text(
              championLabel,
              style: text.micro.copyWith(color: colors.gold),
            ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: colors.gold.withValues(alpha: 0.4)),
            const SizedBox(height: 14),
            Text(
              title,
              style: text.h5.copyWith(color: colors.gold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              style: text.caption.copyWith(
                color: colors.gold.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';
import '../../l10n/app_localizations.dart';
import 'session/lobby_client.dart';
import 'tournament/widgets/tier_badge.dart';

/// Results and standings.
///
/// Two boards: **rating** (skill, ELO) and **wins** (raw count). Rating is the
/// default because a win count rewards volume — and only games with at least
/// two humans are rated at all, so nobody climbs by beating AI.
class MedievalPokerLeaderboardScreen extends StatefulWidget {
  const MedievalPokerLeaderboardScreen({
    super.key,
    this.viewerUserId,
    this.client,
  });

  /// The signed-in player, used to highlight their row.
  final String? viewerUserId;

  /// Injected in tests; defaults to the real REST client.
  final LobbyClient? client;

  @override
  State<MedievalPokerLeaderboardScreen> createState() =>
      _MedievalPokerLeaderboardScreenState();
}

class _MedievalPokerLeaderboardScreenState
    extends State<MedievalPokerLeaderboardScreen> {
  late final LobbyClient _lobby = widget.client ?? LobbyClient();

  LeaderboardBoard _board = LeaderboardBoard.rating;
  LeaderboardSeason _season = LeaderboardSeason.allTime;

  LeaderboardPage? _page;
  PlayerRating? _myRating;
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
      // One round trip each; the rating card is worth showing even when the
      // player is nowhere near the visible page.
      final page = await _lobby.leaderboard(board: _board, season: _season);
      final rating = await _lobby.myRating(season: _season);
      if (!mounted) return;
      setState(() {
        _page = page;
        _myRating = rating;
        _loading = false;
      });
    } on LobbyException catch (e) {
      if (!mounted) return;
      setState(() {
        // Previously any failure fell through to an empty list, so a backend
        // that wasn't serving these routes looked exactly like "nobody has
        // played yet". Say which it is.
        _error = e.message;
        _page = null;
        _myRating = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: colors.field,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.leaderboardLabel,
                      style: text.h4.copyWith(color: colors.gold),
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _load,
                    icon: Icon(Icons.refresh_rounded, color: colors.gold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _Filters(
                board: _board,
                season: _season,
                onBoard: (b) {
                  setState(() => _board = b);
                  _load();
                },
                onSeason: (s) {
                  setState(() => _season = s);
                  _load();
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final colors = context.kiduna;
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: colors.gold));
    }
    if (_error != null) {
      return _ErrorState(
        message: l10n.couldNotLoadLeaderboard,
        detail: _error!,
        onRetry: _load,
      );
    }

    final page = _page;
    final rating = _myRating;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        if (rating != null) _RatingCard(rating: rating),
        const SizedBox(height: 24),
        if (page == null || page.isEmpty)
          _EmptyBoard()
        else ...[
          for (final e in page.entries)
            _Row(
              entry: e,
              board: _board,
              isViewer: e.userId == widget.viewerUserId,
            ),
          // The caller's own row, pinned when they fall outside the page — a
          // board you can't find yourself on isn't much use.
          if (page.me != null &&
              !page.entries.any((e) => e.userId == page.me!.userId)) ...[
            const SizedBox(height: 16),
            Text(
              l10n.yourRank,
              style: context.kidunaText.eyebrow.copyWith(color: colors.gold),
            ),
            const SizedBox(height: 8),
            _Row(entry: page.me!, board: _board, isViewer: true),
          ],
        ],
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.board,
    required this.season,
    required this.onBoard,
    required this.onSeason,
  });

  final LeaderboardBoard board;
  final LeaderboardSeason season;
  final ValueChanged<LeaderboardBoard> onBoard;
  final ValueChanged<LeaderboardSeason> onSeason;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Two selectors sit side by side when there is room and stack when there
    // isn't, rather than shrinking into unreadable chips.
    return LayoutBuilder(
      builder: (context, constraints) {
        final boards = SegmentedButton<LeaderboardBoard>(
          segments: [
            ButtonSegment(
              value: LeaderboardBoard.rating,
              label: Text(l10n.ratingBoard),
            ),
            ButtonSegment(
              value: LeaderboardBoard.wins,
              label: Text(l10n.winsBoard),
            ),
          ],
          selected: {board},
          showSelectedIcon: false,
          onSelectionChanged: (s) => onBoard(s.first),
        );
        final seasons = SegmentedButton<LeaderboardSeason>(
          segments: [
            ButtonSegment(
              value: LeaderboardSeason.current,
              label: Text(l10n.currentSeason),
            ),
            ButtonSegment(
              value: LeaderboardSeason.allTime,
              label: Text(l10n.allTime),
            ),
          ],
          selected: {season},
          showSelectedIcon: false,
          onSelectionChanged: (s) => onSeason(s.first),
        );

        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [boards, const SizedBox(height: 8), seasons],
          );
        }
        return Row(
          children: [
            Expanded(child: boards),
            const SizedBox(width: 12),
            Expanded(child: seasons),
          ],
        );
      },
    );
  }
}

/// The viewer's own standing, shown above the board.
class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.rating});

  final PlayerRating rating;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.deep,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.camel.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${rating.rating}',
                    style: text.display.copyWith(
                      color: colors.gold,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rating.isRanked ? '#${rating.rank}' : l10n.unranked,
                    style: text.caption.copyWith(color: colors.muted),
                  ),
                ],
              ),
              const Spacer(),
              TierBadge(tier: rating.tier),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(label: l10n.ratedGames, value: '${rating.games}'),
              _Stat(label: l10n.winsBoard, value: '${rating.wins}'),
              _Stat(label: l10n.winRateLabel, value: '${rating.winRate}%'),
              _Stat(label: l10n.peakRatingLabel, value: '${rating.peakRating}'),
            ],
          ),
          if (rating.recentDeltas.isNotEmpty) ...[
            const SizedBox(height: 16),
            _RecentForm(deltas: rating.recentDeltas),
          ],
        ],
      ),
    );
  }
}

/// The last few rating swings, newest on the left.
class _RecentForm extends StatelessWidget {
  const _RecentForm({required this.deltas});

  final List<int> deltas;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final d in deltas.take(8))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (d >= 0 ? colors.mint : colors.error).withValues(
                alpha: 0.14,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              d >= 0 ? '+$d' : '$d',
              style: text.micro.copyWith(
                color: d >= 0 ? colors.mint : colors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Column(
      children: [
        Text(
          value,
          style: text.h5.copyWith(
            color: colors.cream,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: text.micro.copyWith(color: colors.muted)),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.entry,
    required this.board,
    required this.isViewer,
  });

  final LeaderboardEntry entry;
  final LeaderboardBoard board;
  final bool isViewer;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    final isPodium = entry.rank > 0 && entry.rank <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colors.deep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isViewer
              ? colors.gold.withValues(alpha: 0.8)
              : (isPodium
                    ? colors.gold.withValues(alpha: 0.4)
                    : colors.camel.withValues(alpha: 0.25)),
          width: isViewer ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${entry.rank}',
              style: text.body.copyWith(
                color: isPodium ? colors.gold : colors.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall.copyWith(
                    color: colors.cream,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.games}G · ${entry.wins}W · ${entry.winRate}%',
                  style: text.micro.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
          if (board == LeaderboardBoard.rating) ...[
            TierBadge(tier: entry.tier, compact: true),
            const SizedBox(width: 8),
            Text(
              '${entry.rating}',
              style: text.body.copyWith(
                color: colors.gold,
                fontWeight: FontWeight.w800,
              ),
            ),
          ] else
            Text(
              '${entry.wins}',
              style: text.body.copyWith(
                color: colors.mint,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyBoard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 44,
            color: colors.gold.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noRankedGamesYet,
            style: text.body.copyWith(color: colors.cream),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noRankedGamesYetDetail,
            textAlign: TextAlign.center,
            style: text.caption.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  final String message;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: colors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: text.body.copyWith(color: colors.cream),
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: text.caption.copyWith(color: colors.muted),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: colors.gold,
                foregroundColor: colors.black,
              ),
              child: Text(l10n.retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../l10n/app_localizations.dart';
import '../medieval_poker_online_screen.dart';
import 'tournament_client.dart';
import 'tournament_models.dart';
import 'widgets/bracket_view.dart';

/// One tournament: register or withdraw, watch the bracket, and drop into your
/// heat when it starts.
///
/// Polls while the tournament is live — a round advances the moment the last
/// heat finishes, which can happen while this screen is open and has no other
/// way to find out.
class MedievalPokerTournamentDetailScreen extends StatefulWidget {
  const MedievalPokerTournamentDetailScreen({
    super.key,
    required this.tournamentId,
    required this.onBack,
    this.viewerUserId,
    this.viewerName,
    this.client,
    this.pollInterval = const Duration(seconds: 3),
  });

  final String tournamentId;
  final VoidCallback onBack;

  /// The signed-in player, used to highlight their own heat and entry.
  final String? viewerUserId;
  final String? viewerName;

  /// Injected in tests; defaults to the real REST client.
  final TournamentClient? client;

  /// Zero disables polling (tests use this to keep timers out of the way).
  final Duration pollInterval;

  @override
  State<MedievalPokerTournamentDetailScreen> createState() =>
      _MedievalPokerTournamentDetailScreenState();
}

class _MedievalPokerTournamentDetailScreenState
    extends State<MedievalPokerTournamentDetailScreen> {
  late final TournamentClient _client = widget.client ?? TournamentClient();

  TournamentDetail? _detail;
  String? _error;
  bool _loading = true;
  bool _busy = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.pollInterval > Duration.zero) {
      _poll = Timer.periodic(widget.pollInterval, (_) => _refresh());
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _fetch();
  }

  /// A background poll: never flips the screen back to a spinner, and a blip
  /// leaves the last good bracket on screen rather than blanking it.
  Future<void> _refresh() async {
    if (_busy) return;
    await _fetch(silent: true);
  }

  Future<void> _fetch({bool silent = false}) async {
    try {
      final d = await _client.detail(widget.tournamentId);
      if (!mounted) return;
      setState(() {
        _detail = d;
        _loading = false;
        _error = null;
      });
    } on TournamentException catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _act(Future<TournamentDetail> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final d = await action();
      if (!mounted) return;
      setState(() {
        _detail = d;
        _busy = false;
      });
    } on TournamentException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _busy = false;
      });
    }
  }

  /// Hand off to the live table. Pausing the poll first keeps this screen from
  /// working in the background while a game is on top of it.
  Future<void> _enterMatch(MyMatch match) async {
    _poll?.cancel();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MedievalPokerOnlineScreen(
          wsUrl: match.wsUrl,
          room: match.roomCode,
          seat: match.seat,
          humans: match.humans,
          token: match.gameToken,
          playerName: widget.viewerName,
        ),
      ),
    );
    if (!mounted) return;
    // Back from the table: the result may already have advanced the bracket.
    await _load();
    if (!mounted) return;
    if (widget.pollInterval > Duration.zero) {
      _poll = Timer.periodic(widget.pollInterval, (_) => _refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = AppLocalizations.of(context)!;
    final detail = _detail;

    return Container(
      color: colors.field,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: Icon(Icons.arrow_back_rounded, color: colors.gold),
                  ),
                  Expanded(
                    child: Text(
                      detail?.tournament.name ?? l10n.tournamentsLabel,
                      overflow: TextOverflow.ellipsis,
                      style: text.h5.copyWith(color: colors.gold),
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _load,
                    icon: Icon(Icons.refresh_rounded, color: colors.gold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: colors.gold))
                  : detail == null
                  ? _errorBody()
                  : _body(detail),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorBody() {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: colors.error),
            const SizedBox(height: 16),
            Text(
              l10n.couldNotLoadTournaments,
              textAlign: TextAlign.center,
              style: text.body.copyWith(color: colors.cream),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _load,
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

  Widget _body(TournamentDetail detail) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = AppLocalizations.of(context)!;
    final me = detail.entrantFor(widget.viewerUserId);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _StatusBanner(detail: detail, viewerEntrant: me),
        const SizedBox(height: 16),

        if (_error != null) ...[
          Text(_error!, style: text.caption.copyWith(color: colors.error)),
          const SizedBox(height: 12),
        ],

        _actions(detail),

        if (detail.bracket.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            l10n.bracketLabel,
            style: text.eyebrow.copyWith(color: colors.gold),
          ),
          const SizedBox(height: 12),
          BracketView(
            rounds: detail.bracket,
            totalRounds: detail.tournament.totalRounds,
            viewerUserId: widget.viewerUserId,
            onEnterMatch: detail.myMatch == null
                ? null
                : (_) => _enterMatch(detail.myMatch!),
          ),
        ],

        const SizedBox(height: 24),
        Text(
          l10n.entrantsLabel,
          style: text.eyebrow.copyWith(color: colors.gold),
        ),
        const SizedBox(height: 8),
        for (final e in _placed(detail.entrants))
          _EntrantRow(entrant: e, isViewer: e.userId == widget.viewerUserId),
      ],
    );
  }

  /// Entrants in the order that reads best: once places have been awarded, by
  /// finishing position; before that, by seed. Registration order is
  /// meaningless once there is a result to show.
  List<Entrant> _placed(List<Entrant> entrants) {
    if (!entrants.any((e) => e.finalRank != null)) return entrants;
    return [...entrants]..sort(
      (a, b) => (a.finalRank ?? 1 << 30).compareTo(b.finalRank ?? 1 << 30),
    );
  }

  Widget _actions(TournamentDetail detail) {
    final colors = context.kiduna;
    final l10n = AppLocalizations.of(context)!;
    final t = detail.tournament;

    // Playing comes first: if there is a table waiting, nothing else matters.
    if (detail.myMatch != null) {
      return FilledButton.icon(
        onPressed: _busy ? null : () => _enterMatch(detail.myMatch!),
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(l10n.enterYourTable),
        style: FilledButton.styleFrom(
          backgroundColor: colors.gold,
          foregroundColor: colors.black,
          minimumSize: const Size.fromHeight(48),
        ),
      );
    }

    if (t.status != TournamentStatus.registering) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (t.isRegistered)
          OutlinedButton(
            onPressed: _busy ? null : () => _act(() => _client.withdraw(t.id)),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.cream,
              side: BorderSide(color: colors.camel.withValues(alpha: 0.5)),
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(l10n.withdrawLabel),
          )
        else
          FilledButton(
            onPressed: _busy ? null : () => _act(() => _client.register(t.id)),
            style: FilledButton.styleFrom(
              backgroundColor: colors.gold,
              foregroundColor: colors.black,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(l10n.registerLabel),
          ),

        // The creator can start early rather than waiting for a full field —
        // useful when the people who are actually here are already in.
        if (t.isCreator && t.registered >= 2) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : () => _act(() => _client.start(t.id)),
            style: TextButton.styleFrom(foregroundColor: colors.sky),
            child: Text(l10n.startNowLabel),
          ),
        ],
      ],
    );
  }
}

/// Where the tournament — and the viewer — currently stand.
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.detail, required this.viewerEntrant});

  final TournamentDetail detail;
  final Entrant? viewerEntrant;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = AppLocalizations.of(context)!;
    final t = detail.tournament;

    final (String headline, Color tint) = () {
      if (viewerEntrant?.isChampion ?? false) {
        return (l10n.youAreTheChampion, colors.gold);
      }
      if (viewerEntrant?.isEliminated ?? false) {
        return (
          l10n.youWereEliminated(viewerEntrant!.eliminatedRound ?? 0),
          colors.muted,
        );
      }
      return switch (t.status) {
        TournamentStatus.registering => (
          l10n.playersRegistered(t.registered, t.size),
          colors.sky,
        ),
        TournamentStatus.running => (
          detail.myMatch != null
              ? l10n.roundOfTotal(t.currentRound, t.totalRounds)
              : l10n.waitingForOtherHeats,
          colors.mint,
        ),
        _ => (l10n.tournamentFinished, colors.gold),
      };
    }();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tint.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded, color: tint, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              headline,
              style: text.body.copyWith(
                color: tint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntrantRow extends StatelessWidget {
  const _EntrantRow({required this.entrant, required this.isViewer});

  final Entrant entrant;
  final bool isViewer;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              entrant.finalRank != null ? '${entrant.finalRank}' : '·',
              style: text.caption.copyWith(color: colors.muted),
            ),
          ),
          Expanded(
            child: Text(
              entrant.label,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall.copyWith(
                color: entrant.isEliminated ? colors.muted : colors.cream,
                fontWeight: isViewer ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          if (entrant.isChampion)
            Text(
              l10n.championLabel,
              style: text.micro.copyWith(
                color: colors.gold,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (entrant.isEliminated)
            Text(
              l10n.eliminatedLabel,
              style: text.micro.copyWith(color: colors.muted),
            ),
        ],
      ),
    );
  }
}

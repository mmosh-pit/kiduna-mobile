import 'dart:async';

import 'package:flutter/material.dart';

import '../poker_palette.dart';
import 'tournament_models.dart';
import 'tournament_source.dart';
import 'widgets/bracket_view.dart';
import 'widgets/start_countdown.dart';

/// One tournament: the countdown before it starts, the bracket once it has one.
///
/// Polls, in the manner of the lobby screen — the bracket changes when tables
/// elsewhere finish, so there is nothing to push from this client.
class TournamentDetailScreen extends StatefulWidget {
  final TournamentSource source;
  final String tournamentId;
  final String viewerId;

  /// Called with a room code when the viewer takes their seat.
  final void Function(String roomCode)? onEnterTable;

  /// Wall clock, injectable so the countdown renders deterministically in
  /// tests and goldens.
  final DateTime Function() clock;

  const TournamentDetailScreen({
    super.key,
    required this.source,
    required this.tournamentId,
    required this.viewerId,
    this.onEnterTable,
    this.clock = DateTime.now,
  });

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  TournamentDetail? _t;
  String? _error;
  bool _busy = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _refresh();
    // One second, because a countdown is on screen.
    _poll = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final next = await widget.source.detail(widget.tournamentId);
      if (mounted) setState(() => _t = next);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _toggleRegistration() async {
    final t = _t;
    if (t == null || _busy) return;
    setState(() => _busy = true);
    try {
      final next = t.summary.isRegistered
          ? await widget.source.withdraw(t.id)
          : await widget.source.register(t.id);
      if (mounted) setState(() => _t = next);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;

    return Scaffold(
      backgroundColor: const Color(0xFF14100A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14100A),
        foregroundColor: Colors.white70,
        elevation: 0,
        title: Text(
          t?.summary.name ?? 'Tournament',
          style: const TextStyle(
            fontFamily: 'GoudyHeavyface',
            fontSize: 22,
            color: kPokerGold,
          ),
        ),
      ),
      body: t == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator(color: kPokerGold)
                  : _Message(text: _error!, tone: kPokerDanger),
            )
          : _body(t),
    );
  }

  Widget _body(TournamentDetail t) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          switch (t.status) {
            TournamentStatus.scheduled => _scheduled(t),
            TournamentStatus.cancelled => _cancelled(t),
            TournamentStatus.running ||
            TournamentStatus.finished => _underway(t),
          },
        ],
      ),
    );
  }

  // ── Before the clock fires ────────────────────────────────────────────────

  Widget _scheduled(TournamentDetail t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        StartCountdown(summary: t.summary, now: widget.clock()),
        const SizedBox(height: 22),
        _RegisterButton(
          registered: t.summary.isRegistered,
          busy: _busy,
          full: t.summary.isFull && !t.summary.isRegistered,
          onTap: _toggleRegistration,
        ),
        const SizedBox(height: 24),
        _SectionLabel(label: 'Entered', trailing: '${t.entrants.length}'),
        const SizedBox(height: 8),
        _EntrantList(entrants: t.entrants, viewerId: widget.viewerId),
      ],
    );
  }

  // ── Called off ────────────────────────────────────────────────────────────

  Widget _cancelled(TournamentDetail t) {
    return Column(
      children: [
        const SizedBox(height: 30),
        const Text(
          'Cancelled',
          style: TextStyle(
            fontFamily: 'GoudyHeavyface',
            fontSize: 34,
            color: kPokerDanger,
          ),
        ),
        const SizedBox(height: 10),
        _Message(
          text:
              t.cancelledReason ??
              'Not enough players were present when the clock ran out.',
          tone: Colors.white70,
        ),
      ],
    );
  }

  // ── Running or finished ───────────────────────────────────────────────────

  Widget _underway(TournamentDetail t) {
    final champion = t.champion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (champion != null) ...[
          const SizedBox(height: 18),
          Text(
            champion.userId == widget.viewerId
                ? 'You are champion'
                : 'Champion',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'GoudyHeavyface',
              fontSize: 30,
              color: kPokerGold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            champion.userId == widget.viewerId ? '' : champion.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Avenir',
              fontSize: 15,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
        ] else
          const SizedBox(height: 10),
        BracketView(
          tournament: t,
          viewerId: widget.viewerId,
          onEnterTable: widget.onEnterTable == null
              ? null
              : (table) {
                  final code = table.roomCode;
                  if (code != null) widget.onEnterTable!(code);
                },
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final String? trailing;
  const _SectionLabel({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'IBMPlexSans',
            fontSize: 11,
            letterSpacing: 2.0,
            color: kPokerMuted,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: const Color(0x336B5533))),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          Text(
            trailing!,
            style: const TextStyle(
              fontFamily: 'IBMPlexSans',
              fontSize: 11,
              color: Colors.white38,
            ),
          ),
        ],
      ],
    );
  }
}

class _EntrantList extends StatelessWidget {
  final List<EntrantView> entrants;
  final String viewerId;
  const _EntrantList({required this.entrants, required this.viewerId});

  @override
  Widget build(BuildContext context) {
    if (entrants.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Text(
          'Nobody has entered yet.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 14,
            color: Colors.white38,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: kPokerPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPokerPanelBorder),
      ),
      child: Column(
        children: [
          for (final e in entrants)
            Container(
              color: e.userId == viewerId ? const Color(0x14EDC169) : null,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.userId == viewerId ? 'You' : e.label,
                      style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 14,
                        fontWeight: e.userId == viewerId
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    e.active ? 'here' : 'away',
                    style: TextStyle(
                      fontFamily: 'IBMPlexSans',
                      fontSize: 11,
                      color: e.active ? kPokerLive : Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RegisterButton extends StatelessWidget {
  final bool registered;
  final bool busy;
  final bool full;
  final VoidCallback onTap;

  const _RegisterButton({
    required this.registered,
    required this.busy,
    required this.full,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (full) {
      return const _Message(text: 'The field is full.', tone: kPokerMuted);
    }

    final label = registered ? 'Withdraw' : 'Enter tournament';
    return Material(
      color: registered ? Colors.transparent : kPokerGold,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: busy ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: registered ? Border.all(color: kPokerPanelBorder) : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Avenir',
              fontWeight: FontWeight.w800,
              color: registered ? Colors.white70 : kPokerInk,
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final Color tone;
  const _Message({required this.text, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 14,
          height: 1.45,
          color: tone,
        ),
      ),
    );
  }
}

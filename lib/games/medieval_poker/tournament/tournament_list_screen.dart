import 'dart:async';

import 'package:flutter/material.dart';

import '../poker_palette.dart';
import 'create_tournament_sheet.dart';
import 'tournament_models.dart';
import 'tournament_source.dart';
import 'widgets/tournament_card.dart';

/// Every tournament, soonest first.
///
/// Split into what you are in and what you could join, because those are two
/// different questions: one is "where do I have to be", the other is "what can
/// I enter". Finished and cancelled ones sit below both.
class TournamentListScreen extends StatefulWidget {
  final TournamentSource source;
  final String viewerId;

  /// Opens one tournament. Left null in tests that only check the list.
  final void Function(TournamentSummary tournament)? onOpen;

  /// Wall clock, injectable so countdowns render deterministically.
  final DateTime Function() clock;

  /// Called after a tournament is scheduled, so the host can open it.
  final void Function(TournamentSummary tournament)? onCreated;

  /// Drop the Scaffold and title when hosted inside another surface — the
  /// dashboard already supplies its own header, so a second one reads as a
  /// stray app bar rather than structure.
  final bool embedded;

  const TournamentListScreen({
    super.key,
    required this.source,
    required this.viewerId,
    this.onOpen,
    this.clock = DateTime.now,
    this.embedded = false,
    this.onCreated,
  });

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen> {
  List<TournamentSummary>? _all;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _refresh();
    // One second, because the cards carry countdowns.
    _poll = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final next = await widget.source.list();
      if (mounted) setState(() => _all = next);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return ColoredBox(
        color: const Color(0xFF14100A),
        child: Stack(
          children: [
            Positioned.fill(child: _body()),
            Positioned(right: 16, bottom: 16, child: _createButton()),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF14100A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14100A),
        foregroundColor: Colors.white70,
        elevation: 0,
        title: const Text(
          'Tournaments',
          style: TextStyle(
            fontFamily: 'GoudyHeavyface',
            fontSize: 22,
            color: kPokerGold,
          ),
        ),
      ),
      body: _body(),
      floatingActionButton: _createButton(),
    );
  }

  Widget _createButton() => FloatingActionButton.extended(
    heroTag: 'schedule-tournament',
    backgroundColor: kPokerGold,
    foregroundColor: kPokerInk,
    onPressed: _schedule,
    icon: const Icon(Icons.add),
    label: const Text(
      'Schedule',
      style: TextStyle(fontFamily: 'Avenir', fontWeight: FontWeight.w800),
    ),
  );

  Future<void> _schedule() async {
    final created = await CreateTournamentSheet.show(context, widget.source);
    if (created == null) return;
    await _refresh();
    if (mounted) widget.onCreated?.call(created.summary);
  }

  Widget _body() {
    final all = _all;
    if (all == null) {
      return Center(
        child: _error == null
            ? const CircularProgressIndicator(color: kPokerGold)
            : _Empty(text: _error!, tone: kPokerDanger),
      );
    }
    if (all.isEmpty) {
      return const _Empty(
        text: 'No tournaments scheduled.\nCheck back shortly.',
        tone: Colors.white38,
      );
    }

    final now = widget.clock();
    final mine = [
      for (final t in all)
        if (t.isRegistered && !_over(t)) t,
    ];
    final open = [
      for (final t in all)
        if (!t.isRegistered && !_over(t)) t,
    ];
    final past = [
      for (final t in all)
        if (_over(t)) t,
    ];

    return SafeArea(
      child: RefreshIndicator(
        color: kPokerGold,
        backgroundColor: kPokerPanel,
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            ..._section('Your tournaments', mine, now),
            ..._section('Open to enter', open, now),
            ..._section('Finished', past, now),
          ],
        ),
      ),
    );
  }

  static bool _over(TournamentSummary t) => t.isFinished || t.isCancelled;

  List<Widget> _section(
    String label,
    List<TournamentSummary> items,
    DateTime now,
  ) {
    if (items.isEmpty) return const [];
    return [
      _SectionLabel(label: label, count: items.length),
      const SizedBox(height: 10),
      for (final t in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TournamentCard(
            summary: t,
            now: now,
            onTap: widget.onOpen == null ? null : () => widget.onOpen!(t),
          ),
        ),
      const SizedBox(height: 14),
    ];
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final int count;
  const _SectionLabel({required this.label, required this.count});

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
        const SizedBox(width: 10),
        Text(
          '$count',
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

class _Empty extends StatelessWidget {
  final String text;
  final Color tone;
  const _Empty({required this.text, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 15,
            height: 1.5,
            color: tone,
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import 'medieval_poker_online_screen.dart';
import 'session/lobby_client.dart';

const _gold = Color(0xFFEDC169);
const _panel = Color(0xFF1B140C);
const _border = Color(0xFF6B5533);

/// Public matchmaking (Phase 5). Enqueues the player, polls for a match, and
/// hands off to the online table once a room is formed. A partial table is
/// filled with AI after a short wait, so the search never hangs.
class MedievalPokerMatchmakingScreen extends StatefulWidget {
  const MedievalPokerMatchmakingScreen({super.key});

  @override
  State<MedievalPokerMatchmakingScreen> createState() =>
      _MedievalPokerMatchmakingScreenState();
}

class _MedievalPokerMatchmakingScreenState
    extends State<MedievalPokerMatchmakingScreen> {
  final _lobby = LobbyClient();
  Timer? _poll;
  Timer? _tick;
  String? _error;
  bool _launched = false;
  bool _leaving = false;
  DateTime? _since;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    // Best-effort dequeue if we bailed while still searching.
    if (!_launched) _lobby.leaveQueue().ignore();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _error = null;
      _since = DateTime.now();
    });
    try {
      final status = await _lobby.enqueue();
      if (!mounted) return;
      if (_handle(status)) return;
      // Poll for a match; the poll also drives the server's partial-table timeout.
      _poll = Timer.periodic(const Duration(seconds: 2), (_) => _pollOnce());
      // Repaint the elapsed timer once a second.
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } on LobbyException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Something went wrong: $e');
    }
  }

  Future<void> _pollOnce() async {
    if (_launched || !mounted) return;
    try {
      _handle(await _lobby.queueStatus());
    } on LobbyException {
      // transient; keep polling
    }
  }

  /// This client's display name, taken from its own seat in the matched roster.
  String? _seatName(LobbyTicket t) {
    for (final s in t.room.seats) {
      if (s.seat == t.seat) return s.username ?? s.name;
    }
    return null;
  }

  /// Returns true if a match was found (and navigation kicked off).
  bool _handle(QueueStatus status) {
    if (status.isMatched && status.ticket != null && !_launched) {
      _launched = true;
      _poll?.cancel();
      _tick?.cancel();
      final t = status.ticket!;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(
            builder: (_) => MedievalPokerOnlineScreen(
              wsUrl: t.wsUrl,
              room: t.room.code,
              seat: t.seat,
              humans: t.room.humans,
              token: t.gameToken,
              timedLevels: t.room.timedLevels,
              playerName: _seatName(t),
            ),
          ));
      return true;
    }
    return false;
  }

  Future<void> _cancel() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    _poll?.cancel();
    _tick?.cancel();
    try {
      await _lobby.leaveQueue();
    } catch (_) {/* ignore */}
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final secs =
        _since == null ? 0 : DateTime.now().difference(_since!).inSeconds;
    return Scaffold(
      backgroundColor: const Color(0xFF14100A),
      appBar: AppBar(
        backgroundColor: _panel,
        foregroundColor: _gold,
        title: const Text('Find a Game',
            style: TextStyle(fontFamily: 'GoudyHeavyface')),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: _error != null ? _errorView() : _searchingView(secs),
          ),
        ),
      ),
    );
  }

  Widget _searchingView(int secs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: _gold),
        const SizedBox(height: 24),
        const Text('Searching for players…',
            style: TextStyle(color: _gold, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('${secs}s  ·  AI fills empty seats after a short wait',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 32),
        OutlinedButton(
          onPressed: _leaving ? null : _cancel,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: const BorderSide(color: _border),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          ),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _errorView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFB3261E), size: 40),
        const SizedBox(height: 14),
        Text(_error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFF3A0A0), fontSize: 14)),
        const SizedBox(height: 24),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: _border),
              ),
              child: const Text('Back'),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _search,
              style: FilledButton.styleFrom(
                  backgroundColor: _gold, foregroundColor: Colors.black),
              child: const Text('Retry'),
            ),
          ],
        ),
      ],
    );
  }
}

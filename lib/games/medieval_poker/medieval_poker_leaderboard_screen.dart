import 'package:flutter/material.dart';

import 'session/lobby_client.dart';

const _gold = Color(0xFFEDC169);
const _panel = Color(0xFF1B140C);
const _border = Color(0xFF6B5533);

/// Results & leaderboard (Phase 6). Shows the player's own record and the top
/// players by wins, sourced from the backend's game-service-written stats.
class MedievalPokerLeaderboardScreen extends StatefulWidget {
  const MedievalPokerLeaderboardScreen({super.key});

  @override
  State<MedievalPokerLeaderboardScreen> createState() =>
      _MedievalPokerLeaderboardScreenState();
}

class _MedievalPokerLeaderboardScreenState
    extends State<MedievalPokerLeaderboardScreen> {
  final _lobby = LobbyClient();
  PlayerStats? _stats;
  List<LeaderboardEntry> _board = const [];
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
      final results = await Future.wait([_lobby.myStats(), _lobby.leaderboard()]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as PlayerStats;
        _board = results[1] as List<LeaderboardEntry>;
        _loading = false;
      });
    } on LobbyException catch (_) {
      if (mounted) {
        setState(() {
          _error = null;
          _stats = null;
          _board = const [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Something went wrong: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0604),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Leaderboard',
                        style: TextStyle(
                            fontFamily: 'GoudyHeavyface',
                            fontSize: 18,
                            color: _gold)),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _load,
                    icon: Icon(Icons.refresh_rounded, color: _gold),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _gold))
                  : _error != null
                      ? _errorView()
                      : _content(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    final s = _stats;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (s != null) _statsCard(s),
        const SizedBox(height: 20),
        const Text('Top Players',
            style: TextStyle(
                color: _gold, fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 8),
        if (_board.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('No games recorded yet.',
                  style: TextStyle(color: Colors.white38)),
            ),
          )
        else
          for (int i = 0; i < _board.length; i++) _row(i + 1, _board[i]),
      ],
    );
  }

  Widget _statsCard(PlayerStats s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('Games', '${s.games}'),
          _stat('Wins', '${s.wins}'),
          _stat('Win rate', '${s.winRate}%'),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: _gold, fontWeight: FontWeight.w900, fontSize: 24)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      );

  Widget _row(int rank, LeaderboardEntry e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: rank <= 3 ? _gold : _border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('$rank',
                style: TextStyle(
                    color: rank <= 3 ? _gold : Colors.white54,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ),
          Expanded(
            child: Text(e.label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          Text('${e.wins}W',
              style: const TextStyle(
                  color: Color(0xFF7FE0A6), fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          Text('${e.games}G  ·  ${e.winRate}%',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFB3261E), size: 40),
              const SizedBox(height: 14),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFF3A0A0))),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _load,
                style: FilledButton.styleFrom(
                    backgroundColor: _gold, foregroundColor: Colors.black),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
}
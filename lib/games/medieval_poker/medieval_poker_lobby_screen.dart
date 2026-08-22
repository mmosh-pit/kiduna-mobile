import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'medieval_poker_leaderboard_screen.dart';
import 'medieval_poker_matchmaking_screen.dart';
import 'medieval_poker_online_screen.dart';
import 'session/lobby_client.dart';

const _gold = Color(0xFFEDC169);
const _panel = Color(0xFF1B140C);
const _border = Color(0xFF6B5533);

/// Friends-only invite lobby (Phase 3). Create a room to get a shareable code,
/// or join one by code; ready up; the host starts once everyone is ready, and
/// all clients hand off to the online table. Requires the app's auth token.
class MedievalPokerLobbyScreen extends StatefulWidget {
  const MedievalPokerLobbyScreen({super.key, this.onLeaderboard});

  /// Called when the leaderboard icon is tapped.
  final VoidCallback? onLeaderboard;

  @override
  State<MedievalPokerLobbyScreen> createState() =>
      _MedievalPokerLobbyScreenState();
}

class _MedievalPokerLobbyScreenState extends State<MedievalPokerLobbyScreen> {
  final _lobby = LobbyClient();
  final _codeController = TextEditingController();

  LobbyRoom? _room;
  int? _mySeat;
  String? _gameToken;
  String? _wsUrl;
  bool _isHost = false;

  String? _error;
  bool _busy = false;
  bool _launched = false;
  Timer? _poll;

  @override
  void dispose() {
    _poll?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  bool get _myReady =>
      _room?.seats
          .firstWhere((s) => s.seat == _mySeat,
              orElse: () => const LobbySeat(
                  seat: -1, userId: null, isAi: false, ready: false))
          .ready ??
      false;

  bool get _canStart {
    final r = _room;
    if (r == null || !_isHost) return false;
    final occupied = r.seats.where((s) => s.userId != null).toList();
    return occupied.isNotEmpty && occupied.every((s) => s.ready);
  }

  Future<void> _guard(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on LobbyException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _adopt(LobbyTicket t, {required bool host}) {
    _room = t.room;
    _mySeat = t.seat;
    _gameToken = t.gameToken;
    _wsUrl = t.wsUrl;
    _isHost = host;
    _launched = false;
    _startPolling();
    _maybeLaunch();
  }

  Future<void> _create() => _guard(() async {
        final t = await _lobby.createRoom();
        if (mounted) setState(() => _adopt(t, host: true));
      });

  Future<void> _join() => _guard(() async {
        final code = _codeController.text.trim().toUpperCase();
        if (code.isEmpty) throw const LobbyException('Enter a room code');
        final t = await _lobby.joinRoom(code);
        if (mounted) setState(() => _adopt(t, host: false));
      });

  Future<void> _toggleReady() => _guard(() async {
        final r = _room;
        if (r == null) return;
        final updated = await _lobby.setReady(r.code, !_myReady);
        if (mounted) setState(() => _room = updated);
      });

  Future<void> _startGame() => _guard(() async {
        final r = _room;
        if (r == null) return;
        final updated = await _lobby.start(r.code);
        if (mounted) {
          setState(() => _room = updated);
          _maybeLaunch();
        }
      });

  Future<void> _leave() => _guard(() async {
        final r = _room;
        _poll?.cancel();
        if (r != null) await _lobby.leave(r.code);
        if (mounted) {
          setState(() {
            _room = null;
            _mySeat = null;
            _gameToken = null;
            _wsUrl = null;
          });
        }
      });

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  Future<void> _refresh() async {
    final r = _room;
    if (r == null || !mounted) return;
    try {
      final updated = await _lobby.getRoom(r.code);
      if (!mounted) return;
      setState(() => _room = updated);
      _maybeLaunch();
    } on LobbyException {
      // transient; keep polling
    }
  }

  /// This client's display name, taken from its own seat in the roster.
  String? _mySeatName(LobbyRoom r) {
    final seat = _mySeat;
    if (seat == null) return null;
    for (final s in r.seats) {
      if (s.seat == seat) return s.username ?? s.name;
    }
    return null;
  }

  void _maybeLaunch() {
    final r = _room;
    if (r == null || !r.isActive || _launched) return;
    _launched = true;
    _poll?.cancel();
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => MedievalPokerOnlineScreen(
            wsUrl: _wsUrl!,
            room: r.code,
            seat: _mySeat!,
            humans: r.humans,
            token: _gameToken,
            timedLevels: r.timedLevels,
            playerName: _mySeatName(r),
          ),
        ))
        .then((_) {
      // Returning from the table: reset to the entry view.
      if (mounted) {
        setState(() {
          _room = null;
          _mySeat = null;
          _gameToken = null;
          _wsUrl = null;
        });
      }
    });
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
                  Expanded(
                    child: Text('Medieval Poker — Lobby',
                        style: TextStyle(
                            fontFamily: 'GoudyHeavyface',
                            fontSize: 18,
                            color: _gold)),
                  ),
                  IconButton(
                    tooltip: 'Leaderboard',
                    icon: Icon(Icons.emoji_events_rounded, color: _gold),
                    onPressed: widget.onLeaderboard,
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _room == null ? _entryView() : _roomView(_room!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Entry (create / join) ──────────────────────────────────────────────
  Widget _entryView() {
    return ListView(
      children: [
        const Text(
          'Play online against friends. Create a room to get a code, or join '
          'one. Empty seats are filled by AI. Requires you to be signed in.',
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy ? null : _create,
          style: FilledButton.styleFrom(
            backgroundColor: _gold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('Create Room',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ),
        const SizedBox(height: 24),
        const Text('Join by code',
            style: TextStyle(
                color: _gold, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _codeController,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            UpperCaseTextFormatter(),
            LengthLimitingTextInputFormatter(6),
          ],
          style: const TextStyle(
              color: Colors.white, fontSize: 20, letterSpacing: 4),
          decoration: const InputDecoration(
            hintText: 'ABC123',
            hintStyle: TextStyle(color: Colors.white24, letterSpacing: 4),
            enabledBorder:
                OutlineInputBorder(borderSide: BorderSide(color: _border)),
            focusedBorder:
                OutlineInputBorder(borderSide: BorderSide(color: _gold)),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _busy ? null : _join,
          style: OutlinedButton.styleFrom(
            foregroundColor: _gold,
            side: const BorderSide(color: _gold),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('Join Room',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ),
        const SizedBox(height: 28),
        const Divider(color: _border),
        const SizedBox(height: 16),
        const Text('Or match with anyone',
            style: TextStyle(
                color: _gold, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => const MedievalPokerMatchmakingScreen()),
          ),
          icon: const Icon(Icons.public_rounded),
          style: OutlinedButton.styleFrom(
            foregroundColor: _gold,
            side: const BorderSide(color: _gold),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          label: const Text('Find a Public Game',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          _errorBox(_error!),
        ],
      ],
    );
  }

  // ── In-room ─────────────────────────────────────────────────────────────
  Widget _roomView(LobbyRoom room) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Code  ',
                style: TextStyle(color: Colors.white60, fontSize: 14)),
            SelectableText(
              room.code,
              style: const TextStyle(
                color: _gold,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
              ),
            ),
            IconButton(
              tooltip: 'Copy code',
              icon: const Icon(Icons.copy_rounded, color: Colors.white54),
              onPressed: () => Clipboard.setData(ClipboardData(text: room.code)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          room.isActive ? 'Starting…' : 'Waiting for players to ready up',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: [
              for (final s in room.seats) _seatTile(s),
            ],
          ),
        ),
        if (_error != null) ...[
          _errorBox(_error!),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : _leave,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: _border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Leave'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : _toggleReady,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      _myReady ? const Color(0xFF2E5A44) : const Color(0xFF33291C),
                  foregroundColor: _myReady ? Colors.white : _gold,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(_myReady ? 'Ready ✓' : 'Ready up',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            if (_isHost) ...[
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: (_busy || !_canStart) ? null : _startGame,
                  style: FilledButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white24,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Start',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _seatTile(LobbySeat s) {
    final isMe = s.seat == _mySeat;
    final Color dot;
    if (s.isAi) {
      dot = const Color(0xFF7FD0E0);
    } else if (s.userId == null) {
      dot = Colors.white24;
    } else if (s.ready) {
      dot = const Color(0xFF3FA96A);
    } else {
      dot = _gold;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isMe ? _gold : _border),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text('Seat ${s.seat}',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${s.label}${isMe ? '  (you)' : ''}',
              style: TextStyle(
                color: s.isOpen ? Colors.white38 : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          if (s.isAi)
            const Text('AI backfill',
                style: TextStyle(color: Color(0xFF7FD0E0), fontSize: 11))
          else if (s.userId != null)
            Text(s.ready ? 'Ready' : 'Not ready',
                style: TextStyle(
                    color: s.ready ? const Color(0xFF7FE0A6) : Colors.white38,
                    fontSize: 11)),
        ],
      ),
    );
  }

  Widget _errorBox(String msg) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x33B3261E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFB3261E)),
        ),
        child: Text(msg,
            style: const TextStyle(color: Color(0xFFF3A0A0), fontSize: 13)),
      );
}

/// Uppercases lobby-code input as it's typed.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
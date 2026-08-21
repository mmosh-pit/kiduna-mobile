import 'package:medieval_poker_engine/medieval_poker_engine.dart';
import 'package:medieval_poker_engine/protocol.dart';
import 'package:medieval_poker_engine/service.dart';

/// One authoritative game instance. Owns the [PokerGame], the per-seat agents,
/// and the [GameDriver], and turns driver events into per-player [ServerMessage]s
/// pushed through [send] (the transport wires this to the right socket).
class GameRoom {
  final String roomId;
  final PokerGame game;
  final List<PlayerAgent> agents;
  final Set<int> aiSeats;

  /// Seconds left in the current timed level, or null (untimed / headless).
  int? Function()? levelSecondsLeft;

  /// Delivers a message to the socket for [seat]. The transport supplies this;
  /// AI seats are simply ignored downstream.
  final void Function(int seat, ServerMessage msg) send;

  final List<String> _log = [];
  late final GameDriver _driver;
  int _seq = 0;

  GameRoom({
    required this.roomId,
    required this.game,
    required this.agents,
    required this.aiSeats,
    required this.send,
    this.levelSecondsLeft,
  }) {
    _driver = GameDriver(
      game: game,
      agents: agents,
      onState: _broadcastState,
      onResult: _broadcastResult,
      onGameOver: _broadcastGameOver,
    );
  }

  /// Attach to a game's log; call at construction so [logTail] is populated.
  void captureLog(String line) {
    _log.add(line);
    if (_log.length > 40) _log.removeRange(0, _log.length - 40);
  }

  Future<void> run() => _driver.run();

  Map<String, dynamic> _snapshotPayload(int seat, Set<int> reveal) =>
      serializeFor(
        game,
        seat,
        aiSeats: aiSeats,
        roomId: roomId,
        actingSeat: game.actingPlayer?.seat,
        levelSecondsLeft: levelSecondsLeft?.call(),
        logTail: List.unmodifiable(
            _log.length > 12 ? _log.sublist(_log.length - 12) : _log),
        revealSeats: reveal,
      ).toJson();

  ServerMessage _stateFor(int seat, Set<int> reveal) => ServerMessage(
        type: ServerMsgType.state,
        seq: _seq,
        payload: _snapshotPayload(seat, reveal),
      );

  /// A full state snapshot tagged `resync`, pushed to a (re)connecting client
  /// so it can repaint the table immediately instead of waiting for the next
  /// broadcast. The client treats it like `state`.
  ServerMessage resyncFor(int seat) => ServerMessage(
        type: ServerMsgType.resync,
        seq: _seq,
        payload: _snapshotPayload(seat, const {}),
      );

  void _broadcastState(Set<int> reveal) {
    _seq++;
    for (var s = 0; s < game.players.length; s++) {
      send(s, _stateFor(s, reveal));
    }
  }

  void _broadcastResult(List<PotAward> awards) {
    _seq++;
    final main = awards.isEmpty ? null : awards.first;
    for (var s = 0; s < game.players.length; s++) {
      final me = game.players[s];
      final won = awards.any((a) => a.winners.contains(me));
      send(
        s,
        ServerMessage(type: ServerMsgType.handResult, seq: _seq, payload: {
          'won': won,
          'inHand': me.inHand,
          // Per-seat blurb so every player — winner, showdown loser, or folder —
          // sees a meaningful result popup, not just the winner.
          'detail': _resultDetail(me, won, awards, main),
          'winners': [for (final w in (main?.winners ?? const [])) w.seat],
        }),
      );
    }
  }

  /// Builds the one-line result blurb shown in each player's win/lose popup.
  String _resultDetail(
      PokerPlayer me, bool won, List<PotAward> awards, PotAward? main) {
    if (won) {
      var total = 0;
      for (final a in awards) {
        if (a.winners.contains(me)) total += a.amount ~/ a.winners.length;
      }
      final hand = me.showdownHand?.toString();
      return 'You won $total${hand != null ? ' with a $hand' : ''}';
    }
    if (main != null) {
      final names = main.winners.map((w) => w.name).join(', ');
      return '$names won the ${main.amount} pot';
    }
    return '';
  }

  void _broadcastGameOver() {
    _seq++;
    final winner = game.gameWinner;
    final standings = [...game.players]..sort((a, b) => b.stack.compareTo(a.stack));
    for (var s = 0; s < game.players.length; s++) {
      send(
        s,
        ServerMessage(type: ServerMsgType.gameOver, seq: _seq, payload: {
          'winnerSeat': winner?.seat,
          'youWon': winner?.seat == s,
          'standings': [
            for (final p in standings)
              {'seat': p.seat, 'stack': p.stack, 'name': p.name}
          ],
        }),
      );
    }
  }
}

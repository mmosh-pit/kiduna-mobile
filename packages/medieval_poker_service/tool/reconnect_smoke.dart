// Reconnection + resync: a human drops mid-game and a new socket reclaims the
// same seat. Asserts the reconnect gets an immediate `resync` (own cards
// visible), the seat is NOT permanently lost to AI, and the game finishes —
// with no opponent hole-card leaks throughout.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:medieval_poker_engine/medieval_poker_engine.dart';
import 'package:medieval_poker_engine/protocol.dart';
import 'package:medieval_poker_service/medieval_poker_service.dart';

int fail = 0;
void check(bool c, String label) { if (!c) { fail++; print('  FAIL: $label'); } }

ClientMessage _respond(PromptSpec spec) {
  ClientMessage act(GameActionKind? k, [Map<String, dynamic> p = const {}]) =>
      ClientMessage(type: ClientMsgType.action, promptId: spec.promptId, actionKind: k, payload: p);
  switch (spec.kind) {
    case PromptKind.bettingAction:
      return (spec.callAmount ?? 0) == 0 ? act(GameActionKind.check) : act(GameActionKind.fold);
    case PromptKind.classPick: return act(GameActionKind.classPick, {'index': 0});
    case PromptKind.courtPick: return act(GameActionKind.courtPick, {'index': 0});
    case PromptKind.deckBuild: return act(GameActionKind.deckBuild);
    case PromptKind.targetPick:
      final s = spec.options.isNotEmpty ? int.tryParse(spec.options.first.id) ?? 0 : 0;
      return act(GameActionKind.targetPick, {'seat': s});
    case PromptKind.itemMode: return act(null, {'index': 0});
    case PromptKind.itemPick: return act(null, {'index': 0});
    case PromptKind.payChoice: return act(GameActionKind.payChoice, {'useChip': false});
    case PromptKind.chipSell: return act(GameActionKind.sellChip, {'sell': false});
    default: return act(GameActionKind.pass);
  }
}

/// Attaches to a socket, auto-answers prompts, tracks stats. `seat` is fixed 0.
class Client {
  final WebSocket ws;
  int states = 0, leaks = 0, ownVisible = 0, resyncs = 0;
  bool welcome = false, gameOver = false;
  Client(this.ws) {
    ws.listen((data) {
      final m = ServerMessage.fromJson(jsonDecode(data as String) as Map<String, dynamic>);
      switch (m.type) {
        case ServerMsgType.welcome: welcome = true;
        case ServerMsgType.resync: resyncs++; _snap(m.payload);
        case ServerMsgType.state: _snap(m.payload);
        case ServerMsgType.prompt:
          _send(_respond(PromptSpec.fromJson(m.payload)));
        case ServerMsgType.gameOver: gameOver = true;
        default: break;
      }
    }, onError: (_) {}, cancelOnError: false);
  }
  void _snap(Map<String, dynamic> payload) {
    states++;
    final snap = TableSnapshot.fromJson(payload);
    final me = snap.seats.firstWhere((s) => s.seat == 0);
    if (me.holeCards.isNotEmpty && me.holeCards.every((c) => c != CardCode.hidden)) ownVisible++;
    if (snap.street != Street.handOver.name) {
      for (final o in snap.seats.where((s) => s.seat != 0)) {
        if (o.holeCards.any((c) => c != CardCode.hidden)) leaks++;
      }
    }
  }
  void _send(ClientMessage m) {
    // A buffered prompt can arrive just as we close this client to simulate the
    // drop; swallow the send rather than crash the harness.
    try {
      if (ws.readyState == WebSocket.open) ws.add(jsonEncode(m.toJson()));
    } catch (_) {/* socket closing */}
  }
}

Future<void> main() async {
  final server = GameServer(
    turnTimeout: const Duration(milliseconds: 200),
    graceDuration: const Duration(seconds: 10),
    config: const PokerConfig(), // hand-count → terminates
  );
  final http = await server.start(host: '127.0.0.1', port: 0);
  final url = 'ws://127.0.0.1:${http.port}/game?room=t1&seat=0&humans=1';

  // Session A: start the game, play a bit, then drop.
  final a = Client(await WebSocket.connect(url));
  final startA = DateTime.now();
  while (a.states < 4 && DateTime.now().difference(startA).inSeconds < 20) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  check(a.welcome, 'A welcomed');
  check(a.states >= 4, 'A saw the game running before dropping (${a.states})');
  final aOwn = a.ownVisible;
  await a.ws.close(); // drop mid-game (within grace)

  // Session B: reconnect to the same seat.
  await Future<void>.delayed(const Duration(milliseconds: 120));
  final b = Client(await WebSocket.connect(url));

  final startB = DateTime.now();
  while (!b.gameOver && DateTime.now().difference(startB).inSeconds < 40) {
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }
  await b.ws.close();
  await http.close(force: true);

  check(b.welcome, 'B welcomed on reconnect');
  check(b.resyncs > 0, 'B got an immediate resync (${b.resyncs})');
  check(b.ownVisible > 0, 'B sees its own hole cards after reconnect');
  check(b.gameOver, 'game finished after reconnect (seat reclaimed, not lost)');
  check(a.leaks == 0 && b.leaks == 0, 'no opponent leaks (A=${a.leaks} B=${b.leaks})');
  check(aOwn > 0, 'A saw its own cards before dropping');

  print(fail == 0
      ? 'RECONNECT OK — dropped mid-game, reconnected, got resync + own cards, '
          'reclaimed the seat, played to gameOver, no leaks'
      : '$fail CHECK(S) FAILED');
  exit(fail == 0 ? 0 : 1);
}

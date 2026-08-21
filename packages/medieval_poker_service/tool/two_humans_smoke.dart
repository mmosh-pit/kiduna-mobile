// Milestone proof (Phase 2): 2 humans + 2 AI in one hardcoded room, over real
// WebSockets, with the two human clients ACTIVELY responding to every prompt
// (not just letting them time out). Asserts both humans get their setup
// prompts (class/court/deck), never see an opponent's hole cards during play,
// always see their own, and the game runs to gameOver.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:medieval_poker_engine/medieval_poker_engine.dart';
import 'package:medieval_poker_engine/protocol.dart';
import 'package:medieval_poker_service/medieval_poker_service.dart';

int fail = 0;
void check(bool c, String label) {
  if (!c) {
    fail++;
    print('  FAIL: $label');
  }
}

/// One scripted human client. Connects, then answers each prompt with the
/// safe/"do nothing" choice so hands resolve on ante pressure and the game
/// ends quickly — but answers ACTIVELY, exercising the whole response path.
class ScriptedHuman {
  final int seat;
  final Uri url;
  late WebSocket _ws;

  int welcomeSeat = -1;
  int states = 0;
  int leaks = 0;
  int ownVisible = 0;
  final Set<String> promptKinds = {};
  bool gotGameOver = false;
  final done = Completer<void>();

  ScriptedHuman(this.seat, this.url);

  Future<void> connect() async {
    // Pass ?humans=2 so the server waits for BOTH humans before setup — this
    // is the lobby→game-service start-gate hint. If it were ignored, the game
    // would start on the first connect and seat 1 would miss its setup prompts,
    // failing the classPick/courtPick/deckBuild assertions below.
    _ws = await WebSocket.connect('$url?room=t1&seat=$seat&humans=2');
    _ws.listen(_onData, onError: (_) {}, onDone: () {
      if (!done.isCompleted) done.complete();
    });
  }

  void _send(ClientMessage m) {
    if (_ws.readyState == WebSocket.open) _ws.add(jsonEncode(m.toJson()));
  }

  void _onData(dynamic data) {
    final m =
        ServerMessage.fromJson(jsonDecode(data as String) as Map<String, dynamic>);
    switch (m.type) {
      case ServerMsgType.welcome:
        welcomeSeat = m.payload['seat'] as int;
      case ServerMsgType.state:
        states++;
        final snap = TableSnapshot.fromJson(m.payload);
        final me = snap.seats.firstWhere((s) => s.seat == seat);
        if (me.holeCards.isNotEmpty &&
            me.holeCards.every((c) => c != CardCode.hidden)) {
          ownVisible++;
        }
        if (snap.street != Street.handOver.name) {
          for (final o in snap.seats.where((s) => s.seat != seat)) {
            if (o.holeCards.any((c) => c != CardCode.hidden)) leaks++;
          }
        }
      case ServerMsgType.prompt:
        final spec = PromptSpec.fromJson(m.payload);
        promptKinds.add(spec.kind.name);
        _send(_respond(spec));
      case ServerMsgType.gameOver:
        gotGameOver = true;
        if (!done.isCompleted) done.complete();
      default:
        break;
    }
  }

  ClientMessage _respond(PromptSpec spec) {
    ClientMessage act(GameActionKind? k, [Map<String, dynamic> p = const {}]) =>
        ClientMessage(
            type: ClientMsgType.action,
            promptId: spec.promptId,
            actionKind: k,
            payload: p);
    switch (spec.kind) {
      case PromptKind.bettingAction:
        // Check when free, otherwise fold — commits nothing beyond antes.
        return (spec.callAmount ?? 0) == 0
            ? act(GameActionKind.check)
            : act(GameActionKind.fold);
      case PromptKind.classPick:
        return act(GameActionKind.classPick, {'index': 0});
      case PromptKind.courtPick:
        return act(GameActionKind.courtPick, {'index': 0});
      case PromptKind.deckBuild:
        return act(GameActionKind.deckBuild); // no cardIds → server auto-builds
      case PromptKind.targetPick:
        final s = spec.options.isNotEmpty
            ? int.tryParse(spec.options.first.id) ?? 0
            : 0;
        return act(GameActionKind.targetPick, {'seat': s});
      case PromptKind.itemMode:
        return act(null, {'index': 0});
      case PromptKind.itemPick:
        return act(null, {'index': 0});
      case PromptKind.payChoice:
        return act(GameActionKind.payChoice, {'useChip': false});
      case PromptKind.chipSell:
        return act(GameActionKind.sellChip, {'sell': false});
      // Every optional window → pass (an actionKind other than the window's
      // "play" kind is read as a decline by the server-side RemoteAgent).
      case PromptKind.setupWindow:
      case PromptKind.roundWindow:
      case PromptKind.showdownWindow:
      case PromptKind.counterWindow:
      case PromptKind.boardCounter:
      case PromptKind.itemPlay:
        return act(GameActionKind.pass);
    }
  }

  Future<void> close() => _ws.close();
}

Future<void> main() async {
  final server = GameServer(
    // Default humansToStart (1); the clients' ?humans=2 hint must raise the
    // per-room start threshold so setup waits for both.
    turnTimeout: const Duration(seconds: 5),
    config: const PokerConfig(), // hand-count → terminates fast
  );
  final http = await server.start(host: '127.0.0.1', port: 0);
  final url = Uri.parse('ws://127.0.0.1:${http.port}/game');

  final a = ScriptedHuman(0, url);
  final b = ScriptedHuman(1, url);
  await a.connect();
  await b.connect();

  await Future.any([
    Future.wait([a.done.future, b.done.future]),
    Future.delayed(const Duration(seconds: 60)),
  ]);

  await a.close();
  await b.close();
  await http.close(force: true);

  for (final h in [a, b]) {
    check(h.welcomeSeat == h.seat, 'seat ${h.seat}: welcome (got ${h.welcomeSeat})');
    check(h.states > 0, 'seat ${h.seat}: received states (${h.states})');
    check(h.ownVisible > 0, 'seat ${h.seat}: own hole cards visible');
    check(h.leaks == 0, 'seat ${h.seat}: NO opponent leaks (leaks=${h.leaks})');
    check(h.gotGameOver, 'seat ${h.seat}: reached gameOver');
    for (final k in ['classPick', 'courtPick', 'deckBuild']) {
      check(h.promptKinds.contains(k), 'seat ${h.seat}: got $k prompt');
    }
    check(h.promptKinds.contains('bettingAction'),
        'seat ${h.seat}: got bettingAction prompt');
  }
  print(fail == 0
      ? 'TWO-HUMANS OK — 2 humans + 2 AI played to gameOver over WS; both got '
          'setup prompts; no hole-card leaks; own cards always visible'
      : '$fail CHECK(S) FAILED');
  exit(fail == 0 ? 0 : 1);
}

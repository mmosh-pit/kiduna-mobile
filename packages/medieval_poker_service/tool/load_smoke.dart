// Load/soak: run many concurrent 4-human rooms to completion. Asserts every
// room finishes, no room leaks an opponent's hole cards, and the authoritative
// result reporter fires exactly once per room with a coherent winner/standings.
// Reports timing. Verifiable locally with no Node/DB (an in-process reporter
// captures what the backend would receive).
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

class LoadClient {
  final String room;
  final int seat;
  late WebSocket _ws;
  int leaks = 0;
  bool gameOver = false;
  LoadClient(this.room, this.seat);

  Future<void> connect(Uri url) async {
    _ws = await WebSocket.connect('$url?room=$room&seat=$seat&humans=4');
    _ws.listen((data) {
      final m = ServerMessage.fromJson(jsonDecode(data as String) as Map<String, dynamic>);
      switch (m.type) {
        case ServerMsgType.prompt:
          if (_ws.readyState == WebSocket.open) {
            _ws.add(jsonEncode(_respond(PromptSpec.fromJson(m.payload)).toJson()));
          }
        case ServerMsgType.state:
          final snap = TableSnapshot.fromJson(m.payload);
          if (snap.street != Street.handOver.name) {
            for (final o in snap.seats.where((s) => s.seat != seat)) {
              if (o.holeCards.any((c) => c != CardCode.hidden)) leaks++;
            }
          }
        case ServerMsgType.gameOver:
          gameOver = true;
        default: break;
      }
    }, onError: (_) {}, cancelOnError: false);
  }

  Future<void> close() => _ws.close();
}

Future<void> main() async {
  const rooms = 8;
  final reports = <GameResultReport>[];
  final server = GameServer(
    turnTimeout: const Duration(milliseconds: 100),
    config: const PokerConfig(),
    resultReporter: (r) async => reports.add(r),
  );
  final http = await server.start(host: '127.0.0.1', port: 0);
  final url = Uri.parse('ws://127.0.0.1:${http.port}/game');

  final started = DateTime.now();
  final clients = <LoadClient>[];
  for (var r = 0; r < rooms; r++) {
    for (var s = 0; s < 4; s++) {
      final c = LoadClient('room$r', s);
      clients.add(c);
      await c.connect(url);
    }
  }

  final deadline = DateTime.now().add(const Duration(seconds: 90));
  while (clients.any((c) => !c.gameOver) && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  await Future<void>.delayed(const Duration(milliseconds: 300)); // let reports flush
  final elapsed = DateTime.now().difference(started);

  for (final c in clients) {
    await c.close();
  }
  await http.close(force: true);

  final finished = clients.where((c) => c.gameOver).length;
  final totalLeaks = clients.fold<int>(0, (a, c) => a + c.leaks);
  check(finished == clients.length, 'all ${clients.length} clients finished (got $finished)');
  check(totalLeaks == 0, 'no opponent leaks under load (leaks=$totalLeaks)');
  check(reports.length == rooms, 'one result report per room (got ${reports.length}/$rooms)');
  for (final rep in reports) {
    check(rep.seats.length == 4, 'report ${rep.roomCode}: 4 seats');
    final ws = rep.winnerSeat;
    check(ws != null && ws >= 0 && ws < 4, 'report ${rep.roomCode}: valid winnerSeat ($ws)');
    if (ws != null) {
      final maxStack = rep.seats.map((s) => s.stack).reduce((a, b) => a > b ? a : b);
      final winnerStack = rep.seats.firstWhere((s) => s.seat == ws).stack;
      check(winnerStack == maxStack, 'report ${rep.roomCode}: winner holds the largest stack');
    }
  }

  print('rooms=$rooms clients=${clients.length} finished=$finished '
      'reports=${reports.length} in ${elapsed.inMilliseconds}ms');
  print(fail == 0
      ? 'LOAD OK — $rooms concurrent rooms ran to completion, no leaks, every '
          'game reported with a coherent winner/standings'
      : '$fail CHECK(S) FAILED');
  exit(fail == 0 ? 0 : 1);
}

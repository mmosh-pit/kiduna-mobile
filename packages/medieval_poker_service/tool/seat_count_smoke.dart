// Per-room seat count (`?seats=`) + elimination ordering in the result report.
//
// A tournament's heads-up final must be a REAL 2-seat table, not 2 humans plus
// 2 AI. And the reported result must carry each seat's bust order, because
// final stacks alone can't rank the losers — everyone eliminated ends on 0.
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

ClientMessage _respond(PromptSpec spec) {
  ClientMessage act(GameActionKind? k, [Map<String, dynamic> p = const {}]) =>
      ClientMessage(
        type: ClientMsgType.action,
        promptId: spec.promptId,
        actionKind: k,
        payload: p,
      );
  switch (spec.kind) {
    case PromptKind.bettingAction:
      return (spec.callAmount ?? 0) == 0
          ? act(GameActionKind.check)
          : act(GameActionKind.fold);
    case PromptKind.classPick:
      return act(GameActionKind.classPick, {'index': 0});
    case PromptKind.courtPick:
      return act(GameActionKind.courtPick, {'index': 0});
    case PromptKind.deckBuild:
      return act(GameActionKind.deckBuild);
    case PromptKind.targetPick:
      final s = spec.options.isNotEmpty
          ? int.tryParse(spec.options.first.id) ?? 0
          : 0;
      return act(GameActionKind.targetPick, {'seat': s});
    case PromptKind.payChoice:
      return act(GameActionKind.payChoice, {'useChip': false});
    case PromptKind.chipSell:
      return act(GameActionKind.sellChip, {'sell': false});
    default:
      return act(GameActionKind.pass);
  }
}

Future<void> main() async {
  GameResultReport? report;
  final server = GameServer(
    turnTimeout: const Duration(milliseconds: 150),
    startDeadline: const Duration(milliseconds: 600),
    config: const PokerConfig(),
    resultReporter: (r) async => report = r,
  );
  final http = await server.start(host: '127.0.0.1', port: 0);

  // A heads-up final: 2 seats only.
  final ws = await WebSocket.connect(
    'ws://127.0.0.1:${http.port}/game?room=final&seat=0&seats=2&humans=1',
  );
  var gameOver = false;
  int? seatsSeen;
  ws.listen((data) {
    final m = ServerMessage.fromJson(
      jsonDecode(data as String) as Map<String, dynamic>,
    );
    switch (m.type) {
      case ServerMsgType.prompt:
        ws.add(jsonEncode(_respond(PromptSpec.fromJson(m.payload)).toJson()));
      case ServerMsgType.state:
        final t = TableSnapshot.fromJson(m.payload);
        seatsSeen = t.seats.length;
      case ServerMsgType.gameOver:
        gameOver = true;
      default:
        break;
    }
  });

  final start = DateTime.now();
  while (!gameOver && DateTime.now().difference(start).inSeconds < 60) {
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }
  await ws.close();
  // The reporter fires from the run loop's whenComplete; give it a tick.
  await Future<void>.delayed(const Duration(milliseconds: 100));
  await http.close(force: true);

  check(gameOver, 'heads-up room ran to completion');
  check(seatsSeen == 2, 'table has exactly 2 seats (got $seatsSeen)');

  final r = report;
  check(r != null, 'result reported');
  if (r != null) {
    check(
      r.seats.length == 2,
      'result carries 2 seats (got ${r.seats.length})',
    );
    final busted = r.seats.where((s) => s.stack <= 0).toList();
    final survivors = r.seats.where((s) => s.stack > 0).toList();
    check(
      busted.every((s) => s.eliminationOrder != null),
      'every busted seat carries an eliminationOrder',
    );
    check(
      survivors.every((s) => s.eliminationOrder == null),
      'surviving seats carry no eliminationOrder',
    );
    final orders = busted.map((s) => s.eliminationOrder!).toList()..sort();
    check(
      orders.toSet().length == orders.length,
      'elimination orders are distinct (got $orders)',
    );
    check(
      orders.isEmpty || orders.first == 1,
      'elimination order starts at 1 (got $orders)',
    );
  }

  print(
    fail == 0
        ? 'SEAT-COUNT OK — 2-seat room honoured and bust order reported'
        : '$fail CHECK(S) FAILED',
  );
  exit(fail == 0 ? 0 : 1);
}

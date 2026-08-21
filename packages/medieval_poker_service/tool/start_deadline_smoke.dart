// A room told to await 2 humans should still start if only 1 shows up, once the
// startDeadline elapses (matchmaking no-show safeguard).
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
    case PromptKind.payChoice: return act(GameActionKind.payChoice, {'useChip': false});
    case PromptKind.chipSell: return act(GameActionKind.sellChip, {'sell': false});
    default: return act(GameActionKind.pass);
  }
}

Future<void> main() async {
  final server = GameServer(
    turnTimeout: const Duration(milliseconds: 150),
    startDeadline: const Duration(milliseconds: 800), // force-start soon
    config: const PokerConfig(),
  );
  final http = await server.start(host: '127.0.0.1', port: 0);
  // Announce a 2-human room but only ONE client connects.
  final ws = await WebSocket.connect('ws://127.0.0.1:${http.port}/game?room=t1&seat=0&humans=2');
  var welcomed = false, started = false, gameOver = false;
  ws.listen((data) {
    final m = ServerMessage.fromJson(jsonDecode(data as String) as Map<String, dynamic>);
    switch (m.type) {
      case ServerMsgType.welcome: welcomed = true;
      case ServerMsgType.prompt:
        started = true; // prompts only flow once the loop is running
        ws.add(jsonEncode(_respond(PromptSpec.fromJson(m.payload)).toJson()));
      case ServerMsgType.state: started = true;
      case ServerMsgType.gameOver: gameOver = true;
      default: break;
    }
  });

  final start = DateTime.now();
  while (!gameOver && DateTime.now().difference(start).inSeconds < 40) {
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }
  await ws.close();
  await http.close(force: true);

  check(welcomed, 'welcomed');
  check(started, 'game started despite only 1 of 2 humans (deadline force-start)');
  check(gameOver, 'ran to completion');
  print(fail == 0 ? 'START-DEADLINE OK — solo human force-started after the deadline and finished' : '$fail CHECK(S) FAILED');
  exit(fail == 0 ? 0 : 1);
}

// The ?timed= WS hint overrides a room's level mode: timed=0 → no level clock
// (levelSecondsLeft null); timed=1 → a countdown is present.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
    default: return act(GameActionKind.pass);
  }
}

/// Connect with the given timed hint, return whether any observed state had a
/// non-null levelSecondsLeft.
Future<bool> hasClock(int port, String room, String timed) async {
  final ws = await WebSocket.connect('ws://127.0.0.1:$port/game?room=$room&seat=0&humans=1&timed=$timed');
  var sawClock = false;
  var states = 0;
  ws.listen((d) {
    final m = ServerMessage.fromJson(jsonDecode(d as String) as Map<String, dynamic>);
    if (m.type == ServerMsgType.prompt) {
      ws.add(jsonEncode(_respond(PromptSpec.fromJson(m.payload)).toJson()));
    } else if (m.type == ServerMsgType.state) {
      states++;
      if (TableSnapshot.fromJson(m.payload).levelSecondsLeft != null) sawClock = true;
    }
  }, onError: (_) {});
  final start = DateTime.now();
  while (states < 3 && DateTime.now().difference(start).inSeconds < 10) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  await ws.close();
  return sawClock;
}

Future<void> main() async {
  // Server default config is timed:true; the per-room hint must override it.
  final server = GameServer(turnTimeout: const Duration(milliseconds: 30));
  final http = await server.start(host: '127.0.0.1', port: 0);

  final timedOff = await hasClock(http.port, 'off', '0');
  final timedOn = await hasClock(http.port, 'on', '1');

  await http.close(force: true);
  check(!timedOff, 'timed=0 → no level clock (levelSecondsLeft null)');
  check(timedOn, 'timed=1 → level clock present');
  print(fail == 0
      ? 'TIMED-PASSTHROUGH OK — ?timed= overrides the room level mode'
      : '$fail CHECK(S) FAILED');
  exit(fail == 0 ? 0 : 1);
}

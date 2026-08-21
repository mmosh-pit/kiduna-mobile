// Fresh-room reconnect guard: a ?resume=1 reconnect to a room this instance no
// longer has (service restarted/crashed) is rejected with `match_not_found`
// instead of silently starting a brand-new AI game. A fresh join still creates
// the room, and a resume to a room that DOES exist proceeds normally.
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
  } else {
    print('  ok: $label');
  }
}

/// Connect and report: welcome / error:<code> / closed / timeout.
Future<String> attempt(int port, String room, int seat,
    {bool resume = false}) async {
  final q = 'room=$room&seat=$seat&humans=2${resume ? '&resume=1' : ''}';
  final ws = await WebSocket.connect('ws://127.0.0.1:$port/game?$q');
  final done = Completer<String>();
  ws.listen((d) {
    final m = ServerMessage.fromJson(jsonDecode(d as String) as Map<String, dynamic>);
    if (m.type == ServerMsgType.welcome && !done.isCompleted) done.complete('welcome');
    if (m.type == ServerMsgType.error && !done.isCompleted) {
      done.complete('error:${m.payload['code']}');
    }
  }, onDone: () {
    if (!done.isCompleted) done.complete('closed');
  }, onError: (_) {});
  final r = await done.future
      .timeout(const Duration(seconds: 3), onTimeout: () => 'timeout');
  await ws.close();
  return r;
}

Future<void> main() async {
  // Open mode; humansToStart 2 so a solo connect keeps the room alive, unstarted.
  final server = GameServer(humansToStart: 2, config: const PokerConfig());
  final http = await server.start(host: '127.0.0.1', port: 0);
  final port = http.port;

  final fresh = await attempt(port, 'R', 0);
  check(fresh == 'welcome', 'fresh join creates + welcomes into room R (got $fresh)');

  final gone = await attempt(port, 'GONE', 0, resume: true);
  check(gone == 'error:match_not_found',
      'resume to a lost room is refused with match_not_found (got $gone)');

  final existing = await attempt(port, 'R', 1, resume: true);
  check(existing == 'welcome',
      'resume to an existing room proceeds normally (got $existing)');

  await server.shutdown();
  print(fail == 0
      ? 'RECONNECT-GUARD OK — lost-room resume rejected; fresh join + live-room resume still work'
      : '$fail CHECK(S) FAILED');
  exit(fail == 0 ? 0 : 1);
}

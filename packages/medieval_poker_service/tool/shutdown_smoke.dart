// Graceful shutdown: on GameServer.shutdown() (what the SIGTERM handler calls
// on a deploy), a connected client receives a clear `server_restart` error
// message — instead of a silent freeze — and the socket then closes.
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

Future<void> main() async {
  // Open mode (no auth), humansToStart 2 so the room lingers with our one client
  // seated (it doesn't matter either way — shutdown hits any live socket).
  final server = GameServer(humansToStart: 2, config: const PokerConfig());
  final http = await server.start(host: '127.0.0.1', port: 0);

  final ws = await WebSocket.connect(
      'ws://127.0.0.1:${http.port}/game?room=t1&seat=0&humans=2');

  final welcomed = Completer<void>();
  final errored = Completer<Map<String, dynamic>>();
  var closed = false;
  ws.listen((d) {
    final m = ServerMessage.fromJson(jsonDecode(d as String) as Map<String, dynamic>);
    if (m.type == ServerMsgType.welcome && !welcomed.isCompleted) {
      welcomed.complete();
    }
    if (m.type == ServerMsgType.error && !errored.isCompleted) {
      errored.complete(m.payload);
    }
  }, onDone: () => closed = true, onError: (_) {});

  await welcomed.future.timeout(const Duration(seconds: 3));
  print('  (client welcomed; triggering graceful shutdown)');

  await server.shutdown();

  final payload = await errored.future
      .timeout(const Duration(seconds: 3), onTimeout: () => <String, dynamic>{});
  check(payload['code'] == 'server_restart',
      'client got server_restart error (got ${payload['code']})');
  check((payload['message'] as String?)?.isNotEmpty == true,
      'error carries a human-readable message');

  // Give the close frame a beat to land.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  check(closed, 'socket closed after the shutdown notice');

  await ws.close();
  print(fail == 0
      ? 'SHUTDOWN OK — clients are told the match ended (server_restart) before the socket closes'
      : '$fail CHECK(S) FAILED');
  exit(fail == 0 ? 0 : 1);
}

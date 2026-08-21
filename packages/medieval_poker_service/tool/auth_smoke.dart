// With a jwtSecret configured, the server must reject a WS upgrade that lacks a
// valid seat/room-bound ticket, and accept one that has it.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:medieval_poker_engine/medieval_poker_engine.dart';
import 'package:medieval_poker_engine/protocol.dart';
import 'package:medieval_poker_service/medieval_poker_service.dart';

int fail = 0;
void check(bool c, String label) { if (!c) { fail++; print('  FAIL: $label'); } }

String _b64(List<int> b) => base64Url.encode(b).replaceAll('=', '');
String mint(String secret, Map<String, dynamic> payload) {
  final h = _b64(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
  final p = _b64(utf8.encode(jsonEncode(payload)));
  final sig = _b64(Hmac(sha256, utf8.encode(secret)).convert(utf8.encode('$h.$p')).bytes);
  return '$h.$p.$sig';
}

Future<bool> rejected(String url) async {
  try {
    final ws = await WebSocket.connect(url);
    await ws.close();
    return false; // upgraded → not rejected
  } catch (_) {
    return true; // upgrade refused (401)
  }
}

Future<bool> welcomed(String url) async {
  final ws = await WebSocket.connect(url);
  final done = Completer<bool>();
  ws.listen((d) {
    final m = ServerMessage.fromJson(jsonDecode(d as String) as Map<String, dynamic>);
    if (m.type == ServerMsgType.welcome && !done.isCompleted) done.complete(true);
  }, onError: (_) {}, onDone: () { if (!done.isCompleted) done.complete(false); });
  final ok = await done.future.timeout(const Duration(seconds: 3), onTimeout: () => false);
  await ws.close();
  return ok;
}

Future<void> main() async {
  const secret = 'shared-secret';
  final server = GameServer(config: const PokerConfig(), jwtSecret: secret, humansToStart: 2);
  final http = await server.start(host: '127.0.0.1', port: 0);
  final base = 'ws://127.0.0.1:${http.port}/game?room=t1';
  final soon = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
  Map<String, dynamic> claim(int seat) =>
      {'typ': 'game', 'roomId': 'rid', 'code': 't1', 'seat': seat, 'userId': 'u$seat', 'exp': soon};

  check(await rejected('$base&seat=0'), 'no token → rejected');
  check(await rejected('$base&seat=0&token=garbage'), 'bad token → rejected');
  check(await rejected('$base&seat=0&token=${mint("wrong", claim(0))}'), 'wrong-secret token → rejected');
  check(await rejected('$base&seat=0&token=${mint(secret, claim(1))}'), 'seat-mismatch token → rejected');
  check(await welcomed('$base&seat=0&token=${mint(secret, claim(0))}'), 'valid token → welcomed');

  await http.close(force: true);
  print(fail == 0
      ? 'AUTH OK — no/bad/wrong-secret/seat-mismatch tokens rejected; valid ticket admitted'
      : '$fail CHECK(S) FAILED');
  exit(fail == 0 ? 0 : 1);
}

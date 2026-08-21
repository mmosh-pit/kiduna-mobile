// Seat-ownership lock: after user A claims seat 0, a *different* user's (valid,
// seat-0-bound) ticket is refused, while A's own reconnect is accepted.
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
String mint(String secret, Map<String, dynamic> p) {
  final h = _b64(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
  final pl = _b64(utf8.encode(jsonEncode(p)));
  final sig = _b64(Hmac(sha256, utf8.encode(secret)).convert(utf8.encode('$h.$pl')).bytes);
  return '$h.$pl.$sig';
}

/// Connect and report: did we get welcomed, or an error/close instead?
Future<String> attempt(int port, String token) async {
  final ws = await WebSocket.connect('ws://127.0.0.1:$port/game?room=t1&seat=0&token=$token');
  final done = Completer<String>();
  ws.listen((d) {
    final m = ServerMessage.fromJson(jsonDecode(d as String) as Map<String, dynamic>);
    if (m.type == ServerMsgType.welcome && !done.isCompleted) done.complete('welcome');
    if (m.type == ServerMsgType.error && !done.isCompleted) done.complete('error:${m.payload['code']}');
  }, onDone: () { if (!done.isCompleted) done.complete('closed'); }, onError: (_) {});
  final r = await done.future.timeout(const Duration(seconds: 3), onTimeout: () => 'timeout');
  await ws.close();
  return r;
}

Future<void> main() async {
  const secret = 'seat-lock-secret';
  final soon = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
  Map<String, dynamic> claim(String uid) =>
      {'typ': 'game', 'roomId': 'rid', 'code': 't1', 'seat': 0, 'userId': uid, 'exp': soon};
  // humansToStart 2 keeps the room from starting on A alone, so seat 0 stays a
  // claimed-but-idle RemoteAgent while we probe it.
  final server = GameServer(jwtSecret: secret, humansToStart: 2, config: const PokerConfig());
  final http = await server.start(host: '127.0.0.1', port: 0);

  final a1 = await attempt(http.port, mint(secret, claim('userA')));
  check(a1 == 'welcome', 'user A claims seat 0 (got $a1)');

  final b = await attempt(http.port, mint(secret, claim('userB')));
  check(b.startsWith('error') || b == 'closed', 'user B refused seat 0 (got $b)');

  final a2 = await attempt(http.port, mint(secret, claim('userA')));
  check(a2 == 'welcome', 'user A reconnects to their own seat 0 (got $a2)');

  await http.close(force: true);
  print(fail == 0
      ? 'SEAT-LOCK OK — seat locked to first claimant; other user refused; owner reconnects'
      : '$fail CHECK(S) FAILED');
  exit(fail == 0 ? 0 : 1);
}

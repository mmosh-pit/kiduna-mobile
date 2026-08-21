// Verifies the HS256 game-ticket validator: accepts a well-formed unexpired
// 'game' token bound to the seat/room, and rejects tampering / wrong secret /
// expiry / wrong type. Mints tokens the same way @fastify/jwt does (HS256).
import 'dart:convert';
import 'package:crypto/crypto.dart';
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

void main() {
  const secret = 's3cr3t-shared-with-node';
  const v = GameTokenVerifier(secret);
  final soon = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
  final past = DateTime.now().subtract(const Duration(minutes: 1)).millisecondsSinceEpoch ~/ 1000;

  Map<String, dynamic> claims({int seat = 1, int? exp}) => {
        'typ': 'game', 'roomId': 'room-uuid', 'code': 't1', 'seat': seat,
        'userId': 'user-1', 'iat': soon - 3600, 'exp': exp ?? soon,
      };

  // Valid.
  final good = v.verify(mint(secret, claims()));
  check(good != null, 'valid token accepted');
  check(good?.seat == 1, 'seat parsed');
  check(good?.code == 't1', 'code parsed');
  check(good?.userId == 'user-1', 'userId parsed');

  // Tampered signature.
  final t = mint(secret, claims());
  check(v.verify('${t.substring(0, t.length - 2)}xx') == null, 'tampered signature rejected');

  // Wrong secret.
  check(const GameTokenVerifier('other').verify(mint(secret, claims())) == null, 'wrong-secret rejected');

  // Expired.
  check(v.verify(mint(secret, claims(exp: past))) == null, 'expired rejected');

  // Wrong type.
  final notGame = {...claims()}..['typ'] = 'auth';
  check(v.verify(mint(secret, notGame)) == null, 'non-game typ rejected');

  // Garbage.
  check(v.verify('not.a.jwt') == null, 'garbage rejected');
  check(v.verify('') == null, 'empty rejected');

  print(fail == 0 ? 'TOKEN OK — valid accepted; tamper/wrong-secret/expiry/type/garbage rejected' : '$fail CHECK(S) FAILED');
}

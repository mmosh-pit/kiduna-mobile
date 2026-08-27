// Per-room table size: a room created with ?seats=N seats exactly N players,
// independent of the server-wide default, and later joiners inherit that size.
//
// Tournament heats run short-handed when no-shows leave a table light, so two-
// and three-seat rooms are ordinary cases. The game is ante-based (no blinds),
// so the engine needs no special casing — only the room did.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:medieval_poker_engine/medieval_poker_engine.dart';
import 'package:medieval_poker_engine/protocol.dart';
import 'package:medieval_poker_service/medieval_poker_service.dart';

int fail = 0;
void check(bool c, String label) {
  if (!c) {
    fail++;
    print('  FAIL: $label');
  } else {
    print('  ok:   $label');
  }
}

/// Connect and return the seat count the server reports at handshake.
Future<int?> seatsSeen(int port, String room, {String? query}) async {
  final ws = await WebSocket.connect(
    'ws://127.0.0.1:$port/game?room=$room&seat=0${query ?? ''}',
  );
  final done = Completer<int?>();
  ws.listen(
    (d) {
      final m = ServerMessage.fromJson(
        jsonDecode(d as String) as Map<String, dynamic>,
      );
      if (m.type == ServerMsgType.welcome && !done.isCompleted) {
        done.complete(m.payload['seats'] as int?);
      }
    },
    onDone: () {
      if (!done.isCompleted) done.complete(null);
    },
    onError: (_) {},
  );
  final r = await done.future.timeout(
    const Duration(seconds: 4),
    onTimeout: () => null,
  );
  await ws.close();
  return r;
}

Future<void> main() async {
  // Server default is 4; every room below overrides it or inherits it.
  final server = GameServer(
    seatsPerRoom: 4,
    // Rooms stay parked: the seat count is known at handshake, so nothing
    // needs to start for this to be observable.
    humansToStart: 2,
    config: const PokerConfig(),
  );
  final http = await server.start(host: '127.0.0.1', port: 0);
  final port = http.port;
  print('seats smoke on :$port');

  check(
    await seatsSeen(port, 'heads_up', query: '&seats=2') == 2,
    'heads-up room seats 2',
  );
  check(
    await seatsSeen(port, 'three', query: '&seats=3') == 3,
    'three-handed room seats 3',
  );
  check(
    await seatsSeen(port, 'full', query: '&seats=4') == 4,
    'four-handed room seats 4',
  );
  check(
    await seatsSeen(port, 'defaulted') == 4,
    'no ?seats= falls back to the server default',
  );

  // Rooms are independent: the heads-up room above must not have resized the
  // server or any other room.
  check(
    await seatsSeen(port, 'later') == 4,
    'a later room still uses the server default',
  );

  // A second connection to a live room inherits its size rather than rebuilding.
  check(
    await seatsSeen(port, 'heads_up', query: '&seats=4') == 2,
    'joining a live room inherits its size, ignoring ?seats=',
  );

  // Out-of-range requests clamp instead of crashing or seating nonsense.
  check(
    await seatsSeen(port, 'tiny', query: '&seats=1') == GameServer.minSeats,
    'seats=1 clamps up to the minimum table',
  );
  check(
    await seatsSeen(port, 'huge', query: '&seats=99') == GameServer.maxSeats,
    'seats=99 clamps down to the maximum table',
  );
  check(
    await seatsSeen(port, 'junk', query: '&seats=abc') == 4,
    'unparseable ?seats= falls back to the default',
  );

  await server.shutdown();

  // ── The signed table size beats the query string ──────────────────────────
  // The first connection to a room fixes its size, so a client supplying its
  // own ?seats= could seat a table the lobby never authorised. With a secret
  // configured, the signed claim wins.
  const secret = 'seats-token-secret';
  final signed = GameServer(
    seatsPerRoom: 4,
    humansToStart: 2,
    jwtSecret: secret,
    config: const PokerConfig(),
  );
  final signedHttp = await signed.start(host: '127.0.0.1', port: 0);
  final sp = signedHttp.port;

  final soon =
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
      1000;
  String ticket(String code, int seat, int? seats) => _mint(secret, {
    'typ': 'game',
    'roomId': 'rid-$code',
    'code': code,
    'seat': seat,
    'userId': 'u1',
    if (seats != null) 'seats': seats,
    'exp': soon,
  });

  final t2 = ticket('signed2', 0, 2);
  check(
    await seatsSeen(sp, 'signed2', query: '&seats=4&token=$t2') == 2,
    'the signed seat count wins over a larger ?seats=',
  );

  final t4 = ticket('signed4', 0, 4);
  check(
    await seatsSeen(sp, 'signed4', query: '&seats=2&token=$t4') == 4,
    'the signed seat count wins over a smaller ?seats=',
  );

  final tNone = ticket('unsigned', 0, null);
  check(
    await seatsSeen(sp, 'unsigned', query: '&seats=3&token=$tNone') == 3,
    'a token without a seat claim falls back to ?seats=',
  );

  await signed.shutdown();
  print(fail == 0 ? 'PASS' : 'FAILED ($fail)');
  exit(fail == 0 ? 0 : 1);
}

String _b64(List<int> b) => base64Url.encode(b).replaceAll('=', '');

/// Mints an HS256 ticket the same way the Node lobby does.
String _mint(String secret, Map<String, dynamic> payload) {
  final h = _b64(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
  final p = _b64(utf8.encode(jsonEncode(payload)));
  final sig = _b64(
    Hmac(sha256, utf8.encode(secret)).convert(utf8.encode('$h.$p')).bytes,
  );
  return '$h.$p.$sig';
}

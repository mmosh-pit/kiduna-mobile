import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Claims carried by the lobby's game ticket.
class GameTokenClaims {
  final String? userId;
  final int? seat;
  final String? code;
  final String? roomId;
  const GameTokenClaims({this.userId, this.seat, this.code, this.roomId});
}

/// Verifies the short-lived HS256 game ticket the Node lobby mints
/// (`jwt.sign({typ:'game', roomId, code, seat, userId}, …)` with the shared
/// `JWT_SECRET`). Returns the claims for a valid, unexpired `game` token, or
/// null for anything malformed / wrong-signature / expired / wrong-type.
class GameTokenVerifier {
  final String secret;
  const GameTokenVerifier(this.secret);

  GameTokenClaims? verify(String token, {DateTime? now}) {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    // Signature check over "header.payload".
    final signingInput = '${parts[0]}.${parts[1]}';
    final expected = _b64UrlNoPad(
      Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(signingInput)).bytes,
    );
    if (!_constEq(expected, parts[2])) return null;

    final Map<String, dynamic> payload;
    try {
      payload =
          jsonDecode(utf8.decode(_b64UrlDecode(parts[1]))) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }

    if (payload['typ'] != 'game') return null;
    final exp = payload['exp'];
    if (exp is int) {
      final nowSecs = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
      if (nowSecs >= exp) return null; // expired
    }

    final seat = payload['seat'];
    return GameTokenClaims(
      userId: payload['userId'] as String?,
      seat: seat is int ? seat : (seat is num ? seat.toInt() : null),
      code: payload['code'] as String?,
      roomId: payload['roomId'] as String?,
    );
  }

  static String _b64UrlNoPad(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  static List<int> _b64UrlDecode(String s) {
    final pad = s.length % 4;
    return base64Url.decode(pad == 0 ? s : s + ('=' * (4 - pad)));
  }

  // Length-independent-ish comparison to avoid timing leaks on the signature.
  static bool _constEq(String a, String b) {
    if (a.length != b.length) return false;
    var r = 0;
    for (var i = 0; i < a.length; i++) {
      r |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return r == 0;
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:medieval_poker_service/medieval_poker_service.dart';

/// Entry point for the authoritative Medieval Poker game-service.
///   dart run bin/server.dart            # binds 0.0.0.0:8080
///   PORT=9000 dart run bin/server.dart
Future<void> main() async {
  final env = Platform.environment;
  final port = int.tryParse(env['PORT'] ?? '') ?? 8080;
  // When the Node backend supervises this process it binds loopback-only
  // (127.0.0.1) so the game-service isn't publicly exposed — Node reverse-
  // proxies the /game WebSocket. Standalone runs default to 0.0.0.0.
  final host = env['GAME_SERVICE_HOST'] ?? '0.0.0.0';
  // Share the lobby's secret so the game ticket can be validated. Absent →
  // open mode (local dev): any socket may take any seat.
  final jwtSecret = env['GAME_JWT_SECRET'] ?? env['JWT_SECRET'];
  // Force-start a room this long after its first connection if not everyone
  // arrives, so a matchmade table isn't stuck on a no-show.
  final startDeadline = Duration(
      seconds: int.tryParse(env['GAME_START_DEADLINE_SECONDS'] ?? '') ?? 30);

  // Report finished games to the backend (results/leaderboard). Configured only
  // when the backend URL is known; the shared secret authenticates the call.
  final backendUrl = env['KINSHIP_BACKEND_URL'] ?? env['BACKEND_URL'];
  final serviceSecret = env['GAME_SERVICE_SECRET'];
  final reporter = backendUrl == null
      ? null
      : _httpReporter(Uri.parse('$backendUrl/games/internal/result'),
          serviceSecret);

  final server = GameServer(
    jwtSecret: jwtSecret,
    startDeadline: startDeadline,
    resultReporter: reporter,
  );
  final http = await server.start(host: host, port: port);
  stdout.writeln('Medieval Poker game-service listening on '
      'ws://${http.address.host}:${http.port}/game '
      '(auth: ${jwtSecret != null ? 'on' : 'off'}, '
      'results: ${reporter != null ? 'on' : 'off'})');

  // Graceful shutdown: a rolling deploy (or Node supervisor) sends SIGTERM;
  // Ctrl-C sends SIGINT. Tell connected clients the match ended cleanly, close
  // sockets, then exit — instead of vanishing mid-hand. (SIGKILL can't be
  // caught, so a hard kill remains a silent drop.)
  var draining = false;
  Future<void> drain(ProcessSignal sig) async {
    if (draining) return;
    draining = true;
    stdout.writeln('game-service: $sig received — draining active tables');
    try {
      await server.shutdown();
    } catch (_) {/* best-effort */}
    exit(0);
  }

  ProcessSignal.sigterm.watch().listen(drain);
  ProcessSignal.sigint.watch().listen(drain);
}

/// A best-effort JSON POST of the result to the backend.
Future<void> Function(GameResultReport) _httpReporter(
    Uri uri, String? secret) {
  return (GameResultReport report) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      if (secret != null) req.headers.set('X-Game-Service-Secret', secret);
      req.add(utf8.encode(jsonEncode(report.toJson())));
      final resp = await req.close().timeout(const Duration(seconds: 8));
      await resp.drain<void>(null);
    } catch (e) {
      stderr.writeln('result report failed for room ${report.roomCode}: $e');
    } finally {
      client.close(force: true);
    }
  };
}

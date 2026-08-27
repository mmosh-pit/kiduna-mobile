import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:medieval_poker_engine/medieval_poker_engine.dart';
import 'package:medieval_poker_engine/protocol.dart';
import 'package:medieval_poker_engine/service.dart';

import 'game_room.dart';
import 'game_token.dart';
import 'result_report.dart';

/// A live room + its sockets. Seats not held by a *connected* human are AI.
class _LiveRoom {
  final String id;
  final PokerGame game;
  final PokerConfig config; // this room's effective config (may override timed)
  final List<PlayerAgent> agents;
  final Map<int, WebSocket> sockets = {}; // seat → live socket
  final Map<int, Timer> graceTimers = {}; // seat → AI-takeover countdown

  /// seat → userId of the human who held it (kept even after an AI takeover),
  /// so the end-of-game result attributes each seat to the right player.
  final Map<int, String> seatUserIds = {};

  late final GameRoom room;
  DateTime? levelStartedAt; // when the current timed level began
  Timer? levelTimer;
  Timer? emptyTeardown; // remove an abandoned, not-yet-started room
  Timer? startDeadlineTimer; // force-start on no-show (matchmaking safeguard)
  bool started = false;

  /// Humans this room waits for before starting. Seeded from the server
  /// default and raised by a connecting client's `?humans=` hint (the lobby
  /// passes the seated-human count so a multi-human room waits for everyone).
  int startThreshold;

  _LiveRoom(this.id, this.game, this.agents,
      {required this.config, this.startThreshold = 1});

  void disposeTimers() {
    levelTimer?.cancel();
    emptyTeardown?.cancel();
    startDeadlineTimer?.cancel();
    for (final t in graceTimers.values) {
      t.cancel();
    }
    graceTimers.clear();
  }
}

/// Authoritative WebSocket game server (dart:io). One connection = one seat.
///
/// Transport: `ws://host:port/game?room=<code>&seat=<n>&humans=<N>&token=<jwt>`.
///
/// Robustness (Phase 4):
/// - **Auth** — with a [jwtSecret], every connection must present a valid lobby
///   ticket bound to the requested room+seat; without one it runs open (dev).
/// - **Reconnection** — a dropped socket doesn't immediately forfeit the seat.
///   The agent detaches (the turn clock still guards against stalls); on
///   reconnect it re-attaches, the client gets an immediate `resync`, and any
///   outstanding prompt is re-sent. Only after a grace window does AI take over.
/// - **Teardown** — abandoned, never-started rooms are reaped.
class GameServer {
  final int seatsPerRoom;
  final Duration turnTimeout;
  final PokerConfig config;
  final int humansToStart;

  /// How long a seat is held for its human after a disconnect before AI takes
  /// over. Their stack/cards are untouched, so reconnecting reclaims the seat.
  final Duration graceDuration;

  /// How long an empty, never-started room lingers before being reaped.
  final Duration emptyRoomTimeout;

  /// If set, a room force-starts this long after its first connection even if
  /// [humansToStart] humans never all arrive (a no-show safeguard for
  /// matchmade rooms). Null (default) → wait indefinitely for the threshold.
  final Duration? startDeadline;

  /// Called once when a room's game ends, with the final standings, so the
  /// backend can persist results / leaderboard. Best-effort. Null → no reporting.
  final Future<void> Function(GameResultReport report)? resultReporter;

  final GameTokenVerifier? _verifier;
  final Random _rng;
  final Map<String, _LiveRoom> _rooms = {};
  HttpServer? _http;
  bool _shuttingDown = false;

  GameServer({
    this.seatsPerRoom = 4,
    this.turnTimeout = const Duration(seconds: 30),
    this.config = const PokerConfig(timedLevels: true),
    this.humansToStart = 1,
    this.graceDuration = const Duration(seconds: 20),
    this.emptyRoomTimeout = const Duration(seconds: 60),
    this.startDeadline,
    this.resultReporter,
    String? jwtSecret,
    Random? rng,
  })  : _verifier = jwtSecret != null ? GameTokenVerifier(jwtSecret) : null,
        _rng = rng ?? Random();

  Future<HttpServer> start({String host = '0.0.0.0', int port = 8080}) async {
    final server = await HttpServer.bind(host, port);
    _http = server;
    server.listen((req) async {
      if (req.uri.path == '/health') {
        req.response
          ..statusCode = 200
          ..write('ok');
        await req.response.close();
        return;
      }
      if (req.uri.path == '/game' && WebSocketTransformer.isUpgradeRequest(req)) {
        final q = req.uri.queryParameters;
        final roomId = q['room'] ?? 'default';
        var seat = int.tryParse(q['seat'] ?? '') ?? 0;
        final humansHint = int.tryParse(q['humans'] ?? '');
        final nameHint = q['name'];
        final resume = q['resume'] == '1' || q['resume'] == 'true';
        final timedHint = q['timed'] == null
            ? null
            : (q['timed'] == '1' || q['timed'] == 'true');

        // Authorize before upgrading when a secret is configured.
        String? userId;
        final verifier = _verifier;
        if (verifier != null) {
          final claims = verifier.verify(q['token'] ?? '');
          final okToken = claims != null &&
              claims.code == roomId &&
              (claims.seat == null || claims.seat == seat);
          if (!okToken) {
            req.response.statusCode = HttpStatus.unauthorized;
            await req.response.close();
            return;
          }
          seat = claims.seat ?? seat;
          userId = claims.userId;
        }

        final socket = await WebSocketTransformer.upgrade(req);
        _onConnect(roomId, seat, socket,
            humansHint: humansHint,
            userId: userId,
            timedHint: timedHint,
            nameHint: nameHint,
            resume: resume);
        return;
      }
      req.response.statusCode = HttpStatus.notFound;
      await req.response.close();
    });
    return server;
  }

  /// Graceful shutdown (e.g. on SIGTERM from a rolling deploy): tell every
  /// connected client the match has ended because the server is restarting —
  /// so they get a clear message instead of a silent freeze/timeout — then
  /// close all sockets and stop listening. In-progress games live in memory and
  /// cannot resume across a restart, so this makes the ending clean rather than
  /// preserving it. Idempotent; best-effort. (A hard crash / SIGKILL can't run
  /// this — that case is inherently lossy.)
  Future<void> shutdown({
    String message =
        'The server is restarting for an update. This match has ended — please start a new game.',
  }) async {
    if (_shuttingDown) return;
    _shuttingDown = true;
    for (final live in _rooms.values) {
      live.disposeTimers();
      for (final s in live.sockets.values) {
        _rawSend(
          s,
          ServerMessage(type: ServerMsgType.error, payload: {
            'code': 'server_restart',
            'message': message,
          }),
        );
      }
    }
    // Let those frames flush before tearing the sockets down.
    await Future<void>.delayed(const Duration(milliseconds: 150));
    for (final live in _rooms.values) {
      for (final s in live.sockets.values) {
        try {
          await s.close();
        } catch (_) {/* already closing */}
      }
    }
    _rooms.clear();
    try {
      await _http?.close(force: true);
    } catch (_) {/* already closed */}
    _http = null;
  }

  _LiveRoom _ensureRoom(String roomId, {bool? timedOverride}) {
    return _rooms.putIfAbsent(roomId, () {
      // The lobby can override timed-vs-hand-count levels per room (?timed=).
      final cfg = timedOverride == null
          ? config
          : config.copyWith(timedLevels: timedOverride);
      final players = [
        for (var i = 0; i < seatsPerRoom; i++)
          PokerPlayer(
              seat: i, name: 'Seat $i', stack: 100,
              personality: AiPersonality.values[i % AiPersonality.values.length])
            ..court = CourtMember.values[i % CourtMember.values.length],
      ];
      late final GameRoom room;
      final game = PokerGame(config: cfg, players: players, rng: _rng,
          onLog: (line) => room.captureLog(line));
      // Start every seat as AI; a connecting human swaps their seat's agent.
      final agents = <PlayerAgent>[
        for (var i = 0; i < seatsPerRoom; i++) AiAgent(i, brain: AiBrain(rng: _rng)),
      ];
      final live = _LiveRoom(roomId, game, agents,
          config: cfg, startThreshold: humansToStart);
      room = GameRoom(
        roomId: roomId,
        game: game,
        agents: agents,
        aiSeats: {for (var i = 0; i < seatsPerRoom; i++) i},
        send: (s, msg) => _sendTo(live, s, msg),
        levelSecondsLeft: () => _levelSecondsLeft(live),
      );
      live.room = room;
      return live;
    });
  }

  void _onConnect(String roomId, int seat, WebSocket socket,
      {int? humansHint,
      String? userId,
      bool? timedHint,
      String? nameHint,
      bool resume = false}) {
    // A resume (auto-reconnect) targets an in-progress game. If this instance
    // has no such room, the original was lost (service restarted/crashed, or it
    // lives on another instance) — reject cleanly instead of silently spinning
    // up a brand-new AI game the player never asked for. A fresh join (resume
    // false) still creates the room as normal.
    if (resume && !_rooms.containsKey(roomId)) {
      _rawSend(
          socket,
          const ServerMessage(type: ServerMsgType.error, payload: {
            'code': 'match_not_found',
            'message':
                'This match is no longer available — it ended or the server restarted. Please start a new game.',
          }));
      socket.close();
      return;
    }

    final live = _ensureRoom(roomId, timedOverride: timedHint);
    if (seat < 0 || seat >= seatsPerRoom) seat = 0;

    // Stamp the real player name onto the seat (replacing the "Seat N" default)
    // so every snapshot, the turn banner, and result blurbs show it. AI-held
    // seats keep their positional label.
    final nm = nameHint?.trim();
    if (nm != null && nm.isNotEmpty) live.game.players[seat].name = nm;

    // Seat-ownership lock: once a human userId claims a seat, a ticket for a
    // DIFFERENT user can't take it — even while the seat is unattached (grace)
    // or AI-held — which closes the common stale-ticket reclaim after a player
    // leaves and the seat is reassigned. (Airtight revocation across a legit
    // reassignment still needs Node seat-ownership authority; documented.)
    if (userId != null) {
      final owner = live.seatUserIds[seat];
      if (owner != null && owner != userId) {
        _rawSend(
            socket,
            const ServerMessage(type: ServerMsgType.error, payload: {
              'code': 'seat_taken',
              'message': 'That seat belongs to another player.',
            }));
        socket.close();
        return;
      }
      live.seatUserIds[seat] = userId; // also drives end-of-game stats
    }

    // This seat is reconnecting (or newly connecting): stop any pending
    // AI-takeover / room-reap countdowns.
    live.graceTimers.remove(seat)?.cancel();
    live.emptyTeardown?.cancel();
    live.emptyTeardown = null;

    // A lobby-created room passes the seated-human count so the loop waits for
    // everyone; take the largest hint seen, clamped to the seat count.
    if (humansHint != null) {
      final hint = humansHint.clamp(1, seatsPerRoom);
      if (hint > live.startThreshold) live.startThreshold = hint;
    }

    void sink(ServerMessage m) => _rawSend(socket, m);
    final existing = live.agents[seat];

    if (existing is RemoteAgent) {
      // Reconnect / contention. A live occupant owned by a *different* user is
      // protected from being kicked; a matching (or dev-mode) reconnect wins.
      if (existing.attached &&
          existing.userId != null &&
          userId != null &&
          existing.userId != userId) {
        _rawSend(
            socket,
            const ServerMessage(type: ServerMsgType.error, payload: {
              'code': 'seat_taken',
              'message': 'That seat is occupied.',
            }));
        socket.close();
        return;
      }
      final old = live.sockets[seat];
      live.sockets[seat] = socket;
      _rawSend(socket,
          ServerMessage(type: ServerMsgType.welcome, payload: {'seat': seat, 'room': roomId}));
      if (live.started) _rawSend(socket, live.room.resyncFor(seat));
      existing.attach(sink); // re-sends any outstanding prompt
      if (old != null && old != socket) old.close();
    } else {
      // Seat was AI (never human, or grace expired) → (re)claim as human.
      final remote =
          RemoteAgent(seat, sink: sink, userId: userId, timeout: turnTimeout);
      live.agents[seat] = remote;
      live.room.aiSeats.remove(seat);
      live.sockets[seat] = socket;
      _rawSend(socket,
          ServerMessage(type: ServerMsgType.welcome, payload: {'seat': seat, 'room': roomId}));
      if (live.started) _rawSend(socket, live.room.resyncFor(seat));
    }

    socket.listen(
      (data) {
        try {
          final msg = ClientMessage.fromJson(
              jsonDecode(data as String) as Map<String, dynamic>);
          if (msg.type == ClientMsgType.heartbeat) {
            _rawSend(socket, const ServerMessage(type: ServerMsgType.pong));
          } else if (msg.type == ClientMsgType.action) {
            final a = live.agents[seat];
            if (a is RemoteAgent) a.onResponse(msg);
          }
        } catch (_) {/* ignore malformed frames */}
      },
      onDone: () => _onDisconnect(live, seat, socket),
      onError: (_) => _onDisconnect(live, seat, socket),
      cancelOnError: true,
    );

    // Arm the start deadline on the first connection (a no-show safeguard for
    // matchmade rooms), then try to start.
    if (!live.started &&
        startDeadline != null &&
        live.startDeadlineTimer == null) {
      live.startDeadlineTimer =
          Timer(startDeadline!, () => _maybeStart(live, force: true));
    }
    _maybeStart(live);
  }

  /// Start the hand loop when enough humans are seated (rest are AI backfill),
  /// or immediately when [force]d by the start deadline (as long as ≥1 human is
  /// present). Idempotent.
  void _maybeStart(_LiveRoom live, {bool force = false}) {
    if (live.started) return;
    final humans = live.agents.whereType<RemoteAgent>().length;
    if (humans == 0) return;
    if (!force && humans < live.startThreshold) return;
    live.started = true;
    live.startDeadlineTimer?.cancel();
    _startLevelTimer(live);
    live.room.run().whenComplete(() {
      live.disposeTimers();
      if (live.game.isGameOver) _reportResult(live);
      _rooms.remove(live.id);
    });
  }

  /// Report the finished game's standings to the backend (best-effort).
  void _reportResult(_LiveRoom live) {
    final reporter = resultReporter;
    if (reporter == null) return;
    final g = live.game;
    final seats = [
      for (final p in g.players)
        SeatResult(
          seat: p.seat,
          userId: live.seatUserIds[p.seat],
          isAi: !live.seatUserIds.containsKey(p.seat),
          stack: p.stack,
        ),
    ];
    final report = GameResultReport(
      roomCode: live.id,
      winnerSeat: g.gameWinner?.seat,
      seats: seats,
    );
    Future(() => reporter(report)).catchError((_) {});
  }

  // Wall-clock ante levels: advance one level every levelDurationSeconds until
  // Sudden Death (then the fixed number of Sudden Death hands ends the game).
  void _startLevelTimer(_LiveRoom live) {
    if (!live.config.timedLevels) return;
    live.levelStartedAt = DateTime.now();
    final period = Duration(seconds: live.config.levelDurationSeconds);
    live.levelTimer = Timer.periodic(period, (t) {
      if (live.game.inSuddenDeath) {
        t.cancel();
        return;
      }
      live.game.advanceLevel();
      live.levelStartedAt = DateTime.now();
    });
  }

  int? _levelSecondsLeft(_LiveRoom live) {
    if (!live.config.timedLevels || live.game.inSuddenDeath) return null;
    final started = live.levelStartedAt;
    if (started == null) return live.config.levelDurationSeconds;
    final elapsed = DateTime.now().difference(started).inSeconds;
    final left = live.config.levelDurationSeconds - elapsed;
    return left < 0 ? 0 : left;
  }

  void _onDisconnect(_LiveRoom live, int seat, WebSocket socket) {
    // Ignore a stale socket's close (it was already superseded by a reconnect).
    if (live.sockets[seat] != socket) return;
    live.sockets.remove(seat);

    // Keep the seat as (detached) human — the turn clock still guards against
    // stalls — and hand it to AI only if grace elapses without a reconnect.
    final a = live.agents[seat];
    if (a is RemoteAgent) a.detach();
    live.graceTimers.remove(seat)?.cancel();
    live.graceTimers[seat] = Timer(graceDuration, () {
      live.graceTimers.remove(seat);
      final cur = live.agents[seat];
      if (cur is RemoteAgent && !cur.attached) {
        cur.cancel(); // release any pending prompt → default
        live.agents[seat] = AiAgent(seat, brain: AiBrain(rng: _rng));
        live.room.aiSeats.add(seat);
      }
    });

    // Reap a room that was abandoned before it ever started.
    if (live.sockets.isEmpty && !live.started) {
      live.emptyTeardown?.cancel();
      live.emptyTeardown = Timer(emptyRoomTimeout, () {
        if (live.sockets.isEmpty && !live.started) {
          live.disposeTimers();
          _rooms.remove(live.id);
        }
      });
    }
  }

  void _sendTo(_LiveRoom live, int seat, ServerMessage msg) {
    final s = live.sockets[seat];
    if (s != null) _rawSend(s, msg);
  }

  void _rawSend(WebSocket socket, ServerMessage msg) {
    if (socket.readyState == WebSocket.open) {
      socket.add(jsonEncode(msg.toJson()));
    }
  }
}

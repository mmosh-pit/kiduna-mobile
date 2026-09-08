import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:medieval_poker_engine/protocol.dart';
import 'game_session.dart';

/// One transport attempt: an incoming frame stream, a send sink, and a closer.
class _Conn {
  final Stream<dynamic> incoming;
  final void Function(dynamic frame) send;
  final void Function()? close;
  const _Conn(this.incoming, this.send, this.close);
}

/// A [GameSession] backed by the authoritative Dart game-service over a
/// WebSocket. Parses the server's [ServerMessage] stream into the session's
/// notifiers and turns [answer] calls into [ClientMessage] actions.
///
/// Phase 4: on an unexpected drop it **auto-reconnects** with backoff (rebuilding
/// the socket). The server holds the seat during a grace window and replays a
/// `resync` (+ any outstanding prompt) on reconnect, so play resumes where it
/// left off. A clean end (`gameOver`) does not reconnect.
///
/// The core is transport-agnostic, so it can be exercised in tests against an
/// in-memory channel with no socket (see [RemoteSession.debug]); the debug
/// transport does not reconnect (it can't be rebuilt).
class RemoteSession implements GameSession {
  @override
  final int viewerSeat;

  final bool isViewer;

  // null for the debug transport. `resume` is true for auto-reconnect attempts
  // (vs the initial connect), so the service can tell "resume an in-progress
  // game" from "join a fresh room" and refuse to fabricate a lost room.
  final _Conn Function(bool resume)? _opener;
  final Duration _heartbeatInterval;
  final int _maxReconnects;

  _Conn? _conn;
  StreamSubscription<dynamic>? _sub;
  Timer? _heartbeat;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  int _clientSeq = 0;
  bool _disposed = false;
  bool _terminal = false; // a server error ended this session — do not reconnect

  final _phase = ValueNotifier<SessionPhase>(SessionPhase.connecting);
  final _table = ValueNotifier<TableSnapshot?>(null);
  final _prompt = ValueNotifier<PromptSpec?>(null);
  final _handResult = ValueNotifier<HandResultView?>(null);
  final _gameOver = ValueNotifier<GameOverView?>(null);
  final _peek = ValueNotifier<String>('');
  final _errorMessage = ValueNotifier<String?>(null);

  RemoteSession._({
    required this.viewerSeat,
    this.isViewer = false,
    _Conn Function(bool resume)? opener,
    _Conn? initial,
    Duration heartbeat = const Duration(seconds: 15),
    this._maxReconnects = 5,
  })  : _opener = opener,
        _heartbeatInterval = heartbeat {
    _bind(initial ?? opener!(false)); // initial connect = a fresh join
    if (_heartbeatInterval > Duration.zero) {
      _heartbeat = Timer.periodic(_heartbeatInterval,
          (_) => _sendMessage(const ClientMessage(type: ClientMsgType.heartbeat)));
    }
  }

  /// Connect to `wsUrl` (e.g. `ws://host:port/game`) for [room] / [seat].
  ///
  /// [humans] tells the service how many humans to await before starting (the
  /// lobby passes the seated-human count). [token] is the lobby-minted game
  /// ticket — required once the service enforces auth, ignored before then.
  /// [name] is the viewer's display name, stamped onto their seat so every
  /// player sees real names instead of "Seat N".
  factory RemoteSession.connect({
    required String wsUrl,
    required String room,
    required int seat,
    int? humans,
    String? token,
    bool? timedLevels,
    String? name,
    bool isViewer = false,
  }) {
    final uri = Uri.parse(wsUrl).replace(queryParameters: {
      'room': room,
      'seat': '$seat',
      if (humans != null) 'humans': '$humans',
      'token': ?token,
      if (timedLevels != null) 'timed': timedLevels ? '1' : '0',
      if (name != null && name.isNotEmpty) 'name': name,
      if (isViewer) 'viewer': '1',
    });
    _Conn open(bool resume) {
      // A reconnect carries ?resume=1 so the service resumes the held seat if
      // the room still exists, or cleanly rejects if it's gone (e.g. the
      // service restarted) instead of dropping us into a brand-new game.
      final target = resume
          ? uri.replace(
              queryParameters: {...uri.queryParameters, 'resume': '1'})
          : uri;
      final channel = WebSocketChannel.connect(target);
      return _Conn(
        channel.stream,
        channel.sink.add,
        () => channel.sink.close(),
      );
    }

    return RemoteSession._(viewerSeat: seat, opener: open, isViewer: isViewer);
  }

  /// Build a session over an injected transport (in-memory channel / tests).
  /// Does not auto-reconnect.
  factory RemoteSession.debug({
    required int seat,
    required Stream<dynamic> incoming,
    required void Function(dynamic frame) send,
    void Function()? closeTransport,
  }) =>
      RemoteSession._(
        viewerSeat: seat,
        initial: _Conn(incoming, send, closeTransport),
        heartbeat: Duration.zero, // no timers under test
      );

  /// Test-only: a reopenable in-memory transport, so the auto-reconnect state
  /// machine (backoff → reopen → rebind → resync) can be exercised without a
  /// socket. [open] returns a fresh (incoming, send) each time it's called.
  @visibleForTesting
  factory RemoteSession.debugReconnectable({
    required int seat,
    required (Stream<dynamic>, void Function(dynamic)) Function() open,
    int maxReconnects = 5,
  }) =>
      RemoteSession._(
        viewerSeat: seat,
        opener: (_) {
          final (incoming, send) = open();
          return _Conn(incoming, send, null);
        },
        heartbeat: Duration.zero,
        maxReconnects: maxReconnects,
      );

  // ── GameSession ────────────────────────────────────────────────────────
  @override
  ValueListenable<SessionPhase> get phase => _phase;
  @override
  ValueListenable<TableSnapshot?> get table => _table;
  @override
  ValueListenable<PromptSpec?> get prompt => _prompt;
  @override
  ValueListenable<HandResultView?> get handResult => _handResult;
  @override
  ValueListenable<GameOverView?> get gameOver => _gameOver;
  @override
  ValueListenable<String> get peek => _peek;
  @override
  ValueListenable<String?> get errorMessage => _errorMessage;

  @override
  void answer(GameActionKind? kind, [Map<String, dynamic> payload = const {}]) {
    if (isViewer) return;
    final active = _prompt.value;
    if (active == null) return;
    _prompt.value = null; // optimistic dismiss; the next prompt/state refreshes
    _sendMessage(ClientMessage(
      type: ClientMsgType.action,
      promptId: active.promptId,
      actionKind: kind,
      payload: payload,
    ));
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _heartbeat?.cancel();
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _conn?.close?.call();
    _phase.dispose();
    _table.dispose();
    _prompt.dispose();
    _handResult.dispose();
    _gameOver.dispose();
    _peek.dispose();
    _errorMessage.dispose();
  }

  // ── Transport lifecycle ──────────────────────────────────────────────────
  void _bind(_Conn conn) {
    _conn = conn;
    _sub = conn.incoming.listen(
      _onFrame,
      onError: (_) => _onClosed(),
      onDone: _onClosed,
      cancelOnError: false,
    );
  }

  void _onClosed() {
    _sub?.cancel();
    _sub = null;
    // Clean end / torn down / a terminal server error (seat taken, server
    // restart) — a reconnect would only be refused or land in a fresh room.
    if (_disposed || _gameOver.value != null || _terminal) return;

    if (_opener != null && _reconnectAttempts < _maxReconnects) {
      // Reconnect with exponential backoff; the seat is held server-side during
      // the grace window, and a `resync` repaints the table on success.
      _prompt.value = null; // drop any stale prompt; resync re-sends the live one
      _setPhase(SessionPhase.connecting);
      final secs = (1 << _reconnectAttempts).clamp(1, 16);
      _reconnectAttempts++;
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(Duration(seconds: secs), () {
        if (_disposed) return;
        try {
          _bind(_opener(true)); // resume: don't accept a freshly-created room
        } catch (_) {
          _onClosed();
        }
      });
    } else {
      // No transport to rebuild (debug) → disconnected; retries exhausted → error.
      _setPhase(_opener == null ? SessionPhase.disconnected : SessionPhase.error);
    }
  }

  void _sendMessage(ClientMessage msg) {
    if (_disposed || _conn == null) return;
    final withSeq = ClientMessage(
      type: msg.type,
      seq: _clientSeq++,
      promptId: msg.promptId,
      actionKind: msg.actionKind,
      payload: msg.payload,
    );
    _conn!.send(jsonEncode(withSeq.toJson()));
  }

  void _onFrame(dynamic frame) {
    if (_disposed) return;
    _reconnectAttempts = 0; // a live frame means the link is healthy
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(frame as String) as Map<String, dynamic>;
    } catch (_) {
      return; // ignore malformed frames
    }
    final msg = ServerMessage.fromJson(json);
    switch (msg.type) {
      case ServerMsgType.welcome:
        _setPhase(SessionPhase.active);
      case ServerMsgType.state:
      case ServerMsgType.resync:
        _setPhase(SessionPhase.active);
        _table.value = TableSnapshot.fromJson(msg.payload);
        final p = msg.payload['prompt'];
        if (p is Map<String, dynamic>) _prompt.value = PromptSpec.fromJson(p);
      case ServerMsgType.prompt:
        _prompt.value = PromptSpec.fromJson(msg.payload);
      case ServerMsgType.reveal:
        final reason = msg.payload['reason'];
        if (reason is String && reason.isNotEmpty) _peek.value = reason;
      case ServerMsgType.handResult:
        _handResult.value = _handResultFrom(msg.payload);
      case ServerMsgType.gameOver:
        _gameOver.value = _gameOverFrom(msg.payload);
      case ServerMsgType.error:
        // A server error is terminal (seat taken, server restart, …): surface
        // its reason and don't reconnect — process it before the socket closes.
        final reason = msg.payload['message'];
        if (reason is String && reason.isNotEmpty) _errorMessage.value = reason;
        _terminal = true;
        _setPhase(SessionPhase.error);
      case ServerMsgType.pong:
        break;
    }
  }

  void _setPhase(SessionPhase p) {
    if (_disposed) return;
    _phase.value = p;
  }

  HandResultView _handResultFrom(Map<String, dynamic> p) {
    final won = p['won'] as bool? ?? false;
    final inHand = p['inHand'] as bool? ?? true;
    final detail = p['detail'] as String? ??
        (won ? 'You win the hand' : 'You lose the hand');
    return HandResultView(won: won, inHand: inHand, detail: detail);
  }

  GameOverView _gameOverFrom(Map<String, dynamic> p) {
    final winnerSeat = p['winnerSeat'] as int?;
    final youWon = p['youWon'] as bool? ?? (winnerSeat == viewerSeat);
    final standings = <StandingView>[
      for (final s in (p['standings'] as List? ?? const []))
        StandingView((s as Map)['seat'] as int, s['stack'] as int,
            name: s['name'] as String?),
    ];
    final detail = p['detail'] as String? ??
        (youWon ? 'You have taken the table.' : 'A rival takes the table.');
    return GameOverView(
      youWon: youWon,
      winnerSeat: winnerSeat,
      detail: detail,
      standings: standings,
    );
  }
}

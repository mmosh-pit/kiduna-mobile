import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:medieval_poker_engine/medieval_poker_engine.dart';
import 'package:medieval_poker_engine/protocol.dart';
import 'package:medieval_poker_engine/service.dart';

import '../../../data/models/sentinel_rules_model.dart';
import '../sentinel/sentinel_validator.dart';
import 'game_session.dart';

/// An offline (single-player-vs-AI) game exposed through the **same**
/// [GameSession] seam as the online table — so the shared snapshot renderer,
/// HUD and [PacedSession] drive it identically. It runs the authoritative
/// [GameDriver] in-process: opponents are [AiAgent]s and the human seat is a
/// loopback [RemoteAgent] whose prompts surface on [prompt] and whose responses
/// arrive via [answer]. No network, no turn clock.
class LocalSession implements GameSession {
  @override
  final int viewerSeat = 0;

  final PokerConfig config;
  @override
  final SentinelRules sentinelRules;
  final int opponentCount;
  final bool revealAll;
  final Random _rng;

  late final PokerGame _game;
  late final List<PlayerAgent> _agents;
  late final GameDriver _driver;
  late final RemoteAgent _human;

  final _phase = ValueNotifier<SessionPhase>(SessionPhase.active);
  final _table = ValueNotifier<TableSnapshot?>(null);
  final _prompt = ValueNotifier<PromptSpec?>(null);
  final _handResult = ValueNotifier<HandResultView?>(null);
  final _gameOver = ValueNotifier<GameOverView?>(null);
  final _peek = ValueNotifier<String>('');
  // Offline play never errors; kept to satisfy the GameSession contract.
  final _errorMessage = ValueNotifier<String?>(null);
  final _sentinelViolation = ValueNotifier<SentinelViolation?>(null);

  final List<String> _log = [];
  Set<int> get _aiSeats => {for (var i = 1; i <= opponentCount; i++) i};

  Timer? _levelTimer;
  DateTime? _levelStartedAt;
  int _peekToken = 0;
  Timer? _peekTimer;
  bool _disposed = false;

  LocalSession({
    this.config = const PokerConfig(timedLevels: true),
    this.sentinelRules = const SentinelRules(),
    this.opponentCount = 3,
    String humanName = 'You',
    this.revealAll = false,
    int? seed,
  }) : _rng = seed != null ? Random(seed) : Random() {
    final players = <PokerPlayer>[
      PokerPlayer(
          seat: 0, name: humanName, stack: config.startingStack, isHuman: true),
    ];
    for (var i = 0; i < opponentCount; i++) {
      final p = AiPersonality.values[i % AiPersonality.values.length];
      players.add(PokerPlayer(
        seat: i + 1,
        name: p.title,
        stack: config.startingStack,
        personality: p,
      )..court = CourtMember.values[(i + 1) % CourtMember.values.length]);
    }
    _game = PokerGame(
      config: config,
      players: players,
      rng: _rng,
      onLog: _appendLog,
      onPeek: _showPeek,
    );

    // The human plays through a loopback RemoteAgent: its prompts become
    // [prompt]; [answer] feeds its responses. A long timeout stands in for
    // "no turn clock offline" (it's cancelled the moment the player answers).
    _human = RemoteAgent(0,
        sink: _onHumanMessage, timeout: const Duration(hours: 6));
    _agents = <PlayerAgent>[
      _human,
      for (var i = 1; i <= opponentCount; i++)
        AiAgent(i, brain: AiBrain(rng: _rng)),
    ];
    _driver = GameDriver(
      game: _game,
      agents: _agents,
      onState: _onState,
      onResult: _onResult,
      onGameOver: _onGameOver,
    );
  }

  /// Begin the game loop. Safe to call once.
  void start() {
    _startLevelTimer();
    _driver.run().whenComplete(() => _levelTimer?.cancel());
  }

  // ── GameSession ──────────────────────────────────────────────────────────
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
  ValueListenable<SentinelViolation?> get sentinelViolation => _sentinelViolation;

  @override
  void answer(GameActionKind? kind, [Map<String, dynamic> payload = const {}]) {
    final active = _prompt.value;
    if (active == null) return;

    if (sentinelRules.isNotEmpty && kind != null) {
      final violation = _checkSentinel(kind, payload);
      if (violation != null) {
        _sentinelViolation.value = violation;
        return;
      }
    }
    _sentinelViolation.value = null;

    _prompt.value = null;
    _human.onResponse(ClientMessage(
      type: ClientMsgType.action,
      promptId: active.promptId,
      actionKind: kind,
      payload: payload,
    ));
  }

  SentinelViolation? _checkSentinel(GameActionKind kind, Map<String, dynamic> payload) {
    final player = _game.players[viewerSeat];
    PokerAction? action;
    switch (kind) {
      case GameActionKind.fold:
        action = const PokerAction.fold();
      case GameActionKind.check:
        action = const PokerAction.check();
      case GameActionKind.call:
        action = const PokerAction.call();
      case GameActionKind.bet:
        action = PokerAction.bet(payload['to'] as int? ?? 0);
      case GameActionKind.raise:
        action = PokerAction.raise(payload['to'] as int? ?? 0);
      default:
        break;
    }

    if (action != null) {
      return SentinelValidator.validateAction(sentinelRules, action, player);
    }

    if (kind == GameActionKind.playPower) {
      final cardId = payload['cardId'] as String?;
      if (cardId != null) {
        return SentinelValidator.validatePowerCard(sentinelRules, cardId);
      }
    }

    return null;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _levelTimer?.cancel();
    _peekTimer?.cancel();
    // Unblock and hand the seat to AI so the driver's background loop unwinds
    // fast instead of waiting on a human who has left.
    _human.cancel();
    _agents[0] = AiAgent(0, brain: AiBrain(rng: _rng));
    _phase.dispose();
    _table.dispose();
    _prompt.dispose();
    _handResult.dispose();
    _gameOver.dispose();
    _peek.dispose();
    _errorMessage.dispose();
    _sentinelViolation.dispose();
  }

  // ── Driver → session ───────────────────────────────────────────────────────
  void _onHumanMessage(ServerMessage msg) {
    if (_disposed) return;
    if (msg.type == ServerMsgType.prompt) {
      _prompt.value = PromptSpec.fromJson(msg.payload);
    }
  }

  void _onState(Set<int> reveal) {
    if (_disposed) return;
    final reveals = revealAll
        ? {for (var i = 0; i <= opponentCount; i++) i}
        : reveal;
    _table.value = serializeFor(
      _game,
      viewerSeat,
      aiSeats: _aiSeats,
      actingSeat: _game.actingPlayer?.seat,
      levelSecondsLeft: _levelSecondsLeft(),
      logTail: _logTail(),
      revealSeats: reveals,
    );
  }

  void _onResult(List<PotAward> awards) {
    if (_disposed) return;
    final human = _game.players[viewerSeat];
    final main = awards.isNotEmpty ? awards.first : null;
    final won = main != null && main.winners.contains(human);
    var total = 0;
    for (final a in awards) {
      if (a.winners.contains(human)) total += a.amount ~/ a.winners.length;
    }
    String detail;
    if (won) {
      final hand = human.showdownHand?.toString();
      detail = 'You won $total${hand != null ? ' with a $hand' : ''}';
    } else if (main != null) {
      detail =
          '${main.winners.map((w) => w.name).join(', ')} won the ${main.amount} pot';
    } else {
      detail = '';
    }
    _handResult.value =
        HandResultView(won: won, inHand: human.inHand, detail: detail);
  }

  void _onGameOver() {
    if (_disposed) return;
    final human = _game.players[viewerSeat];
    final winner = _game.gameWinner;
    final won = winner != null && winner.isHuman;
    String detail;
    if (won) {
      detail = _game.inSuddenDeath
          ? 'Victory! You survived Sudden Death with the biggest stack.'
          : 'Victory! You have taken all the coins on the table.';
    } else if (human.eliminated) {
      detail = 'Defeated. Your coffers are empty.';
    } else {
      detail = '${winner?.name ?? 'A rival'} wins Sudden Death on the chip count.';
    }
    final standings = [..._game.players]
      ..sort((a, b) => b.stack.compareTo(a.stack));
    _gameOver.value = GameOverView(
      youWon: won,
      winnerSeat: winner?.seat,
      detail: detail,
      standings: [
        for (final p in standings) StandingView(p.seat, p.stack, name: p.name)
      ],
    );
  }

  // ── Log / peek / level clock ────────────────────────────────────────────────
  void _appendLog(String message) {
    _log.add(message);
    if (_log.length > 60) _log.removeRange(0, _log.length - 60);
  }

  List<String> _logTail() =>
      List.unmodifiable(_log.length > 12 ? _log.sublist(_log.length - 12) : _log);

  void _showPeek(String message) {
    if (_disposed) return;
    _peek.value = message;
    final token = ++_peekToken;
    _peekTimer?.cancel();
    _peekTimer = Timer(const Duration(milliseconds: 4000), () {
      if (!_disposed && _peekToken == token) _peek.value = '';
    });
  }

  void _startLevelTimer() {
    if (!config.timedLevels) return;
    _levelStartedAt = DateTime.now();
    _levelTimer = Timer.periodic(Duration(seconds: config.levelDurationSeconds),
        (t) {
      if (_disposed || _game.inSuddenDeath) {
        t.cancel();
        return;
      }
      _game.advanceLevel();
      _levelStartedAt = DateTime.now();
    });
  }

  int? _levelSecondsLeft() {
    if (!config.timedLevels || _game.inSuddenDeath) return null;
    final started = _levelStartedAt;
    if (started == null) return config.levelDurationSeconds;
    final elapsed = DateTime.now().difference(started).inSeconds;
    final left = config.levelDurationSeconds - elapsed;
    return left < 0 ? 0 : left;
  }
}

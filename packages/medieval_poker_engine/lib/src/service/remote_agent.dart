import 'dart:async';

import 'package:medieval_poker_engine/medieval_poker_engine.dart';
import 'package:medieval_poker_engine/protocol.dart';

import 'agent.dart';

/// A [PlayerAgent] for a remote human. Each decision is sent as a [PromptSpec]
/// through [sendPrompt]; the matching client response (delivered via
/// [onResponse]) resolves it. If [timeout] elapses first (slow player /
/// disconnect), the window's safe default is applied.
class RemoteAgent implements PlayerAgent {
  @override
  final int seat;
  final Duration timeout;

  /// Stable identity (the lobby token's userId), when authenticated — used to
  /// authorize a reconnect to this seat. Null in open/dev mode.
  final String? userId;

  /// Current output sink (the live socket), or null while disconnected.
  void Function(ServerMessage msg)? _sink;

  RemoteAgent(
    this.seat, {
    void Function(ServerMessage msg)? sink,
    this.userId,
    this.timeout = const Duration(seconds: 30),
  }) : _sink = sink;

  @override
  bool get isAi => false;

  /// Whether a live socket is currently attached.
  bool get attached => _sink != null;

  int _promptCounter = 0;
  String? _pendingId;
  PromptSpec? _pendingSpec;
  Completer<ClientMessage?>? _pending;

  /// Point this agent's output at a (new) socket. Re-sends any outstanding
  /// prompt so a reconnecting player can still answer before the turn clock.
  void attach(void Function(ServerMessage msg) sink) {
    _sink = sink;
    final spec = _pendingSpec;
    if (spec != null) {
      sink(ServerMessage(type: ServerMsgType.prompt, payload: spec.toJson()));
    }
  }

  /// Stop sending (socket dropped). The outstanding prompt is deliberately NOT
  /// cancelled — the turn timeout still applies, so the game never stalls while
  /// the player is in their reconnection grace window.
  void detach() => _sink = null;

  /// Feed a client message in; resolves the outstanding prompt if it matches.
  void onResponse(ClientMessage msg) {
    if (msg.type != ClientMsgType.action) return;
    if (msg.promptId != _pendingId) return;
    final c = _pending;
    if (c != null && !c.isCompleted) {
      _clearPending();
      c.complete(msg);
    }
  }

  /// Cancel any outstanding prompt (grace expired / teardown) → default applies.
  void cancel() {
    final c = _pending;
    if (c != null && !c.isCompleted) {
      _clearPending();
      c.complete(null);
    }
  }

  void _clearPending() {
    _pending = null;
    _pendingId = null;
    _pendingSpec = null;
  }

  Future<ClientMessage?> _ask(PromptSpec Function(String id) build) {
    final id = 'p${seat}_${_promptCounter++}';
    final spec = build(id);
    final completer = Completer<ClientMessage?>();
    _pendingId = id;
    _pendingSpec = spec;
    _pending = completer;
    // Capture the result future BEFORE sending: an in-process loopback sink
    // (the offline LocalSession) can complete the response *synchronously*
    // during the send, which would otherwise null out `_pending` first.
    final result = completer.future.timeout(timeout, onTimeout: () {
      _clearPending();
      return null;
    });
    _sink?.call(
        ServerMessage(type: ServerMsgType.prompt, payload: spec.toJson()));
    return result;
  }

  int get _deadline => DateTime.now().millisecondsSinceEpoch + timeout.inMilliseconds;

  List<PromptOption> _cardOptions(List<PowerCard> cards) => [
        for (final c in cards)
          PromptOption(c.templateId, c.name, subtitle: c.description),
      ];

  @override
  void beginWindow() {}

  @override
  Future<int> chooseClass(List<String> classNames) async {
    final r = await _ask((id) => PromptSpec(
        promptId: id, kind: PromptKind.classPick, title: 'Choose your class',
        options: [for (var i = 0; i < classNames.length; i++) PromptOption('$i', classNames[i])],
        deadlineMs: _deadline));
    return (r?.payload['index'] as int?) ?? 0;
  }

  @override
  Future<int> chooseCourt(List<String> courtNames) async {
    final r = await _ask((id) => PromptSpec(
        promptId: id, kind: PromptKind.courtPick, title: 'Choose your Court',
        options: [for (var i = 0; i < courtNames.length; i++) PromptOption('$i', courtNames[i])],
        deadlineMs: _deadline));
    return (r?.payload['index'] as int?) ?? 0;
  }

  @override
  Future<List<String>?> buildDeck(List<PowerCard> pool, int target) async {
    final r = await _ask((id) => PromptSpec(
        promptId: id, kind: PromptKind.deckBuild, title: 'Build your Power Deck',
        options: _cardOptions(pool), deckTarget: target, deadlineMs: _deadline));
    final ids = (r?.payload['cardIds'] as List?)?.cast<String>();
    return ids; // null → auto full pool
  }

  @override
  Future<String?> pickWindowCard(PokerGame g, PokerPlayer p, PowerTiming timing,
      List<PowerCard> playable) async {
    final kind = switch (timing) {
      PowerTiming.setup => PromptKind.setupWindow,
      PowerTiming.round => PromptKind.roundWindow,
      PowerTiming.showdown => PromptKind.showdownWindow,
      PowerTiming.counter => PromptKind.roundWindow,
    };
    final r = await _ask((id) => PromptSpec(
        promptId: id, kind: kind, title: 'Play a ${timing.label} card?',
        options: _cardOptions(playable), optional: true, deadlineMs: _deadline));
    if (r?.actionKind != GameActionKind.playPower) return null;
    return r?.payload['cardId'] as String?;
  }

  @override
  Future<String?> pickItem(PokerGame g, PokerPlayer p, List<GameItem> playable) async {
    final r = await _ask((id) => PromptSpec(
        promptId: id, kind: PromptKind.itemPlay, title: 'Play a held Item?',
        options: [for (final it in playable) PromptOption(it.id, it.name, subtitle: it.description)],
        optional: true, deadlineMs: _deadline));
    if (r?.actionKind != GameActionKind.playItem) return null;
    return r?.payload['itemId'] as String?;
  }

  @override
  Future<String?> pickCounter(PokerGame g, PokerPlayer p, ChainEntry top,
      List<PowerCard> options) async {
    final r = await _ask((id) => PromptSpec(
        promptId: id, kind: PromptKind.counterWindow,
        title: 'Respond to ${top.card.name}?',
        options: _cardOptions(options), optional: true, deadlineMs: _deadline));
    if (r?.actionKind != GameActionKind.counter) return null;
    return r?.payload['cardId'] as String?;
  }

  @override
  Future<String?> pickBoardCounter(PokerGame g, PokerPlayer p, List<PowerCard> options) async {
    final r = await _ask((id) => PromptSpec(
        promptId: id, kind: PromptKind.boardCounter, title: 'A board card was dealt — respond?',
        options: _cardOptions(options), optional: true, deadlineMs: _deadline));
    if (r?.actionKind != GameActionKind.boardCounter) return null;
    return r?.payload['cardId'] as String?;
  }

  @override
  Future<int?> pickTargetSeat(PokerGame g, PokerPlayer p, PowerCard card,
      List<PokerPlayer> targets) async {
    final r = await _ask((id) => PromptSpec(
        promptId: id, kind: PromptKind.targetPick, title: '${card.name}: choose a target',
        options: [for (final t in targets) PromptOption('${t.seat}', t.name)],
        deadlineMs: _deadline));
    return r?.payload['seat'] as int?; // null → engine fallback
  }

  @override
  Future<int> pickItemMode(PokerGame g, PokerPlayer p, GameItem item, List<String> modes) async {
    final r = await _ask((id) => PromptSpec(
        promptId: id, kind: PromptKind.itemMode, title: '${item.name} — choose',
        options: [for (var i = 0; i < modes.length; i++) PromptOption('$i', modes[i])],
        deadlineMs: _deadline));
    return (r?.payload['index'] as int?) ?? 0;
  }

  @override
  Future<int> pickItemCardIndex(PokerGame g, PokerPlayer p, GameItem item, int mode,
      ItemPick pick) async {
    final r = await _ask((id) => PromptSpec(
        promptId: id, kind: PromptKind.itemPick, title: pick.prompt,
        options: [for (var i = 0; i < pick.options.length; i++) PromptOption('$i', pick.options[i])],
        optional: pick.optional, deadlineMs: _deadline));
    return (r?.payload['index'] as int?) ?? -1; // -1 → engine auto-picks
  }

  @override
  Future<bool> payWithChip(PokerGame g, PokerPlayer p, PowerCard card) async {
    final r = await _ask((id) => PromptSpec(
        promptId: id, kind: PromptKind.payChoice,
        title: '${card.name}: pay ${g.payCostOf(card)} coins?', deadlineMs: _deadline));
    return (r?.payload['useChip'] as bool?) ?? false; // default: pay coins
  }

  @override
  Future<bool> sellChip(PokerGame g, PokerPlayer p) async {
    final r = await _ask((id) => PromptSpec(
        promptId: id, kind: PromptKind.chipSell, title: 'Sell a Comp Chip?',
        optional: true, deadlineMs: _deadline));
    return (r?.payload['sell'] as bool?) ?? false; // default: keep
  }

  @override
  Future<PokerAction> bettingAction(PokerGame g, PokerPlayer p) async {
    final callAmt = g.callAmount(p);
    final r = await _ask((id) => PromptSpec(
        promptId: id, kind: PromptKind.bettingAction, title: 'Your move',
        callAmount: callAmt, minRaiseTo: g.minRaiseTo(p), maxRaiseTo: g.maxRaiseTo(p),
        canRaise: g.canRaise(p), deadlineMs: _deadline));
    final kind = r?.actionKind;
    final to = r?.payload['to'] as int?;
    switch (kind) {
      case GameActionKind.fold:
        return const PokerAction.fold();
      case GameActionKind.check:
        return callAmt == 0 ? const PokerAction.check() : const PokerAction.fold();
      case GameActionKind.call:
        return callAmt == 0 ? const PokerAction.check() : const PokerAction.call();
      case GameActionKind.bet:
        return PokerAction.bet(to ?? g.minRaiseTo(p));
      case GameActionKind.raise:
        return PokerAction.raise(to ?? g.minRaiseTo(p));
      default:
        // Timeout / unknown → the safe default: check if free, else fold.
        return callAmt == 0 ? const PokerAction.check() : const PokerAction.fold();
    }
  }
}

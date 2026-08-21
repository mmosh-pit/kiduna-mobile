import 'package:medieval_poker_engine/medieval_poker_engine.dart';

import 'agent.dart';

/// A [PlayerAgent] backed by the existing [AiBrain]. Window plays are computed
/// once per window (via [beginWindow]) and dispensed one at a time so the AI's
/// probabilistic choices don't re-roll each iteration.
class AiAgent implements PlayerAgent {
  @override
  final int seat;
  final AiBrain _ai;

  AiAgent(this.seat, {AiBrain? brain}) : _ai = brain ?? AiBrain();

  @override
  bool get isAi => true;

  // Per-window queues (templateIds / item ids), rebuilt on beginWindow.
  List<String>? _cardQueue;
  PowerTiming? _cardTiming;
  List<String>? _itemQueue;

  @override
  void beginWindow() {
    _cardQueue = null;
    _cardTiming = null;
    _itemQueue = null;
  }

  @override
  Future<int> chooseClass(List<String> classNames) async => 0; // unused for AI
  @override
  Future<int> chooseCourt(List<String> courtNames) async => 0; // unused for AI
  @override
  Future<List<String>?> buildDeck(List<PowerCard> pool, int target) async =>
      null; // AI keeps the auto-built full pool

  @override
  Future<String?> pickWindowCard(PokerGame g, PokerPlayer p, PowerTiming timing,
      List<PowerCard> playable) async {
    if (_cardQueue == null || _cardTiming != timing) {
      _cardTiming = timing;
      final plays = switch (timing) {
        PowerTiming.setup => _ai.setupPlays(g, p),
        PowerTiming.round => _ai.roundPlays(g, p),
        PowerTiming.showdown => _ai.showdownPlays(g, p),
        PowerTiming.counter => const <PowerCard>[],
      };
      _cardQueue = [for (final c in plays) c.templateId];
    }
    final ids = playable.map((c) => c.templateId).toSet();
    while (_cardQueue!.isNotEmpty) {
      final next = _cardQueue!.removeAt(0);
      if (ids.contains(next)) return next;
    }
    return null;
  }

  @override
  Future<String?> pickItem(
      PokerGame g, PokerPlayer p, List<GameItem> playable) async {
    _itemQueue ??= [for (final it in _ai.itemPlays(g, p)) it.id];
    final ids = playable.map((it) => it.id).toSet();
    while (_itemQueue!.isNotEmpty) {
      final next = _itemQueue!.removeAt(0);
      if (ids.contains(next)) return next;
    }
    return null;
  }

  @override
  Future<String?> pickCounter(PokerGame g, PokerPlayer p, ChainEntry top,
      List<PowerCard> options) async {
    final c = _ai.pickCounter(g, p, top);
    return c?.templateId;
  }

  @override
  Future<String?> pickBoardCounter(
      PokerGame g, PokerPlayer p, List<PowerCard> options) async {
    final c = _ai.pickBoardCounter(g, p);
    return c?.templateId;
  }

  @override
  Future<int?> pickTargetSeat(PokerGame g, PokerPlayer p, PowerCard card,
      List<PokerPlayer> targets) async {
    final t = _ai.pickTarget(g, p, card);
    return t?.seat;
  }

  @override
  Future<int> pickItemMode(
          PokerGame g, PokerPlayer p, GameItem item, List<String> modes) async =>
      _ai.itemMode(g, p, item);

  @override
  Future<int> pickItemCardIndex(PokerGame g, PokerPlayer p, GameItem item,
          int mode, ItemPick pick) async =>
      -1; // AI declines the sub-pick → engine auto-picks

  @override
  Future<bool> payWithChip(PokerGame g, PokerPlayer p, PowerCard card) async =>
      _ai.usesChipFor(g, p, card);

  @override
  Future<bool> sellChip(PokerGame g, PokerPlayer p) async =>
      _ai.sellsChip(g, p);

  @override
  Future<PokerAction> bettingAction(PokerGame g, PokerPlayer p) async =>
      _ai.decide(g, p);
}

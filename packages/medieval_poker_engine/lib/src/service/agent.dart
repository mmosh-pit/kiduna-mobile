import 'package:medieval_poker_engine/medieval_poker_engine.dart';

/// Abstracts *who makes a decision* for one seat — an AI, or a remote human
/// over the socket. The [GameDriver] calls these at each decision point; the AI
/// answers synchronously, a human answers over the network (with a timeout that
/// falls back to the safe default).
///
/// All "window" decisions are one-at-a-time: the driver applies each play, then
/// asks again, until the agent returns `null` (done / pass). [beginWindow] is
/// called before each such loop so a stateful agent can reset.
abstract class PlayerAgent {
  int get seat;
  bool get isAi;

  void beginWindow() {}

  // ── Deck-building (game start; only called for human agents) ──
  Future<int> chooseClass(List<String> classNames);
  Future<int> chooseCourt(List<String> courtNames);

  /// Chosen deck (template ids), or null to accept the auto-built full pool.
  Future<List<String>?> buildDeck(List<PowerCard> pool, int target);

  // ── Windows: return a card/item id to play now, or null to stop ──
  Future<String?> pickWindowCard(
      PokerGame g, PokerPlayer p, PowerTiming timing, List<PowerCard> playable);
  Future<String?> pickItem(PokerGame g, PokerPlayer p, List<GameItem> playable);
  Future<String?> pickCounter(
      PokerGame g, PokerPlayer p, ChainEntry top, List<PowerCard> options);
  Future<String?> pickBoardCounter(
      PokerGame g, PokerPlayer p, List<PowerCard> options);

  // ── Sub-decisions ──
  /// Seat of the chosen target, or null (fallback / no legal target).
  Future<int?> pickTargetSeat(
      PokerGame g, PokerPlayer p, PowerCard card, List<PokerPlayer> targets);
  Future<int> pickItemMode(
      PokerGame g, PokerPlayer p, GameItem item, List<String> modes);

  /// Index into the [ItemPick] options, or -1 to decline/auto.
  Future<int> pickItemCardIndex(
      PokerGame g, PokerPlayer p, GameItem item, int mode, ItemPick pick);
  Future<bool> payWithChip(PokerGame g, PokerPlayer p, PowerCard card);
  Future<bool> sellChip(PokerGame g, PokerPlayer p);

  // ── Betting ──
  Future<PokerAction> bettingAction(PokerGame g, PokerPlayer p);
}

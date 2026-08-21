import 'package:medieval_poker_engine/medieval_poker_engine.dart';
import 'package:medieval_poker_engine/protocol.dart';

/// Builds the [TableSnapshot] one specific player is allowed to see.
///
/// The hidden-information contract lives here: a seat's real hole cards are
/// encoded only for [viewerSeat] itself or for seats listed in [revealSeats]
/// (showdown / a PEEK scoped to this viewer). Every other seat's hole cards are
/// sent as [CardCode.hidden] ("??"), and the deck is never sent at all.
TableSnapshot serializeFor(
  PokerGame g,
  int viewerSeat, {
  required Set<int> aiSeats,
  String roomId = '',
  int? actingSeat,
  int? levelSecondsLeft,
  List<String> logTail = const [],
  Set<int> revealSeats = const {},
}) {
  final viewer = g.players[viewerSeat];

  SeatSnapshot seatOf(PokerPlayer p) {
    final visible = p.seat == viewerSeat || revealSeats.contains(p.seat);
    final hole = visible
        ? [for (final c in p.hole) CardCode.encode(c)]
        : List<String>.filled(p.hole.length, CardCode.hidden);
    return SeatSnapshot(
      seat: p.seat,
      name: p.name,
      stack: p.stack,
      folded: p.folded,
      allIn: p.allIn,
      eliminated: p.eliminated,
      heatingUp: p.heatingUp,
      tilted: p.tilted,
      isDealer: p.seat == g.buttonSeat,
      isActing: actingSeat == p.seat,
      isAI: aiSeats.contains(p.seat),
      compChips: p.compChips,
      tokenCount: p.tokens.length + p.courtTokens.length,
      roundBet: p.roundBet,
      lastAction: p.lastActionLabel,
      holeCards: hole,
    );
  }

  final playableItemIds =
      g.playableItems(viewer).map((it) => it.id).toSet();

  PowerCardView view(PowerCard c) =>
      PowerCardView(c.templateId, c.name, c.description, c.timing.name);
  // Draw deck is name-sorted so the viewer can see WHAT remains without
  // learning the draw ORDER (which would foresee future draws).
  final drawDeck = [for (final c in viewer.powerDeck) view(c)]
    ..sort((a, b) => a.name.compareTo(b.name));

  return TableSnapshot(
    roomId: roomId,
    viewerSeat: viewerSeat,
    handNumber: g.handNumber,
    seats: [for (final p in g.players) seatOf(p)],
    board: [for (final c in g.community) CardCode.encode(c)],
    pot: g.pot,
    ante: g.ante,
    level: g.level,
    inSuddenDeath: g.inSuddenDeath,
    suddenDeathHand: g.suddenDeathHand,
    levelSecondsLeft: levelSecondsLeft,
    street: g.street.name,
    yourPowerHand: [
      for (final c in viewer.powerHand)
        PowerCardView(c.templateId, c.name, c.description, c.timing.name),
    ],
    yourItems: [
      for (final it in g.heldItems(viewer))
        ItemView(it.id, it.name, it.description,
            playableItemIds.contains(it.id)),
    ],
    logTail: logTail,
    yourDrawDeck: drawDeck,
    yourDiscard: [for (final c in viewer.powerDiscard) view(c)],
    yourOneShot: [for (final c in viewer.oneShotPile) view(c)],
  );
}

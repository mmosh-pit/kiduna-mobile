import 'package:flutter/foundation.dart';

import 'package:medieval_poker_engine/protocol.dart';

/// Connection lifecycle of a session (drives connecting / error overlays).
enum SessionPhase { connecting, active, disconnected, error }

/// The human's outcome for a just-finished hand (drives the win/lose flash).
@immutable
class HandResultView {
  final bool won;

  /// Whether the viewer was still in the hand at showdown (false if they folded
  /// earlier). The result popup shows for everyone regardless; this is retained
  /// for context and potential differentiation of the message.
  final bool inHand;
  final String detail;
  const HandResultView({
    required this.won,
    required this.inHand,
    required this.detail,
  });
}

/// One row of the final standings.
@immutable
class StandingView {
  final int seat;
  final int stack;

  /// Display name for the seat (real player name, or "Seat N" for AI).
  final String? name;

  /// 1-based finishing place; 1 is the champion. Busted players all end on or
  /// near zero chips, so [stack] alone cannot order them — this can.
  final int rank;

  /// Hand this seat busted on, or null if they were still in at the end.
  final int? eliminatedAtHand;

  const StandingView(
    this.seat,
    this.stack, {
    this.name,
    this.rank = 0,
    this.eliminatedAtHand,
  });

  /// Whether this seat played to the finish rather than busting out.
  bool get survived => eliminatedAtHand == null;

  /// What to show for this row — the player name when known, else the seat.
  String get label => (name != null && name!.isNotEmpty) ? name! : 'Seat $seat';
}

/// Where a finished table sat in a tournament, when it was one.
///
/// Null on a casual table. Populated by the tournament layer so the standings
/// can say "you advance" instead of offering a rematch that does not exist.
@immutable
class TournamentOutcomeView {
  /// Human label for the round just played, e.g. "Round 1", "Final Table".
  final String roundLabel;

  /// Whether the viewer came out of this table still in the tournament.
  final bool advanced;

  /// Where they advance to. Null when this was the final table, or when they
  /// did not advance.
  final String? nextRoundLabel;

  /// The viewer won the whole tournament, not just this table.
  final bool isChampion;

  const TournamentOutcomeView({
    required this.roundLabel,
    required this.advanced,
    this.nextRoundLabel,
    this.isChampion = false,
  });
}

/// The end-of-game result.
@immutable
class GameOverView {
  final bool youWon;
  final int? winnerSeat;
  final String detail;
  final List<StandingView> standings;

  /// Set only when this table was one heat of a tournament.
  final TournamentOutcomeView? tournament;

  const GameOverView({
    required this.youWon,
    required this.winnerSeat,
    required this.detail,
    required this.standings,
    this.tournament,
  });
}

/// The UI-facing contract for a game of Medieval Poker, whether played locally
/// against AI or online over the network. The Flame renderer and the HUD bind
/// ONLY to this interface — they never touch a [PokerGame] engine or a socket
/// directly, so the same table renders identically in both modes.
///
/// Everything the UI shows is derived from the [TableSnapshot] the server (or a
/// local authority) produces for *this* viewer; every human decision is an
/// answer to the current [prompt]. This is the seam that lets `LocalSession`
/// (offline) and `RemoteSession` (online) be swapped underneath one UI.
abstract class GameSession {
  /// The seat this client occupies.
  int get viewerSeat;

  /// Connection lifecycle.
  ValueListenable<SessionPhase> get phase;

  /// The latest table state from this viewer's perspective (null until the
  /// first snapshot arrives). Opponents' hole cards are hidden here already.
  ValueListenable<TableSnapshot?> get table;

  /// The decision the UI must currently render (null = nothing to ask). The
  /// HUD maps [PromptSpec.kind] to the matching panel.
  ValueListenable<PromptSpec?> get prompt;

  /// The most recent hand's result for this viewer (null = no flash showing).
  ValueListenable<HandResultView?> get handResult;

  /// Set once when the game ends.
  ValueListenable<GameOverView?> get gameOver;

  /// Transient PEEK reveal text (secret info shown only to this viewer).
  ValueListenable<String> get peek;

  /// A human-readable reason for the current error/disconnected state (e.g.
  /// "That seat belongs to another player", "server is restarting"), or null
  /// when there's nothing specific to say. The HUD shows it in place of the
  /// generic connection message. Never set for a healthy session.
  ValueListenable<String?> get errorMessage;

  /// Answer the active [prompt]. [kind] may be null for prompts whose response
  /// is read purely from [payload] (e.g. item mode / pick). No-op if there is
  /// no active prompt. Clears [prompt] optimistically so the panel dismisses.
  void answer(GameActionKind? kind, [Map<String, dynamic> payload = const {}]);

  /// Tear down transports/timers.
  void dispose();
}

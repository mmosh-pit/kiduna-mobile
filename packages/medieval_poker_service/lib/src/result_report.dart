/// The authoritative game-service's report of a finished game, sent to the
/// Node backend (`POST /games/internal/result`) so results/leaderboard are
/// written from a trusted source rather than from clients.
class SeatResult {
  final int seat;
  final String? userId; // null for a seat no human ever held (pure AI)
  final bool isAi;
  final int stack; // final chip count

  /// 1-based bust order (1 = first out), or null if the seat still had chips
  /// when the game ended. Final stacks alone can't separate the losers — every
  /// eliminated seat ends on 0 — so the backend ranks with this.
  final int? eliminationOrder;

  const SeatResult({
    required this.seat,
    required this.userId,
    required this.isAi,
    required this.stack,
    this.eliminationOrder,
  });

  Map<String, dynamic> toJson() => {
        'seat': seat,
        if (userId != null) 'userId': userId,
        'isAi': isAi,
        'stack': stack,
        if (eliminationOrder != null) 'eliminationOrder': eliminationOrder,
      };
}

class GameResultReport {
  final String roomCode;
  final int? winnerSeat;
  final List<SeatResult> seats;
  const GameResultReport({
    required this.roomCode,
    required this.winnerSeat,
    required this.seats,
  });

  Map<String, dynamic> toJson() => {
        'roomCode': roomCode,
        'winnerSeat': winnerSeat,
        'seats': [for (final s in seats) s.toJson()],
      };
}

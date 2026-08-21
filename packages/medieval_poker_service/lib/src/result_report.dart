/// The authoritative game-service's report of a finished game, sent to the
/// Node backend (`POST /games/internal/result`) so results/leaderboard are
/// written from a trusted source rather than from clients.
class SeatResult {
  final int seat;
  final String? userId; // null for a seat no human ever held (pure AI)
  final bool isAi;
  final int stack; // final chip count
  const SeatResult({
    required this.seat,
    required this.userId,
    required this.isAi,
    required this.stack,
  });

  Map<String, dynamic> toJson() => {
        'seat': seat,
        if (userId != null) 'userId': userId,
        'isAi': isAi,
        'stack': stack,
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

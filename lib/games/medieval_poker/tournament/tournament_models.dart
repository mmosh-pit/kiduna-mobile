import 'package:flutter/foundation.dart';

/// Where a tournament is in its life.
enum TournamentStatus { registering, running, finished, cancelled }

TournamentStatus _statusOf(String? raw) => switch (raw) {
  'running' => TournamentStatus.running,
  'finished' => TournamentStatus.finished,
  'cancelled' => TournamentStatus.cancelled,
  _ => TournamentStatus.registering,
};

/// How one heat of a bracket is going.
enum MatchStatus { pending, active, finished }

MatchStatus _matchStatusOf(String? raw) => switch (raw) {
  'active' => MatchStatus.active,
  'finished' => MatchStatus.finished,
  _ => MatchStatus.pending,
};

/// A tournament as it appears in a list — enough to render a card without
/// fetching the whole bracket.
@immutable
class TournamentSummary {
  final String id;
  final String name;
  final TournamentStatus status;
  final int size;
  final int registered;
  final int currentRound;
  final int totalRounds;
  final String? championUserId;
  final bool isRegistered;
  final bool isCreator;

  const TournamentSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.size,
    required this.registered,
    required this.currentRound,
    required this.totalRounds,
    required this.championUserId,
    required this.isRegistered,
    required this.isCreator,
  });

  bool get isOpen => status == TournamentStatus.registering;
  bool get isRunning => status == TournamentStatus.running;
  bool get isFinished => status == TournamentStatus.finished;

  /// True once every slot is taken — the point at which it starts itself.
  bool get isFull => registered >= size;

  factory TournamentSummary.fromJson(Map<String, dynamic> j) =>
      TournamentSummary(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        status: _statusOf(j['status'] as String?),
        size: j['size'] as int? ?? 0,
        registered: j['registered'] as int? ?? 0,
        currentRound: j['currentRound'] as int? ?? 0,
        totalRounds: j['totalRounds'] as int? ?? 1,
        championUserId: j['championUserId'] as String?,
        isRegistered: j['isRegistered'] as bool? ?? false,
        isCreator: j['isCreator'] as bool? ?? false,
      );
}

/// Someone entered in a tournament.
@immutable
class Entrant {
  final String userId;
  final int seed;
  final String status; // registered | active | eliminated | champion
  final int? eliminatedRound;
  final int? finalRank;
  final String? username;
  final String? name;
  final String? picture;

  const Entrant({
    required this.userId,
    required this.seed,
    required this.status,
    this.eliminatedRound,
    this.finalRank,
    this.username,
    this.name,
    this.picture,
  });

  String get label => username ?? name ?? 'Player';
  bool get isEliminated => status == 'eliminated';
  bool get isChampion => status == 'champion';

  factory Entrant.fromJson(Map<String, dynamic> j) => Entrant(
    userId: j['userId'] as String? ?? '',
    seed: j['seed'] as int? ?? 0,
    status: j['status'] as String? ?? 'registered',
    eliminatedRound: j['eliminatedRound'] as int?,
    finalRank: j['finalRank'] as int?,
    username: j['username'] as String?,
    name: j['name'] as String?,
    picture: j['picture'] as String?,
  );
}

/// One seat in a heat.
@immutable
class MatchPlayer {
  final int seat;
  final String? userId;
  final bool isAi;
  final String? username;
  final String? name;
  final String? picture;

  const MatchPlayer({
    required this.seat,
    required this.userId,
    required this.isAi,
    this.username,
    this.name,
    this.picture,
  });

  String get label => isAi ? 'AI' : (username ?? name ?? 'Player');

  factory MatchPlayer.fromJson(Map<String, dynamic> j) => MatchPlayer(
    seat: j['seat'] as int? ?? 0,
    userId: j['userId'] as String?,
    isAi: j['isAi'] as bool? ?? false,
    username: j['username'] as String?,
    name: j['name'] as String?,
    picture: j['picture'] as String?,
  );
}

/// One heat of the bracket.
@immutable
class BracketMatch {
  final String id;
  final int round;
  final int matchIndex;
  final String? roomCode;
  final MatchStatus status;
  final String? winnerUserId;
  final List<MatchPlayer> players;

  const BracketMatch({
    required this.id,
    required this.round,
    required this.matchIndex,
    required this.roomCode,
    required this.status,
    required this.winnerUserId,
    required this.players,
  });

  bool contains(String? userId) =>
      userId != null && players.any((p) => p.userId == userId);

  factory BracketMatch.fromJson(Map<String, dynamic> j) => BracketMatch(
    id: j['id'] as String? ?? '',
    round: j['round'] as int? ?? 1,
    matchIndex: j['matchIndex'] as int? ?? 0,
    roomCode: j['roomCode'] as String?,
    status: _matchStatusOf(j['status'] as String?),
    winnerUserId: j['winnerUserId'] as String?,
    players: [
      for (final p in (j['players'] as List? ?? const []))
        MatchPlayer.fromJson(p as Map<String, dynamic>),
    ],
  );
}

/// All the heats of one round.
@immutable
class BracketRound {
  final int round;
  final List<BracketMatch> matches;
  const BracketRound({required this.round, required this.matches});

  factory BracketRound.fromJson(Map<String, dynamic> j) => BracketRound(
    round: j['round'] as int? ?? 1,
    matches: [
      for (final m in (j['matches'] as List? ?? const []))
        BracketMatch.fromJson(m as Map<String, dynamic>),
    ],
  );
}

/// The table the viewer should be sitting at right now, with everything the
/// online screen needs to connect.
@immutable
class MyMatch {
  final String matchId;
  final int round;
  final String roomCode;
  final int seat;
  final int seatCount;
  final int humans;
  final String gameToken;
  final String wsUrl;

  const MyMatch({
    required this.matchId,
    required this.round,
    required this.roomCode,
    required this.seat,
    required this.seatCount,
    required this.humans,
    required this.gameToken,
    required this.wsUrl,
  });

  factory MyMatch.fromJson(Map<String, dynamic> j) => MyMatch(
    matchId: j['matchId'] as String? ?? '',
    round: j['round'] as int? ?? 1,
    roomCode: j['roomCode'] as String? ?? '',
    seat: j['seat'] as int? ?? 0,
    seatCount: j['seatCount'] as int? ?? 4,
    humans: j['humans'] as int? ?? 1,
    gameToken: j['gameToken'] as String? ?? '',
    wsUrl: j['wsUrl'] as String? ?? '',
  );
}

/// A tournament with its full bracket and the viewer's place in it.
@immutable
class TournamentDetail {
  final TournamentSummary tournament;
  final List<Entrant> entrants;
  final List<BracketRound> bracket;
  final MyMatch? myMatch;

  const TournamentDetail({
    required this.tournament,
    required this.entrants,
    required this.bracket,
    required this.myMatch,
  });

  /// The viewer's entry, if they are in this tournament.
  Entrant? entrantFor(String? userId) {
    if (userId == null) return null;
    for (final e in entrants) {
      if (e.userId == userId) return e;
    }
    return null;
  }

  factory TournamentDetail.fromJson(Map<String, dynamic> j) => TournamentDetail(
    tournament: TournamentSummary.fromJson(
      j['tournament'] as Map<String, dynamic>,
    ),
    entrants: [
      for (final e in (j['entrants'] as List? ?? const []))
        Entrant.fromJson(e as Map<String, dynamic>),
    ],
    bracket: [
      for (final r in (j['bracket'] as List? ?? const []))
        BracketRound.fromJson(r as Map<String, dynamic>),
    ],
    myMatch: j['myMatch'] == null
        ? null
        : MyMatch.fromJson(j['myMatch'] as Map<String, dynamic>),
  );
}

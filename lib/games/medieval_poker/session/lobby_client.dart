import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';

/// One seat as seen in the lobby.
class LobbySeat {
  final int seat;
  final String? userId;
  final bool isAi;
  final bool ready;
  final String? username;
  final String? name;
  final String? picture;

  const LobbySeat({
    required this.seat,
    required this.userId,
    required this.isAi,
    required this.ready,
    this.username,
    this.name,
    this.picture,
  });

  bool get isOpen => userId == null && !isAi;

  factory LobbySeat.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>?;
    return LobbySeat(
      seat: j['seat'] as int,
      userId: j['userId'] as String?,
      isAi: j['isAi'] as bool? ?? false,
      ready: j['ready'] as bool? ?? false,
      username: user?['username'] as String?,
      name: user?['name'] as String?,
      picture: user?['picture'] as String?,
    );
  }

  String get label {
    if (isAi) return 'AI';
    if (userId == null) return 'Open';
    return username ?? name ?? 'Player';
  }
}

/// A lobby room + its seats.
class LobbyRoom {
  final String id;
  final String code;
  final String game;
  final String status; // lobby | active | finished
  final int seatCount;
  final String wsUrl;
  final String createdBy;
  final int humans;
  final bool timedLevels;
  final List<LobbySeat> seats;

  const LobbyRoom({
    required this.id,
    required this.code,
    required this.game,
    required this.status,
    required this.seatCount,
    required this.wsUrl,
    required this.createdBy,
    required this.humans,
    required this.timedLevels,
    required this.seats,
  });

  bool get isActive => status == 'active';
  bool get isLobby => status == 'lobby';

  factory LobbyRoom.fromJson(Map<String, dynamic> j) => LobbyRoom(
    id: j['id'] as String,
    code: j['code'] as String,
    game: j['game'] as String? ?? 'medieval_poker',
    status: j['status'] as String,
    seatCount: j['seatCount'] as int,
    wsUrl: j['wsUrl'] as String,
    createdBy: j['createdBy'] as String,
    humans: j['humans'] as int? ?? 0,
    timedLevels:
        (j['config'] as Map<String, dynamic>?)?['timedLevels'] as bool? ?? true,
    seats: [
      for (final s in (j['seats'] as List? ?? const []))
        LobbySeat.fromJson(s as Map<String, dynamic>),
    ],
  );
}

/// What a create/join returns: the room, your seat, and the connection details
/// to hand to [RemoteSession].
class LobbyTicket {
  final LobbyRoom room;
  final int seat;
  final String gameToken;
  final String wsUrl;

  const LobbyTicket({
    required this.room,
    required this.seat,
    required this.gameToken,
    required this.wsUrl,
  });
}

/// Which leaderboard to show: skill rating, or raw win count.
enum LeaderboardBoard { rating, wins }

/// Which window the board covers.
enum LeaderboardSeason { current, allTime }

/// A player's court rank, derived from their rating. Mirrors the backend's
/// `TIERS` table in `src/rating/elo.ts` — keep the two in step.
enum RatingTier { peasant, squire, knight, baron, duke, royal }

RatingTier ratingTierOf(String? id) => switch (id) {
  'squire' => RatingTier.squire,
  'knight' => RatingTier.knight,
  'baron' => RatingTier.baron,
  'duke' => RatingTier.duke,
  'royal' => RatingTier.royal,
  _ => RatingTier.peasant,
};

/// One row of the leaderboard. Carries both boards' figures so a single row
/// type serves the rating and wins views.
class LeaderboardEntry {
  final String userId;
  final int games;
  final int wins;
  final int rank;
  final int rating;
  final int peakRating;
  final RatingTier tier;
  final String? username;
  final String? name;
  final String? picture;

  const LeaderboardEntry({
    required this.userId,
    required this.games,
    required this.wins,
    this.rank = 0,
    this.rating = 1200,
    this.peakRating = 1200,
    this.tier = RatingTier.knight,
    this.username,
    this.name,
    this.picture,
  });

  String get label => username ?? name ?? 'Player';
  int get winRate => games == 0 ? 0 : ((wins / games) * 100).round();

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
    userId: j['userId'] as String? ?? '',
    games: j['games'] as int? ?? 0,
    wins: j['wins'] as int? ?? 0,
    rank: j['rank'] as int? ?? 0,
    rating: j['rating'] as int? ?? 1200,
    peakRating: j['peakRating'] as int? ?? 1200,
    tier: ratingTierOf(j['tier'] as String?),
    username: j['username'] as String?,
    name: j['name'] as String?,
    picture: j['picture'] as String?,
  );
}

/// A page of the leaderboard plus the caller's own row — which the server
/// includes even when the caller sits far below the visible page, so a player
/// can always find themselves.
class LeaderboardPage {
  final LeaderboardBoard board;
  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? me;

  const LeaderboardPage({
    required this.board,
    required this.entries,
    required this.me,
  });

  bool get isEmpty => entries.isEmpty;
}

/// The caller's own aggregate.
class PlayerStats {
  final int games;
  final int wins;
  const PlayerStats({required this.games, required this.wins});
  int get winRate => games == 0 ? 0 : ((wins / games) * 100).round();
  factory PlayerStats.fromJson(Map<String, dynamic> j) =>
      PlayerStats(games: j['games'] as int? ?? 0, wins: j['wins'] as int? ?? 0);
}

/// The caller's public-matchmaking status.
class QueueStatus {
  final String status; // idle | waiting | matched
  final int? waitingMs;
  final LobbyTicket? ticket; // present when [isMatched]
  const QueueStatus({required this.status, this.waitingMs, this.ticket});

  bool get isMatched => status == 'matched';
  bool get isWaiting => status == 'waiting';
}

/// The caller's own rating, tier and recent movement.
class PlayerRating {
  final int rating;
  final int peakRating;
  final int games;
  final int wins;

  /// Position on the board, or null when the player has no rated games yet.
  final int? rank;
  final RatingTier tier;

  /// Most recent rating changes, newest first.
  final List<int> recentDeltas;

  const PlayerRating({
    required this.rating,
    required this.peakRating,
    required this.games,
    required this.wins,
    required this.rank,
    required this.tier,
    this.recentDeltas = const [],
  });

  bool get isRanked => rank != null && games > 0;
  int get winRate => games == 0 ? 0 : ((wins / games) * 100).round();

  factory PlayerRating.fromJson(
    Map<String, dynamic> rating,
    List<dynamic> recent,
  ) => PlayerRating(
    rating: rating['rating'] as int? ?? 1200,
    peakRating: rating['peakRating'] as int? ?? 1200,
    games: rating['games'] as int? ?? 0,
    wins: rating['wins'] as int? ?? 0,
    rank: rating['rank'] as int?,
    tier: ratingTierOf(rating['tier'] as String?),
    recentDeltas: [
      for (final e in recent) (e as Map<String, dynamic>)['delta'] as int? ?? 0,
    ],
  );
}

/// Raised for a lobby REST failure, carrying the server's message when present.
class LobbyException implements Exception {
  final String message;

  /// True when the backend does not serve this route at all — a deployment
  /// problem, not an empty result. Without this an un-deployed backend looks
  /// identical to "nobody has played yet".
  final bool isMissingEndpoint;

  const LobbyException(this.message, {this.isMissingEndpoint = false});

  @override
  String toString() => message;
}

/// REST client for the Node lobby (`/games/*`). Uses the app's [DioClient],
/// which targets `BACKEND_URL` and attaches the user's bearer token, so the
/// caller must already be authenticated.
class LobbyClient {
  final Dio _dio;
  LobbyClient({Dio? dio}) : _dio = dio ?? ApiClient.instance.authDio;

  Future<LobbyTicket> createRoom({int? seats, bool? timedLevels}) async {
    final res = await _call(
      () => _dio.post(
        '/games/rooms',
        data: {'seats': ?seats, 'timedLevels': ?timedLevels},
      ),
    );
    return _ticketOf(res);
  }

  Future<LobbyTicket> joinRoom(String code) async {
    final res = await _call(() => _dio.post('/games/rooms/$code/join'));
    return _ticketOf(res);
  }

  Future<LobbyRoom> setReady(String code, bool ready) async {
    final res = await _call(
      () => _dio.post('/games/rooms/$code/ready', data: {'ready': ready}),
    );
    return LobbyRoom.fromJson(_data(res)['room'] as Map<String, dynamic>);
  }

  Future<LobbyRoom> start(String code) async {
    final res = await _call(() => _dio.post('/games/rooms/$code/start'));
    return LobbyRoom.fromJson(_data(res)['room'] as Map<String, dynamic>);
  }

  Future<void> leave(String code) async {
    await _call(() => _dio.post('/games/rooms/$code/leave'));
  }

  Future<LobbyRoom> getRoom(String code) async {
    final res = await _call(() => _dio.get('/games/rooms/$code'));
    return LobbyRoom.fromJson(_data(res)['room'] as Map<String, dynamic>);
  }

  // ── Public matchmaking ─────────────────────────────────────────────────
  Future<QueueStatus> enqueue() async =>
      _queueStatusOf(await _call(() => _dio.post('/games/queue')));

  Future<QueueStatus> queueStatus() async =>
      _queueStatusOf(await _call(() => _dio.get('/games/queue')));

  Future<void> leaveQueue() async {
    await _call(() => _dio.delete('/games/queue'));
  }

  // ── Results / leaderboard ──────────────────────────────────────────────

  /// A page of the leaderboard. [board] picks skill rating or raw wins;
  /// [season] picks the current season or the all-time board.
  Future<LeaderboardPage> leaderboard({
    LeaderboardBoard board = LeaderboardBoard.rating,
    LeaderboardSeason season = LeaderboardSeason.allTime,
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await _call(
      () => _dio.get(
        '/games/leaderboard',
        queryParameters: {
          'board': board == LeaderboardBoard.wins ? 'wins' : 'rating',
          'season': season == LeaderboardSeason.current ? 'current' : 'all',
          'limit': limit,
          'offset': offset,
        },
      ),
    );
    final d = _data(res);
    final list = d['leaderboard'] as List? ?? const [];
    final me = d['me'];
    return LeaderboardPage(
      board: board,
      entries: [
        for (final e in list)
          LeaderboardEntry.fromJson(e as Map<String, dynamic>),
      ],
      me: me == null
          ? null
          : LeaderboardEntry.fromJson(me as Map<String, dynamic>),
    );
  }

  Future<PlayerStats> myStats() async {
    final res = await _call(() => _dio.get('/games/stats'));
    return PlayerStats.fromJson(_data(res)['stats'] as Map<String, dynamic>);
  }

  /// The caller's rating, tier, rank and recent movement.
  Future<PlayerRating> myRating({
    LeaderboardSeason season = LeaderboardSeason.allTime,
  }) async {
    final res = await _call(
      () => _dio.get(
        '/games/rating',
        queryParameters: {
          'season': season == LeaderboardSeason.current ? 'current' : 'all',
        },
      ),
    );
    final d = _data(res);
    return PlayerRating.fromJson(
      (d['rating'] as Map).cast<String, dynamic>(),
      d['recent'] as List? ?? const [],
    );
  }

  QueueStatus _queueStatusOf(Response res) {
    final d = _data(res);
    final status = d['status'] as String? ?? 'idle';
    if (status == 'matched') {
      return QueueStatus(
        status: status,
        ticket: LobbyTicket(
          room: LobbyRoom.fromJson(d['room'] as Map<String, dynamic>),
          seat: d['seat'] as int,
          gameToken: d['gameToken'] as String,
          wsUrl: d['wsUrl'] as String,
        ),
      );
    }
    return QueueStatus(status: status, waitingMs: d['waitingMs'] as int?);
  }

  // ── plumbing ─────────────────────────────────────────────────────────────
  Future<Response> _call(Future<Response> Function() fn) async {
    try {
      return await fn();
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map && data['error'] is String)
          ? data['error'] as String
          : (e.message ?? 'Network error');
      // A 404 with no `error` body is the route itself missing, not a missing
      // record — the caller shows "couldn't load" rather than "no games yet".
      final missing =
          e.response?.statusCode == 404 &&
          !(data is Map && data['error'] is String);
      throw LobbyException(msg, isMissingEndpoint: missing);
    }
  }

  Map<String, dynamic> _data(Response res) {
    final body = res.data;
    if (body is Map && body['data'] is Map) {
      return (body['data'] as Map).cast<String, dynamic>();
    }
    throw const LobbyException('Malformed lobby response');
  }

  LobbyTicket _ticketOf(Response res) {
    final d = _data(res);
    return LobbyTicket(
      room: LobbyRoom.fromJson(d['room'] as Map<String, dynamic>),
      seat: d['seat'] as int,
      gameToken: d['gameToken'] as String,
      wsUrl: d['wsUrl'] as String,
    );
  }
}

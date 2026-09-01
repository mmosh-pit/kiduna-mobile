
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

/// One seat as seen in the lobby.
class LobbySeat {
  final int seat;
  final String? userId;
  final String? viewerUserId;
  final bool isAi;
  final bool ready;
  final String? username;
  final String? name;
  final String? picture;

  const LobbySeat({
    required this.seat,
    required this.userId,
    this.viewerUserId,
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
      viewerUserId: j['viewerUserId'] as String?,
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
  final GameResult? result;

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
    this.result,
  });

  bool get isActive => status == 'active';
  bool get isLobby => status == 'lobby';
  bool get isFinished => status == 'finished';

  factory LobbyRoom.fromJson(Map<String, dynamic> j) {
    final resultJson = j['result'] as Map<String, dynamic>?;
    return LobbyRoom(
      id: j['id'] as String,
      code: j['code'] as String,
      game: j['game'] as String? ?? 'medieval_poker',
      status: j['status'] as String,
      seatCount: j['seatCount'] as int,
      wsUrl: j['wsUrl'] as String,
      createdBy: j['createdBy'] as String,
      humans: j['humans'] as int? ?? 0,
      timedLevels:
          (j['config'] as Map<String, dynamic>?)?['timedLevels'] as bool? ??
              true,
      seats: [
        for (final s in (j['seats'] as List? ?? const []))
          LobbySeat.fromJson(s as Map<String, dynamic>)
      ],
      result: resultJson != null ? GameResult.fromJson(resultJson) : null,
    );
  }
}

/// Result data for a finished game room.
class GameResult {
  final String? winnerUserId;
  final String? winnerName;
  final List<dynamic>? standings;
  final DateTime? endedAt;

  const GameResult({
    this.winnerUserId,
    this.winnerName,
    this.standings,
    this.endedAt,
  });

  factory GameResult.fromJson(Map<String, dynamic> j) => GameResult(
        winnerUserId: j['winnerUserId'] as String?,
        winnerName: j['winnerName'] as String?,
        standings: j['standings'] as List?,
        endedAt: j['endedAt'] != null
            ? DateTime.tryParse(j['endedAt'] as String)
            : null,
      );
}

/// What a create/join returns: the room, your seat, and the connection details
/// to hand to [RemoteSession].
class LobbyTicket {
  final LobbyRoom room;
  final int seat;
  final String gameToken;
  final String wsUrl;
  final bool isViewer;

  const LobbyTicket({
    required this.room,
    required this.seat,
    required this.gameToken,
    required this.wsUrl,
    this.isViewer = false,
  });
}

/// One row of the leaderboard.
class LeaderboardEntry {
  final String userId;
  final int games;
  final int wins;
  final String? username;
  final String? name;
  final String? picture;
  const LeaderboardEntry({
    required this.userId,
    required this.games,
    required this.wins,
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
        username: j['username'] as String?,
        name: j['name'] as String?,
        picture: j['picture'] as String?,
      );
}

/// The caller's own aggregate.
class PlayerStats {
  final int games;
  final int wins;
  const PlayerStats({required this.games, required this.wins});
  int get winRate => games == 0 ? 0 : ((wins / games) * 100).round();
  factory PlayerStats.fromJson(Map<String, dynamic> j) => PlayerStats(
        games: j['games'] as int? ?? 0,
        wins: j['wins'] as int? ?? 0,
      );
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

/// Raised for a lobby REST failure, carrying the server's message when present.
class LobbyException implements Exception {
  final String message;
  const LobbyException(this.message);
  @override
  String toString() => message;
}

/// REST client for the Node lobby (`/games/*`). Defaults to [ApiClient]'s
/// `authDio`, which targets the Node backend (`AUTH_API_URL`) and attaches the
/// user's bearer token — NOT the main `dio` (the FastAPI agent at
/// `API_BASE_URL`), which does not serve `/games/*`. The caller must already be
/// authenticated.
class LobbyClient {
  final Dio _dio;
  LobbyClient({Dio? dio}) : _dio = dio ?? ApiClient.instance.authDio;

  /// Fastify rejects an empty body sent with `application/json` (authDio's
  /// default content-type) with a 400 `FST_ERR_CTP_EMPTY_JSON_BODY`, so bodyless
  /// mutations must still send a valid JSON payload — an empty object.
  static const Map<String, dynamic> _emptyBody = <String, dynamic>{};

  Future<LobbyTicket> createRoom({int? seats, bool? timedLevels, String? realmId}) async {
    final res = await _call(() => _dio.post('/games/rooms', data: {
          if (seats != null) 'seats': seats,
          if (timedLevels != null) 'timedLevels': timedLevels,
          if (realmId != null) 'realmId': realmId,
        }));
    return _ticketOf(res);
  }

  Future<LobbyTicket> joinRoom(String code) async {
    final res =
        await _call(() => _dio.post('/games/rooms/$code/join', data: _emptyBody));
    return _ticketOf(res);
  }

  Future<LobbyRoom> setReady(String code, bool ready) async {
    final res =
        await _call(() => _dio.post('/games/rooms/$code/ready', data: {'ready': ready}));
    return LobbyRoom.fromJson(_data(res)['room'] as Map<String, dynamic>);
  }

  Future<LobbyRoom> start(String code) async {
    final res =
        await _call(() => _dio.post('/games/rooms/$code/start', data: _emptyBody));
    return LobbyRoom.fromJson(_data(res)['room'] as Map<String, dynamic>);
  }

  Future<void> leave(String code) async {
    await _call(() => _dio.post('/games/rooms/$code/leave', data: _emptyBody));
  }

  Future<LobbyTicket> watchRoom(String code, {int? seat}) async {
    final res = await _call(
      () => _dio.post('/games/rooms/$code/watch', data: {
        if (seat != null) 'seat': seat,
      }),
    );
    return _ticketOf(res);
  }

  Future<LobbyRoom> getRoom(String code) async {
    final res = await _call(() => _dio.get('/games/rooms/$code'));
    return LobbyRoom.fromJson(_data(res)['room'] as Map<String, dynamic>);
  }

  Future<List<LobbyRoom>> realmGames(String realmId) async {
    final res = await _call(
      () => _dio.get('/games/rooms', queryParameters: {'realmId': realmId}),
    );
    final list = _data(res)['rooms'] as List? ?? const [];
    return [
      for (final r in list)
        LobbyRoom.fromJson(r as Map<String, dynamic>)
    ];
  }

  // ── Public matchmaking ─────────────────────────────────────────────────
  Future<QueueStatus> enqueue() async =>
      _queueStatusOf(await _call(() => _dio.post('/games/queue', data: _emptyBody)));

  Future<QueueStatus> queueStatus() async =>
      _queueStatusOf(await _call(() => _dio.get('/games/queue')));

  Future<void> leaveQueue() async {
    await _call(() => _dio.delete('/games/queue', data: _emptyBody));
  }

  // ── Results / leaderboard ──────────────────────────────────────────────
  Future<List<LeaderboardEntry>> leaderboard() async {
    final res = await _call(() => _dio.get('/games/leaderboard'));
    final list = _data(res)['leaderboard'] as List? ?? const [];
    return [
      for (final e in list) LeaderboardEntry.fromJson(e as Map<String, dynamic>)
    ];
  }

  Future<PlayerStats> myStats() async {
    final res = await _call(() => _dio.get('/games/stats'));
    return PlayerStats.fromJson(_data(res)['stats'] as Map<String, dynamic>);
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
      throw LobbyException(msg);
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
      isViewer: d['isViewer'] as bool? ?? false,
    );
  }
}

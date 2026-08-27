class GravitySignals {
  const GravitySignals({
    required this.claim,
    required this.recency,
    required this.commitment,
    required this.motion,
    required this.relationship,
    required this.consequence,
    required this.affinity,
  });

  final double claim;
  final double recency;
  final double commitment;
  final double motion;
  final double relationship;
  final double consequence;
  final double affinity;

  factory GravitySignals.fromJson(Map<String, dynamic> json) {
    return GravitySignals(
      claim: (json['claim'] as num?)?.toDouble() ?? 0.0,
      recency: (json['recency'] as num?)?.toDouble() ?? 0.0,
      commitment: (json['commitment'] as num?)?.toDouble() ?? 0.0,
      motion: (json['motion'] as num?)?.toDouble() ?? 0.0,
      relationship: (json['relationship'] as num?)?.toDouble() ?? 0.0,
      consequence: (json['consequence'] as num?)?.toDouble() ?? 0.0,
      affinity: (json['affinity'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RealmGravity {
  const RealmGravity({
    required this.id,
    required this.name,
    required this.type,
    required this.level,
    required this.score,
    required this.signals,
    required this.reason,
    this.membership,
    this.role,
    this.gameStatus,
    this.gameRoomCode,
    this.gamePlayerCount,
    this.gameSeatCount,
  });

  final String id;
  final String name;
  final String type;
  final String level;
  final double score;
  final GravitySignals signals;
  final String reason;
  final String? membership;
  final String? role;
  final String? gameStatus;
  final String? gameRoomCode;
  final int? gamePlayerCount;
  final int? gameSeatCount;

  factory RealmGravity.fromJson(Map<String, dynamic> json) {
    return RealmGravity(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'unknown',
      level: json['level'] as String? ?? 'quiet',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      signals: GravitySignals.fromJson(
        json['signals'] as Map<String, dynamic>? ?? const {},
      ),
      reason: json['reason'] as String? ?? '',
      membership: json['membership'] as String?,
      role: json['role'] as String?,
      gameStatus: json['game_status'] as String?,
      gameRoomCode: json['game_room_code'] as String?,
      gamePlayerCount: json['game_player_count'] as int?,
      gameSeatCount: json['game_seat_count'] as int?,
    );
  }
}

class LevelSummary {
  const LevelSummary({
    required this.vital,
    required this.central,
    required this.relevant,
    required this.available,
    required this.quiet,
  });

  final int vital;
  final int central;
  final int relevant;
  final int available;
  final int quiet;

  factory LevelSummary.fromJson(Map<String, dynamic> json) {
    return LevelSummary(
      vital: json['vital'] as int? ?? 0,
      central: json['central'] as int? ?? 0,
      relevant: json['relevant'] as int? ?? 0,
      available: json['available'] as int? ?? 0,
      quiet: json['quiet'] as int? ?? 0,
    );
  }
}

class GravityResponse {
  const GravityResponse({
    required this.wallet,
    required this.computedAt,
    required this.signalsAvailable,
    required this.signalsUnavailable,
    required this.realms,
    required this.levelSummary,
  });

  final String wallet;
  final String computedAt;
  final List<String> signalsAvailable;
  final List<String> signalsUnavailable;
  final List<RealmGravity> realms;
  final LevelSummary levelSummary;

  factory GravityResponse.fromJson(Map<String, dynamic> json) {
    return GravityResponse(
      wallet: json['wallet'] as String? ?? '',
      computedAt: json['computed_at'] as String? ?? '',
      signalsAvailable: (json['signals_available'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      signalsUnavailable: (json['signals_unavailable'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      realms: (json['realms'] as List<dynamic>?)
              ?.map(
                (e) =>
                    RealmGravity.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      levelSummary: LevelSummary.fromJson(
        json['level_summary'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

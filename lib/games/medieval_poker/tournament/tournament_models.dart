import 'package:flutter/foundation.dart';

/// Client-side view of a tournament.
///
/// These mirror the bracket contract in `medieval_poker_engine/tournament.dart`
/// — round, table, entrant — so the wire format and the shape the server
/// computes stay in step.
///
/// The important property: **the bracket does not exist until the clock fires.**
/// Entrants register, but only those present at start time are seated, so a
/// sixteen-player sign-up can open as a single heads-up table. Nothing here may
/// assume a fixed tree; [TournamentDetail.rounds] is empty until it starts.

/// Where a tournament is in its life.
enum TournamentStatus {
  /// Open for registration, waiting for its start time.
  scheduled,

  /// Under way.
  running,

  /// A champion was decided.
  finished,

  /// Called off — usually too few players present when the clock fired.
  cancelled;

  static TournamentStatus parse(String? raw) => switch (raw) {
    'running' => TournamentStatus.running,
    'finished' => TournamentStatus.finished,
    'cancelled' => TournamentStatus.cancelled,
    _ => TournamentStatus.scheduled,
  };

  String get wire => name;
}

/// How one table is going.
enum TableStatus {
  /// Seated, not yet dealt.
  pending,

  /// Being played now.
  active,

  /// Has a winner.
  finished;

  static TableStatus parse(String? raw) => switch (raw) {
    'active' => TableStatus.active,
    'finished' => TableStatus.finished,
    _ => TableStatus.pending,
  };
}

/// Someone entered in a tournament.
@immutable
class EntrantView {
  final String userId;
  final String? name;

  /// Present and connected as the clock approaches. Only active entrants are
  /// seated when it fires.
  final bool active;

  /// Set once they are out; 1 is the champion.
  final int? finalRank;

  const EntrantView({
    required this.userId,
    this.name,
    this.active = false,
    this.finalRank,
  });

  String get label => (name != null && name!.isNotEmpty) ? name! : 'Player';

  bool get isChampion => finalRank == 1;

  factory EntrantView.fromJson(Map<String, dynamic> j) => EntrantView(
    userId: j['userId'] as String? ?? '',
    name: j['name'] as String?,
    active: j['active'] as bool? ?? false,
    finalRank: j['finalRank'] as int?,
  );
}

/// One table within a round. Mirrors `TableAssignment`.
@immutable
class TableView {
  /// Position within the round, 0-based.
  final int index;

  /// Who sits here, in seat order.
  final List<EntrantView> players;

  final TableStatus status;

  /// Set once the table is finished.
  final String? winnerUserId;

  /// Room code to connect to, when this table is playable.
  final String? roomCode;

  const TableView({
    required this.index,
    required this.players,
    this.status = TableStatus.pending,
    this.winnerUserId,
    this.roomCode,
  });

  int get seats => players.length;

  /// True when this table runs short of a full complement. Ordinary in this
  /// format — no-shows leave tables light rather than cancelling them.
  bool isShortHanded(int seatsPerTable) => seats < seatsPerTable;

  /// Whether [userId] plays at this table.
  bool includes(String userId) => players.any((p) => p.userId == userId);

  EntrantView? get winner {
    if (winnerUserId == null) return null;
    for (final p in players) {
      if (p.userId == winnerUserId) return p;
    }
    return null;
  }

  factory TableView.fromJson(Map<String, dynamic> j) => TableView(
    index: j['index'] as int? ?? 0,
    status: TableStatus.parse(j['status'] as String?),
    winnerUserId: j['winnerUserId'] as String?,
    roomCode: j['roomCode'] as String?,
    players: [
      for (final p in (j['players'] as List? ?? const []))
        EntrantView.fromJson(p as Map<String, dynamic>),
    ],
  );
}

/// One round of play. Mirrors `BracketRound`.
@immutable
class RoundView {
  /// 1-based.
  final int number;

  final List<TableView> tables;

  /// True when the winner of this round wins the tournament.
  final bool isFinal;

  const RoundView({
    required this.number,
    required this.tables,
    required this.isFinal,
  });

  /// A field small enough for one table has no "Round 1" — that table *is* the
  /// final, and naming it Round 1 would promise a round that never comes.
  String get label => isFinal ? 'Final Table' : 'Round $number';

  int get playerCount => tables.fold(0, (n, t) => n + t.seats);

  bool get isComplete =>
      tables.isNotEmpty &&
      tables.every((t) => t.status == TableStatus.finished);

  /// The table [userId] plays at this round, if any.
  TableView? tableFor(String userId) {
    for (final t in tables) {
      if (t.includes(userId)) return t;
    }
    return null;
  }

  factory RoundView.fromJson(Map<String, dynamic> j) => RoundView(
    number: j['number'] as int? ?? 1,
    isFinal: j['isFinal'] as bool? ?? false,
    tables: [
      for (final t in (j['tables'] as List? ?? const []))
        TableView.fromJson(t as Map<String, dynamic>),
    ],
  );
}

/// A tournament as it appears in a list.
@immutable
class TournamentSummary {
  final String id;
  final String name;
  final TournamentStatus status;

  /// When the clock fires. Whoever is active then gets seated.
  final DateTime startsAt;

  /// How many have registered.
  final int registered;

  /// The most this format seats.
  final int capacity;

  /// Fewest active players needed, or it is cancelled.
  final int minEntrants;

  /// Whether the viewer has registered.
  final bool isRegistered;

  const TournamentSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.startsAt,
    required this.registered,
    required this.capacity,
    required this.minEntrants,
    this.isRegistered = false,
  });

  bool get isScheduled => status == TournamentStatus.scheduled;
  bool get isRunning => status == TournamentStatus.running;
  bool get isFinished => status == TournamentStatus.finished;
  bool get isCancelled => status == TournamentStatus.cancelled;

  /// Every slot taken. Registration closes, but the clock still decides the
  /// start — a full field is not an early start.
  bool get isFull => registered >= capacity;

  /// Enough registered that it would run if everyone showed up. Not a promise:
  /// only players active at start time are counted.
  bool get hasQuorum => registered >= minEntrants;

  Duration timeUntilStart(DateTime now) => startsAt.difference(now);

  factory TournamentSummary.fromJson(Map<String, dynamic> j) =>
      TournamentSummary(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        status: TournamentStatus.parse(j['status'] as String?),
        startsAt:
            DateTime.tryParse(j['startsAt'] as String? ?? '')?.toLocal() ??
            DateTime.fromMillisecondsSinceEpoch(0),
        registered: j['registered'] as int? ?? 0,
        capacity: j['capacity'] as int? ?? 16,
        minEntrants: j['minEntrants'] as int? ?? 2,
        isRegistered: j['isRegistered'] as bool? ?? false,
      );
}

/// A tournament with its field and, once started, its bracket.
@immutable
class TournamentDetail {
  final TournamentSummary summary;

  /// Everyone registered, whether or not they are present.
  final List<EntrantView> entrants;

  /// Empty until the clock fires — the shape is not known before then.
  final List<RoundView> rounds;

  /// Seats at a full table, so the UI can mark short-handed ones.
  final int seatsPerTable;

  /// Set once decided.
  final String? championUserId;

  /// Why it was called off, when it was.
  final String? cancelledReason;

  const TournamentDetail({
    required this.summary,
    required this.entrants,
    required this.rounds,
    this.seatsPerTable = 4,
    this.championUserId,
    this.cancelledReason,
  });

  String get id => summary.id;
  TournamentStatus get status => summary.status;

  /// How many registered entrants are present right now.
  int get activeCount => entrants.where((e) => e.active).length;

  /// The round being played, or the last one played.
  RoundView? get currentRound => rounds.isEmpty ? null : rounds.last;

  /// The table [userId] is at right now, if they are still in.
  TableView? currentTableFor(String userId) => currentRound?.tableFor(userId);

  /// Whether [userId] is still in the tournament.
  bool isStillIn(String userId) {
    if (rounds.isEmpty) return entrants.any((e) => e.userId == userId);
    return currentRound?.tableFor(userId) != null;
  }

  EntrantView? get champion {
    final id = championUserId;
    if (id == null) return null;
    for (final e in entrants) {
      if (e.userId == id) return e;
    }
    // A finished tournament may arrive with only its bracket populated, so fall
    // back to the tables rather than dropping the champion silently.
    for (final r in rounds.reversed) {
      for (final t in r.tables) {
        for (final p in t.players) {
          if (p.userId == id) return p;
        }
      }
    }
    return null;
  }

  factory TournamentDetail.fromJson(Map<String, dynamic> j) => TournamentDetail(
    summary: TournamentSummary.fromJson(j),
    seatsPerTable: j['seatsPerTable'] as int? ?? 4,
    championUserId: j['championUserId'] as String?,
    cancelledReason: j['cancelledReason'] as String?,
    entrants: [
      for (final e in (j['entrants'] as List? ?? const []))
        EntrantView.fromJson(e as Map<String, dynamic>),
    ],
    rounds: [
      for (final r in (j['rounds'] as List? ?? const []))
        RoundView.fromJson(r as Map<String, dynamic>),
    ],
  );
}

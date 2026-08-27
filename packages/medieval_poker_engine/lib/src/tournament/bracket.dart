/// Tournament bracket shape: who sits at which table, and who plays next.
///
/// Pure logic — no transport, no persistence, no clock. A host decides *when*
/// to start (a scheduler) and *where* tables run (rooms); this decides the
/// shape. That split is deliberate: the shape is the part with real edge cases,
/// and it is worth testing without a server attached.
library;

/// How a tournament is sized.
class TournamentRules {
  /// Most tables that may run at once in the opening round.
  ///
  /// This also caps the final table: one winner comes off each opening table,
  /// so [maxTables] winners must themselves fit at a single table.
  final int maxTables;

  /// A full table.
  final int seatsPerTable;

  /// Fewest players a table may run with. Two is a real table — the game is
  /// ante-based, so heads-up needs no special casing.
  final int minSeatsPerTable;

  const TournamentRules({
    this.maxTables = 4,
    this.seatsPerTable = 4,
    this.minSeatsPerTable = 2,
  }) : assert(maxTables >= 1),
       assert(seatsPerTable >= 2),
       assert(minSeatsPerTable >= 2),
       assert(
         minSeatsPerTable <= seatsPerTable,
         'a table cannot require more players than it seats',
       ),
       assert(
         maxTables <= seatsPerTable,
         'every opening table sends one winner to the final table, so there '
         'cannot be more opening tables than seats at that final table',
       );

  /// The most entrants this format can seat at once.
  int get capacity => maxTables * seatsPerTable;

  /// Fewest players that can start a tournament at all.
  int get minEntrants => minSeatsPerTable;
}

/// One table within a round.
class TableAssignment {
  /// Position of this table in the round, 0-based.
  final int index;

  /// Who sits here, in seat order.
  final List<String> playerIds;

  const TableAssignment({required this.index, required this.playerIds});

  int get seats => playerIds.length;

  /// True when this table is running short of a full complement.
  bool isShortHanded(TournamentRules rules) => seats < rules.seatsPerTable;

  @override
  String toString() => 'Table $index: $playerIds';
}

/// One round of play.
class BracketRound {
  /// 1-based.
  final int number;

  /// Tables playing simultaneously in this round.
  final List<TableAssignment> tables;

  /// True when the winner of this round wins the tournament.
  final bool isFinal;

  const BracketRound({
    required this.number,
    required this.tables,
    required this.isFinal,
  });

  /// What to call this round in the UI.
  ///
  /// A tournament small enough to fit one table has no "Round 1" — that single
  /// table *is* the final, and calling it Round 1 would promise a round that
  /// never comes.
  String get label => isFinal ? 'Final Table' : 'Round $number';

  /// Everyone playing this round.
  List<String> get playerIds => [for (final t in tables) ...t.playerIds];

  int get playerCount => tables.fold(0, (n, t) => n + t.seats);

  @override
  String toString() => '$label (${tables.length} tables, $playerCount players)';
}

/// Why a tournament could not start.
enum BracketRefusal {
  /// Fewer players turned up than the format allows.
  tooFewPlayers,

  /// More players than the format can seat.
  overCapacity,

  /// The same player was entered more than once.
  duplicatePlayer,
}

/// Thrown when a bracket cannot be built from the given entrants.
class BracketException implements Exception {
  final BracketRefusal reason;
  final String message;
  const BracketException(this.reason, this.message);

  @override
  String toString() => 'BracketException($reason): $message';
}

/// Builds and advances a bracket.
///
/// The shape is not known until the clock fires: entrants register, but only
/// those present at start time are seated, so a sixteen-player sign-up can open
/// as a single heads-up table. Callers must render whatever comes back rather
/// than assuming a fixed tree.
class TournamentBracket {
  final TournamentRules rules;

  const TournamentBracket({this.rules = const TournamentRules()});

  /// Whether [activePlayers] is enough to begin.
  bool canStart(int activePlayers) =>
      activePlayers >= rules.minEntrants && activePlayers <= rules.capacity;

  /// The opening round for the players present when the clock fires.
  ///
  /// Players are dealt round-robin across tables rather than sliced in blocks,
  /// so registration order does not concentrate early sign-ups at one table.
  /// That also distributes the shortfall evenly: five players open as 3 + 2,
  /// never 4 + 1, which would leave a table below the minimum.
  ///
  /// Throws [BracketException] if the field cannot be seated.
  BracketRound openingRound(List<String> activePlayers) {
    final n = activePlayers.length;

    if (activePlayers.toSet().length != n) {
      throw const BracketException(
        BracketRefusal.duplicatePlayer,
        'the same player was entered more than once',
      );
    }
    if (n < rules.minEntrants) {
      throw BracketException(
        BracketRefusal.tooFewPlayers,
        'need at least ${rules.minEntrants} players to start, got $n',
      );
    }
    if (n > rules.capacity) {
      throw BracketException(
        BracketRefusal.overCapacity,
        'this format seats at most ${rules.capacity} players, got $n',
      );
    }

    final tableCount = _tableCountFor(n);
    return _round(number: 1, playerIds: activePlayers, tableCount: tableCount);
  }

  /// The round after [previous], given the winner of each of its tables.
  ///
  /// Returns null when the tournament is over — that is, when [previous] was
  /// already the final table.
  ///
  /// [winners] must hold exactly one player per table in [previous]; a table
  /// always produces a winner, so a short list means a result is still missing.
  BracketRound? nextRound(BracketRound previous, List<String> winners) {
    if (previous.isFinal) return null;

    if (winners.length != previous.tables.length) {
      throw BracketException(
        BracketRefusal.tooFewPlayers,
        'expected one winner per table: ${previous.tables.length} tables, '
        'got ${winners.length} winners',
      );
    }
    if (winners.toSet().length != winners.length) {
      throw const BracketException(
        BracketRefusal.duplicatePlayer,
        'the same player won more than one table',
      );
    }

    // Winners always fit a single table: TournamentRules asserts that there are
    // never more opening tables than seats at the final one.
    return _round(
      number: previous.number + 1,
      playerIds: winners,
      tableCount: 1,
    );
  }

  /// How many tables [n] players should open on.
  ///
  /// As few tables as will hold them, so players stay concentrated rather than
  /// spread thin — then capped so no table drops below the minimum.
  int _tableCountFor(int n) {
    final byCapacity = (n + rules.seatsPerTable - 1) ~/ rules.seatsPerTable;
    final byMinimum = n ~/ rules.minSeatsPerTable;
    final count = byCapacity.clamp(1, rules.maxTables);
    return count.clamp(1, byMinimum < 1 ? 1 : byMinimum);
  }

  /// Deals [playerIds] round-robin across [tableCount] tables.
  BracketRound _round({
    required int number,
    required List<String> playerIds,
    required int tableCount,
  }) {
    final buckets = List.generate(tableCount, (_) => <String>[]);
    for (var i = 0; i < playerIds.length; i++) {
      buckets[i % tableCount].add(playerIds[i]);
    }

    return BracketRound(
      number: number,
      tables: [
        for (var i = 0; i < tableCount; i++)
          TableAssignment(index: i, playerIds: buckets[i]),
      ],
      // One table left means its winner takes the tournament.
      isFinal: tableCount == 1,
    );
  }
}

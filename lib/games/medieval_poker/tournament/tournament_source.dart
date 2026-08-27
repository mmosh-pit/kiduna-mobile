import 'dart:async';
import 'dart:math';

import 'package:medieval_poker_engine/tournament.dart';

import 'tournament_models.dart';

/// Where tournament state comes from.
///
/// One seam, two implementations: [FakeTournamentSource] runs a whole
/// tournament in memory so the screens can be built and demoed before the
/// backend exists, and a REST-backed one talks to the real service. The screens
/// bind only to this — they never know which they have.
abstract interface class TournamentSource {
  /// Tournaments visible to this viewer, soonest first.
  Future<List<TournamentSummary>> list();

  /// Full detail including the bracket, once there is one.
  Future<TournamentDetail> detail(String id);

  /// Enter the viewer. Returns the updated detail.
  Future<TournamentDetail> register(String id);

  /// Withdraw the viewer before it starts.
  Future<TournamentDetail> withdraw(String id);

  /// Schedule a new tournament. It starts on [startsAt], not when it fills.
  Future<TournamentDetail> create({
    required String name,
    required DateTime startsAt,
    int? maxTables,
    int? seatsPerTable,
    int? minSeatsPerTable,
  });

  void dispose();
}

/// A complete tournament, in memory, on a real clock.
///
/// It genuinely runs: the clock fires at [TournamentSummary.startsAt], seats
/// whoever is active using the same [TournamentBracket] the server would use,
/// plays tables out, and advances winners to the final. That means the screens
/// are exercised against real shapes — including a field too small to need a
/// first round, and a start that cancels for want of players — rather than a
/// fixture that only ever shows the happy path.
class FakeTournamentSource implements TournamentSource {
  /// Who is looking. Their rows are marked "You".
  final String viewerId;

  /// Seconds a table takes to play out, once started.
  final Duration tableDuration;

  final TournamentBracket bracket;
  final Random _rng;
  final Map<String, _FakeTournament> _byId = {};
  Timer? _tick;

  FakeTournamentSource({
    this.viewerId = 'you',
    this.tableDuration = const Duration(seconds: 6),
    this.bracket = const TournamentBracket(),
    Random? rng,
    DateTime? now,
  }) : _rng = rng ?? Random(7) {
    final t0 = now ?? DateTime.now();
    _seed(t0);
    _tick = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _advanceAll(DateTime.now());
    });
  }

  void _seed(DateTime now) {
    // Starting soon, viewer not yet entered — the ordinary case.
    _byId['t1'] = _FakeTournament(
      id: 't1',
      name: 'The Winter Crown',
      startsAt: now.add(const Duration(seconds: 25)),
      entrants: _field(9),
    );

    // Already under way, viewer playing.
    final running = _FakeTournament(
      id: 't2',
      name: 'Blackwater Open',
      startsAt: now.subtract(const Duration(seconds: 10)),
      entrants: [_FakeEntrant(viewerId, 'You', active: true), ..._field(11)],
      registered: true,
    );
    _byId['t2'] = running;

    // Too small to need a first round: it opens straight onto a final table.
    _byId['t3'] = _FakeTournament(
      id: 't3',
      name: 'Tavern Duel',
      startsAt: now.add(const Duration(seconds: 70)),
      entrants: [_FakeEntrant(viewerId, 'You', active: true), ..._field(2)],
      registered: true,
    );

    // Will cancel: only one player is present when the clock fires.
    _byId['t4'] = _FakeTournament(
      id: 't4',
      name: 'The Empty Hall',
      startsAt: now.add(const Duration(seconds: 40)),
      entrants: [_FakeEntrant('ghost', 'Solitary Knight', active: true)],
    );
  }

  static const _names = [
    'Rowan',
    'Ada',
    'Bors',
    'Isolde',
    'Gareth',
    'Nimue',
    'Percival',
    'Elaine',
    'Tristan',
    'Morgause',
    'Kay',
    'Lyonesse',
  ];

  List<_FakeEntrant> _field(int n) => [
    for (var i = 0; i < n; i++)
      _FakeEntrant('p$i', _names[i % _names.length], active: true),
  ];

  @override
  Future<List<TournamentSummary>> list() async {
    final all = _byId.values.map((t) => t.summary(viewerId)).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return all;
  }

  @override
  Future<TournamentDetail> detail(String id) async {
    final t = _byId[id];
    if (t == null) throw StateError('no such tournament: $id');
    return t.detail(viewerId);
  }

  @override
  Future<TournamentDetail> register(String id) async {
    final t = _byId[id]!;
    if (t.status == TournamentStatus.scheduled &&
        !t.entrants.any((e) => e.userId == viewerId)) {
      t.entrants.add(_FakeEntrant(viewerId, 'You', active: true));
    }
    return t.detail(viewerId);
  }

  @override
  Future<TournamentDetail> withdraw(String id) async {
    final t = _byId[id]!;
    if (t.status == TournamentStatus.scheduled) {
      t.entrants.removeWhere((e) => e.userId == viewerId);
    }
    return t.detail(viewerId);
  }

  @override
  Future<TournamentDetail> create({
    required String name,
    required DateTime startsAt,
    int? maxTables,
    int? seatsPerTable,
    int? minSeatsPerTable,
  }) async {
    final id = 'local-${_byId.length + 1}';
    _byId[id] = _FakeTournament(
      id: id,
      name: name,
      startsAt: startsAt,
      // The creator is in it; a tournament of one still cancels on the clock,
      // which is the behaviour worth being able to see.
      entrants: [_FakeEntrant(viewerId, 'You', active: true)],
      registered: true,
    );
    return _byId[id]!.detail(viewerId);
  }

  /// Advance the simulation to [now].
  ///
  /// The internal ticker calls this with wall time; tests drive it directly so
  /// a whole tournament can be run without waiting on a real clock.
  void pump(DateTime now) => _advanceAll(now);

  void _advanceAll(DateTime now) {
    for (final t in _byId.values) {
      t.advance(now, bracket, _rng, tableDuration);
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _tick = null;
  }
}

class _FakeEntrant {
  final String userId;
  final String name;
  bool active;
  int? finalRank;
  _FakeEntrant(this.userId, this.name, {this.active = false});
}

class _FakeTable {
  final int index;
  final List<_FakeEntrant> players;
  TableStatus status = TableStatus.pending;
  String? winnerUserId;
  DateTime? startedAt;
  _FakeTable(this.index, this.players);
}

class _FakeRound {
  final int number;
  final bool isFinal;
  final List<_FakeTable> tables;
  _FakeRound(this.number, this.isFinal, this.tables);
  bool get isComplete => tables.every((t) => t.status == TableStatus.finished);
}

class _FakeTournament {
  final String id;
  final String name;
  final DateTime startsAt;
  final List<_FakeEntrant> entrants;
  final bool registered;

  TournamentStatus status = TournamentStatus.scheduled;
  final List<_FakeRound> rounds = [];
  String? championUserId;
  String? cancelledReason;
  int _nextRank = 0;

  _FakeTournament({
    required this.id,
    required this.name,
    required this.startsAt,
    required List<_FakeEntrant> entrants,
    this.registered = false,
  }) : entrants = [...entrants];

  /// Drive the clock: start, play tables out, advance, finish.
  void advance(
    DateTime now,
    TournamentBracket bracket,
    Random rng,
    Duration tableDuration,
  ) {
    if (status == TournamentStatus.scheduled && !now.isBefore(startsAt)) {
      _start(bracket);
      return;
    }
    if (status != TournamentStatus.running) return;

    final round = rounds.last;
    for (final table in round.tables) {
      if (table.status == TableStatus.pending) {
        table.status = TableStatus.active;
        table.startedAt = now;
      } else if (table.status == TableStatus.active &&
          table.startedAt != null &&
          now.difference(table.startedAt!) >= tableDuration) {
        _finishTable(table, rng);
      }
    }

    if (round.isComplete) _afterRound(round, bracket);
  }

  void _start(TournamentBracket bracket) {
    final active = entrants.where((e) => e.active).toList();
    if (!bracket.canStart(active.length)) {
      status = TournamentStatus.cancelled;
      cancelledReason = active.length < bracket.rules.minEntrants
          ? 'Only ${active.length} player${active.length == 1 ? "" : "s"} '
                'turned up — ${bracket.rules.minEntrants} are needed.'
          : 'Too many players for this format.';
      return;
    }
    _seatRound(bracket.openingRound([for (final e in active) e.userId]));
    status = TournamentStatus.running;
  }

  void _seatRound(BracketRound shape) {
    rounds.add(
      _FakeRound(shape.number, shape.isFinal, [
        for (final t in shape.tables)
          _FakeTable(t.index, [
            for (final id in t.playerIds)
              entrants.firstWhere((e) => e.userId == id),
          ]),
      ]),
    );
  }

  void _finishTable(_FakeTable table, Random rng) {
    final winner = table.players[rng.nextInt(table.players.length)];
    table.winnerUserId = winner.userId;
    table.status = TableStatus.finished;
    // Everyone else at this table is out; rank them from the bottom up.
    for (final p in table.players) {
      if (p.userId != winner.userId) p.finalRank = ++_nextRank;
    }
  }

  void _afterRound(_FakeRound round, TournamentBracket bracket) {
    final winners = [for (final t in round.tables) t.winnerUserId!];

    if (round.isFinal) {
      championUserId = winners.single;
      for (final e in entrants) {
        if (e.userId == championUserId) e.finalRank = ++_nextRank;
      }
      // Ranks were assigned bottom-up; flip so 1 is the champion.
      final total = _nextRank;
      for (final e in entrants) {
        if (e.finalRank != null) e.finalRank = total - e.finalRank! + 1;
      }
      status = TournamentStatus.finished;
      return;
    }

    final shape = bracket.nextRound(
      BracketRound(
        number: round.number,
        isFinal: round.isFinal,
        tables: [
          for (final t in round.tables)
            TableAssignment(
              index: t.index,
              playerIds: [for (final p in t.players) p.userId],
            ),
        ],
      ),
      winners,
    );
    if (shape != null) _seatRound(shape);
  }

  TournamentSummary summary(String viewerId) => TournamentSummary(
    id: id,
    name: name,
    status: status,
    startsAt: startsAt,
    registered: entrants.length,
    capacity: 16,
    minEntrants: 2,
    isRegistered: entrants.any((e) => e.userId == viewerId),
  );

  TournamentDetail detail(String viewerId) => TournamentDetail(
    summary: summary(viewerId),
    championUserId: championUserId,
    cancelledReason: cancelledReason,
    entrants: [for (final e in entrants) _view(e)],
    rounds: [
      for (final r in rounds)
        RoundView(
          number: r.number,
          isFinal: r.isFinal,
          tables: [
            for (final t in r.tables)
              TableView(
                index: t.index,
                status: t.status,
                winnerUserId: t.winnerUserId,
                roomCode: '$id-r${r.number}-t${t.index}',
                players: [for (final p in t.players) _view(p)],
              ),
          ],
        ),
    ],
  );

  EntrantView _view(_FakeEntrant e) => EntrantView(
    userId: e.userId,
    name: e.name,
    active: e.active,
    finalRank: e.finalRank,
  );
}

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/games/medieval_poker/tournament/tournament_models.dart';
import 'package:kiduna/games/medieval_poker/tournament/tournament_source.dart';

/// The in-memory source is what the screens are built against until the backend
/// exists, so it has to produce real shapes — a field that opens straight onto
/// a final table, a start that cancels for want of players — not just the happy
/// path. These tests drive its clock directly rather than waiting on wall time.

final _t0 = DateTime.utc(2026, 9, 24, 19, 0);

FakeTournamentSource _source() => FakeTournamentSource(
  viewerId: 'you',
  tableDuration: const Duration(seconds: 5),
  rng: Random(11),
  now: _t0,
);

/// Step the simulation forward in small increments, as the real ticker would.
void _run(FakeTournamentSource s, Duration total) {
  const step = Duration(milliseconds: 500);
  for (var t = Duration.zero; t <= total; t += step) {
    s.pump(_t0.add(t));
  }
}

void main() {
  test('lists tournaments soonest first', () async {
    final s = _source();
    addTearDown(s.dispose);

    final list = await s.list();
    expect(list, isNotEmpty);
    for (var i = 1; i < list.length; i++) {
      expect(
        list[i].startsAt.isBefore(list[i - 1].startsAt),
        isFalse,
        reason: 'list is not sorted by start time',
      );
    }
  });

  test('nothing has a bracket before its clock fires', () async {
    final s = _source();
    addTearDown(s.dispose);

    final t = await s.detail('t1');
    expect(t.status, TournamentStatus.scheduled);
    expect(
      t.rounds,
      isEmpty,
      reason: 'the shape is not known before the start',
    );
    expect(t.entrants, isNotEmpty);
  });

  group('registration', () {
    test('register and withdraw before the start', () async {
      final s = _source();
      addTearDown(s.dispose);

      expect((await s.detail('t1')).summary.isRegistered, isFalse);

      final joined = await s.register('t1');
      expect(joined.summary.isRegistered, isTrue);
      expect(joined.entrants.any((e) => e.userId == 'you'), isTrue);

      final left = await s.withdraw('t1');
      expect(left.summary.isRegistered, isFalse);
    });

    test('registering twice does not duplicate the entrant', () async {
      final s = _source();
      addTearDown(s.dispose);

      await s.register('t1');
      final twice = await s.register('t1');
      expect(twice.entrants.where((e) => e.userId == 'you'), hasLength(1));
    });

    test('cannot withdraw once it is running', () async {
      final s = _source();
      addTearDown(s.dispose);

      _run(s, const Duration(seconds: 30)); // t1 starts at +25s
      expect((await s.detail('t1')).status, TournamentStatus.running);

      await s.register('t1');
      final after = await s.detail('t1');
      expect(
        after.entrants.any((e) => e.userId == 'you'),
        isFalse,
        reason: 'a running tournament must not accept late entrants',
      );
    });
  });

  group('the clock', () {
    test('a nine-player field opens on three tables', () async {
      final s = _source();
      addTearDown(s.dispose);

      _run(s, const Duration(seconds: 26));
      final t = await s.detail('t1');

      expect(t.status, TournamentStatus.running);
      expect(t.rounds, hasLength(1));
      expect(t.rounds.first.tables, hasLength(3));
      expect(t.rounds.first.isFinal, isFalse);
      expect(t.rounds.first.label, 'Round 1');
      expect(t.rounds.first.playerCount, 9);
    });

    test('a three-player field opens straight onto the final table', () async {
      final s = _source();
      addTearDown(s.dispose);

      _run(s, const Duration(seconds: 72)); // t3 starts at +70s
      final t = await s.detail('t3');

      expect(t.rounds, hasLength(1));
      expect(t.rounds.first.tables, hasLength(1));
      expect(
        t.rounds.first.isFinal,
        isTrue,
        reason: 'one table means it is the final, not Round 1',
      );
      expect(t.rounds.first.label, 'Final Table');
    });

    test('one player present cancels rather than starting', () async {
      final s = _source();
      addTearDown(s.dispose);

      _run(s, const Duration(seconds: 45)); // t4 starts at +40s
      final t = await s.detail('t4');

      expect(t.status, TournamentStatus.cancelled);
      expect(t.rounds, isEmpty);
      expect(t.cancelledReason, isNotNull);
      expect(t.cancelledReason, contains('Only 1 player'));
    });
  });

  group('playing out', () {
    test('runs to a champion, and everyone gets a place', () async {
      final s = _source();
      addTearDown(s.dispose);

      // t2 is already under way at t0; two rounds of 5s tables plus slack.
      _run(s, const Duration(seconds: 40));
      final t = await s.detail('t2');

      expect(t.status, TournamentStatus.finished);
      expect(t.championUserId, isNotNull);
      expect(t.champion, isNotNull);

      final ranks = [
        for (final e in t.entrants)
          if (e.finalRank != null) e.finalRank!,
      ]..sort();
      expect(ranks, [
        for (var i = 1; i <= t.entrants.length; i++) i,
      ], reason: 'places must be 1..n with no gaps or ties');
      expect(t.champion!.finalRank, 1);
      expect(t.champion!.isChampion, isTrue);
    });

    test('the final round holds one table of the winners', () async {
      final s = _source();
      addTearDown(s.dispose);

      _run(s, const Duration(seconds: 40));
      final t = await s.detail('t2');

      expect(t.rounds.length, greaterThanOrEqualTo(2));
      final last = t.rounds.last;
      expect(last.isFinal, isTrue);
      expect(last.tables, hasLength(1));
      expect(last.tables.single.seats, t.rounds.first.tables.length);
    });

    test('every table reports a winner who sat at it', () async {
      final s = _source();
      addTearDown(s.dispose);

      _run(s, const Duration(seconds: 40));
      final t = await s.detail('t2');

      for (final round in t.rounds) {
        for (final table in round.tables) {
          expect(table.status, TableStatus.finished);
          expect(table.winnerUserId, isNotNull);
          expect(
            table.includes(table.winnerUserId!),
            isTrue,
            reason: 'a table was won by someone who was not seated at it',
          );
          expect(table.winner, isNotNull);
        }
      }
    });

    test('tables carry a room code to connect to', () async {
      final s = _source();
      addTearDown(s.dispose);

      _run(s, const Duration(seconds: 26));
      final t = await s.detail('t1');

      for (final table in t.rounds.first.tables) {
        expect(table.roomCode, isNotNull);
        expect(table.roomCode, isNotEmpty);
      }
    });
  });

  group('viewer position', () {
    test('reports the table the viewer is at', () async {
      final s = _source();
      addTearDown(s.dispose);

      _run(s, const Duration(seconds: 1));
      final t = await s.detail('t2');

      final mine = t.currentTableFor('you');
      expect(mine, isNotNull);
      expect(mine!.includes('you'), isTrue);
      expect(t.isStillIn('you'), isTrue);
    });

    test('a knocked-out viewer is no longer at a table', () async {
      final s = _source();
      addTearDown(s.dispose);

      _run(s, const Duration(seconds: 40));
      final t = await s.detail('t2');

      // Whether they won or lost, the two must agree.
      expect(t.isStillIn('you'), t.currentTableFor('you') != null);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:medieval_poker_engine/tournament.dart';

/// The tournament format: four tables in the opening round, then a final table.
/// Tables run short-handed down to two players, because entrants who registered
/// may not be present when the clock fires.
const _rules = TournamentRules();
const _bracket = TournamentBracket(rules: _rules);

List<String> _players(int n) => [for (var i = 0; i < n; i++) 'p$i'];

/// Table sizes for a field of [n], largest first.
List<int> _shape(int n) =>
    [for (final t in _bracket.openingRound(_players(n)).tables) t.seats]
      ..sort((a, b) => b.compareTo(a));

void main() {
  group('format', () {
    test('seats sixteen at most', () {
      expect(_rules.capacity, 16);
    });

    test('needs two players to run', () {
      expect(_rules.minEntrants, 2);
      expect(_bracket.canStart(0), isFalse);
      expect(_bracket.canStart(1), isFalse);
      expect(_bracket.canStart(2), isTrue);
      expect(_bracket.canStart(16), isTrue);
      expect(_bracket.canStart(17), isFalse);
    });
  });

  group('opening round shape', () {
    // The awkward cases are the point: an odd field must not leave a table
    // below the two-player minimum.
    const expected = <int, List<int>>{
      2: [2],
      3: [3],
      4: [4],
      5: [3, 2], // not 4 + 1 — that second table could not run
      6: [3, 3],
      7: [4, 3],
      8: [4, 4],
      9: [3, 3, 3],
      10: [4, 3, 3],
      11: [4, 4, 3],
      12: [4, 4, 4],
      13: [4, 3, 3, 3],
      14: [4, 4, 3, 3],
      15: [4, 4, 4, 3],
      16: [4, 4, 4, 4],
    };

    expected.forEach((n, shape) {
      test('$n players open as ${shape.join(" + ")}', () {
        expect(_shape(n), shape);
      });
    });

    for (var n = 2; n <= 16; n++) {
      test('$n players: no table falls below the minimum', () {
        for (final t in _bracket.openingRound(_players(n)).tables) {
          expect(
            t.seats,
            greaterThanOrEqualTo(_rules.minSeatsPerTable),
            reason: 'table ${t.index} could not run with ${t.seats} players',
          );
          expect(t.seats, lessThanOrEqualTo(_rules.seatsPerTable));
        }
      });

      test('$n players: everyone is seated exactly once', () {
        final round = _bracket.openingRound(_players(n));
        expect(round.playerCount, n);
        expect(round.playerIds.toSet(), _players(n).toSet());
      });

      test('$n players: never more than four tables', () {
        expect(
          _bracket.openingRound(_players(n)).tables.length,
          lessThanOrEqualTo(_rules.maxTables),
        );
      });
    }
  });

  group('a field that fits one table has no first round', () {
    for (final n in [2, 3, 4]) {
      test('$n players open straight onto the final table', () {
        final round = _bracket.openingRound(_players(n));

        expect(round.tables, hasLength(1));
        expect(round.isFinal, isTrue);
        expect(round.label, 'Final Table');
        expect(
          _bracket.nextRound(round, ['p0']),
          isNull,
          reason: 'there is nothing after the final table',
        );
      });
    }

    test('five players do get a first round', () {
      final round = _bracket.openingRound(_players(5));
      expect(round.isFinal, isFalse);
      expect(round.label, 'Round 1');
    });
  });

  group('seating is dealt, not sliced', () {
    test('registration order does not pile early sign-ups onto one table', () {
      final round = _bracket.openingRound(_players(8));

      // Dealt round-robin: table 0 takes p0, p2, p4, p6.
      expect(round.tables[0].playerIds, ['p0', 'p2', 'p4', 'p6']);
      expect(round.tables[1].playerIds, ['p1', 'p3', 'p5', 'p7']);
    });

    test('the shortfall lands on the last table, not the first', () {
      final round = _bracket.openingRound(_players(5));
      expect(round.tables[0].seats, 3);
      expect(round.tables[1].seats, 2);
    });
  });

  group('advancing', () {
    test('table winners meet at the final table', () {
      final opening = _bracket.openingRound(_players(16));
      expect(opening.tables, hasLength(4));
      expect(opening.isFinal, isFalse);

      final finalRound = _bracket.nextRound(opening, ['p0', 'p1', 'p2', 'p3'])!;

      expect(finalRound.number, 2);
      expect(finalRound.tables, hasLength(1));
      expect(finalRound.isFinal, isTrue);
      expect(finalRound.label, 'Final Table');
      expect(finalRound.playerIds, ['p0', 'p1', 'p2', 'p3']);
    });

    test('two opening tables make a heads-up final', () {
      final opening = _bracket.openingRound(_players(6));
      expect(opening.tables, hasLength(2));

      final finalRound = _bracket.nextRound(opening, ['p0', 'p1'])!;
      expect(finalRound.tables.single.seats, 2);
      expect(finalRound.isFinal, isTrue);
    });

    test('three opening tables make a three-handed final', () {
      final opening = _bracket.openingRound(_players(9));
      expect(opening.tables, hasLength(3));

      final finalRound = _bracket.nextRound(opening, ['p0', 'p1', 'p2'])!;
      expect(finalRound.tables.single.seats, 3);
    });

    test('the final table is always reachable in one more round', () {
      // Four opening tables is the cap precisely so four winners fit one table.
      for (var n = 5; n <= 16; n++) {
        final opening = _bracket.openingRound(_players(n));
        final winners = [for (final t in opening.tables) t.playerIds.first];
        final next = _bracket.nextRound(opening, winners)!;
        expect(next.isFinal, isTrue, reason: '$n players needed a third round');
        expect(next.tables.single.seats, lessThanOrEqualTo(4));
      }
    });

    test('a missing result is refused rather than guessed', () {
      final opening = _bracket.openingRound(_players(16));
      expect(
        () => _bracket.nextRound(opening, ['p0', 'p1']),
        throwsA(isA<BracketException>()),
      );
    });

    test('one player cannot win two tables', () {
      final opening = _bracket.openingRound(_players(8));
      expect(
        () => _bracket.nextRound(opening, ['p0', 'p0']),
        throwsA(
          isA<BracketException>().having(
            (e) => e.reason,
            'reason',
            BracketRefusal.duplicatePlayer,
          ),
        ),
      );
    });
  });

  group('refusals', () {
    test('a lone entrant cannot start a tournament', () {
      expect(
        () => _bracket.openingRound(_players(1)),
        throwsA(
          isA<BracketException>().having(
            (e) => e.reason,
            'reason',
            BracketRefusal.tooFewPlayers,
          ),
        ),
      );
    });

    test('an empty field cannot start a tournament', () {
      expect(
        () => _bracket.openingRound(const []),
        throwsA(isA<BracketException>()),
      );
    });

    test('a field over capacity is refused', () {
      expect(
        () => _bracket.openingRound(_players(17)),
        throwsA(
          isA<BracketException>().having(
            (e) => e.reason,
            'reason',
            BracketRefusal.overCapacity,
          ),
        ),
      );
    });

    test('the same player cannot be entered twice', () {
      expect(
        () => _bracket.openingRound(['p0', 'p1', 'p0']),
        throwsA(
          isA<BracketException>().having(
            (e) => e.reason,
            'reason',
            BracketRefusal.duplicatePlayer,
          ),
        ),
      );
    });
  });

  group('short-handed reporting', () {
    test('a full table is not flagged short-handed', () {
      final round = _bracket.openingRound(_players(8));
      expect(round.tables.every((t) => t.isShortHanded(_rules)), isFalse);
    });

    test('an under-filled table is flagged', () {
      final round = _bracket.openingRound(_players(5));
      expect(round.tables.every((t) => t.isShortHanded(_rules)), isTrue);
    });
  });

  group('other formats', () {
    test('a two-table format caps at eight and finals heads-up', () {
      const rules = TournamentRules(maxTables: 2);
      const bracket = TournamentBracket(rules: rules);

      expect(rules.capacity, 8);
      final opening = bracket.openingRound(_players(8));
      expect(opening.tables, hasLength(2));

      final finalRound = bracket.nextRound(opening, ['p0', 'p1'])!;
      expect(finalRound.tables.single.seats, 2);
      expect(finalRound.isFinal, isTrue);
    });

    test('six-seat tables seat more players per table', () {
      const bracket = TournamentBracket(
        rules: TournamentRules(maxTables: 3, seatsPerTable: 6),
      );

      expect(bracket.rules.capacity, 18);
      expect(
        [for (final t in bracket.openingRound(_players(7)).tables) t.seats],
        [4, 3],
      );
    });
  });
}

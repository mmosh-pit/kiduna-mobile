import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:medieval_poker_engine/medieval_poker_engine.dart';
import 'package:medieval_poker_engine/service.dart';

/// Characterization + finishing-rank tests for the elimination path.
///
/// The engine shipped with no tests, so the first group pins down behaviour
/// that already existed — a game terminates, exactly one winner emerges, a
/// fully seeded run replays — before the finishing-rank work builds on it.
///
/// The short-handed cases (2 and 3 seats) matter because tournament tables run
/// with as few as two players when no-shows leave a table light.
///
/// Note: chips are deliberately NOT conserved. Power Cards pay out of a bank,
/// so the table total grows over a game; any test asserting conservation is
/// asserting a rule this game does not have.

/// [count] AI seats on the standard starting stack.
List<PokerPlayer> _seats(int count, {int startingStack = 100}) => [
  for (var i = 0; i < count; i++)
    PokerPlayer(seat: i, name: 'Seat $i', stack: startingStack),
];

/// Plays one full game headlessly. Both the engine RNG and every AI brain are
/// seeded, which is what makes a run reproducible — seeding only the engine
/// leaves the AI free-running.
Future<PokerGame> _playOut(int seatCount, {int seed = 7}) async {
  final game = PokerGame(
    config: const PokerConfig(),
    players: _seats(seatCount),
    rng: Random(seed),
  );
  await GameDriver(
    game: game,
    agents: [
      for (var i = 0; i < seatCount; i++)
        AiAgent(i, brain: AiBrain(rng: Random(seed + i))),
    ],
  ).run();
  return game;
}

/// A game parked on hand 1 so elimination can be driven directly.
PokerGame _handInProgress({int seed = 3}) {
  final game = PokerGame(
    config: const PokerConfig(),
    players: _seats(4),
    rng: Random(seed),
  );
  game.drawForButton();
  return game;
}

void main() {
  group('characterization', () {
    for (final seatCount in [2, 3, 4]) {
      test('$seatCount players: the game ends and names one winner', () async {
        final game = await _playOut(seatCount);

        expect(
          game.isGameOver,
          isTrue,
          reason: 'driver returned before the game was over',
        );
        expect(
          game.gameWinner,
          isNotNull,
          reason: 'a finished game must have a winner',
        );
        expect(game.players, hasLength(seatCount));
        expect(game.remainingInGame, isNotEmpty);
      }, timeout: const Timeout(Duration(seconds: 30)));
    }

    test(
      'heads-up is well formed — the game is ante-based, not blinded',
      () async {
        final game = await _playOut(2);

        // With antes there is no small/big blind to reverse, which is why two
        // seats need no special-casing. Guard the invariant anyway.
        expect(game.players.every((p) => p.stack >= 0), isTrue);
        expect(game.gameWinner, isNotNull);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test('a fully seeded run replays identically', () async {
      final a = await _playOut(4, seed: 99);
      final b = await _playOut(4, seed: 99);

      expect(
        [for (final p in a.players) p.stack],
        [for (final p in b.players) p.stack],
      );
      expect(a.gameWinner!.seat, b.gameWinner!.seat);
    }, timeout: const Timeout(Duration(seconds: 60)));
  });

  group('finishing rank', () {
    test(
      'busted players carry an order and a hand; survivors carry neither',
      () async {
        final game = await _playOut(4);

        for (final p in game.players) {
          if (p.eliminated) {
            expect(
              p.eliminationOrder,
              isNotNull,
              reason: '${p.name} is out but has no elimination order',
            );
            expect(
              p.eliminatedAtHand,
              isNotNull,
              reason: '${p.name} is out but has no elimination hand',
            );
            expect(p.eliminatedAtHand, greaterThan(0));
          } else {
            expect(p.eliminationOrder, isNull);
            expect(p.eliminatedAtHand, isNull);
          }
        }
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test('elimination order is 1..k with no gaps or repeats', () async {
      final game = await _playOut(4);

      final orders = <int>[
        for (final p in game.players)
          if (p.eliminated) p.eliminationOrder!,
      ]..sort();

      expect(orders, [for (var i = 1; i <= orders.length; i++) i]);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test(
      'a later elimination order never happened on an earlier hand',
      () async {
        final game = await _playOut(4);

        final busted = <PokerPlayer>[
          for (final p in game.players)
            if (p.eliminated) p,
        ]..sort((a, b) => a.eliminationOrder!.compareTo(b.eliminationOrder!));

        for (var i = 1; i < busted.length; i++) {
          expect(
            busted[i].eliminatedAtHand,
            greaterThanOrEqualTo(busted[i - 1].eliminatedAtHand!),
            reason: 'elimination order contradicts the hand it happened on',
          );
        }
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    for (final seatCount in [2, 3, 4]) {
      test(
        '$seatCount players: finalStandings ranks everyone exactly once',
        () async {
          final game = await _playOut(seatCount);
          final standings = game.finalStandings;

          expect(standings, hasLength(seatCount));
          expect(
            standings.map((p) => p.seat).toSet(),
            game.players.map((p) => p.seat).toSet(),
            reason: 'a seat was dropped or duplicated',
          );
          expect(
            standings.first.seat,
            game.gameWinner!.seat,
            reason: 'the champion must be ranked first',
          );
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );
    }

    test('no survivor is ranked below a busted player', () async {
      final game = await _playOut(4);
      final standings = game.finalStandings;

      final lastSurvivor = standings.lastIndexWhere((p) => !p.eliminated);
      final firstBusted = standings.indexWhere((p) => p.eliminated);

      if (firstBusted != -1) {
        expect(lastSurvivor, lessThan(firstBusted));
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('busted players appear in reverse elimination order', () async {
      final game = await _playOut(4);

      final busted = <PokerPlayer>[
        for (final p in game.finalStandings)
          if (p.eliminated) p,
      ];

      // Standings are best-first, and busting later is a better finish.
      for (var i = 1; i < busted.length; i++) {
        expect(
          busted[i].eliminationOrder,
          lessThan(busted[i - 1].eliminationOrder!),
        );
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('finalRankOf agrees with the standings order', () async {
      final game = await _playOut(4);
      final standings = game.finalStandings;

      for (var i = 0; i < standings.length; i++) {
        expect(game.finalRankOf(standings[i]), i + 1);
      }
      expect(game.finalRankOf(game.gameWinner!), 1);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });

  group('same-hand busts', () {
    test('two players out on one hand get distinct consecutive orders', () {
      final game = _handInProgress();
      final players = game.players;

      game.startHand();
      players[1].stack = 0;
      players[2].stack = 0;

      game.applyEliminations();

      expect(players[1].eliminated, isTrue);
      expect(players[2].eliminated, isTrue);
      expect(players[1].eliminatedAtHand, game.handNumber);
      expect(players[2].eliminatedAtHand, game.handNumber);

      final orders = {players[1].eliminationOrder, players[2].eliminationOrder};
      expect(orders, hasLength(2), reason: 'orders must not be shared');
      expect(orders.contains(null), isFalse);
    });

    test('the deeper stack at hand start finishes higher', () {
      final game = _handInProgress();
      final players = game.players;

      // Seat 2 begins the hand with four times seat 1's chips.
      players[1].stack = 10;
      players[2].stack = 40;

      game.startHand();
      expect(players[1].stackAtHandStart, 10);
      expect(players[2].stackAtHandStart, 40);

      players[1].stack = 0;
      players[2].stack = 0;
      game.applyEliminations();

      // Finishing higher means being eliminated later in the ordering.
      expect(
        players[2].eliminationOrder,
        greaterThan(players[1].eliminationOrder!),
        reason: 'the deeper stack should finish higher',
      );
      expect(
        game.finalRankOf(players[2]),
        lessThan(game.finalRankOf(players[1])),
      );
    });

    test('applyEliminations is idempotent', () {
      final game = _handInProgress();
      final players = game.players;

      game.startHand();
      players[1].stack = 0;

      game.applyEliminations();
      final order = players[1].eliminationOrder;
      final hand = players[1].eliminatedAtHand;

      game.applyEliminations();
      game.applyEliminations();

      expect(
        players[1].eliminationOrder,
        order,
        reason: 're-running must not renumber an already-out player',
      );
      expect(players[1].eliminatedAtHand, hand);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/games/medieval_poker/session/game_session.dart';
import 'package:kiduna/games/medieval_poker/session/standings_screen.dart';

/// A finished four-seat table. Seat 3 takes it; the rest bust in order, which
/// is what gives every row a distinct place despite three of them ending on
/// zero chips.
GameOverView _table({
  bool youWon = false,
  TournamentOutcomeView? tournament,
  String detail = 'A rival takes the table.',
}) => GameOverView(
  youWon: youWon,
  winnerSeat: 3,
  detail: detail,
  tournament: tournament,
  standings: const [
    StandingView(3, 440, name: 'Rowan', rank: 1),
    StandingView(0, 0, name: 'Jeya', rank: 2, eliminatedAtHand: 17),
    StandingView(1, 0, name: 'Ada', rank: 3, eliminatedAtHand: 12),
    StandingView(2, 0, name: 'Bors', rank: 4, eliminatedAtHand: 8),
  ],
);

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(backgroundColor: Colors.black, body: child),
);

void main() {
  group('standings', () {
    testWidgets('every seat gets a place, even on equal chips', (tester) async {
      await tester.pumpWidget(
        _host(
          StandingsScreen(
            view: _table(),
            viewerSeat: 0,
            onExit: () {},
          ),
        ),
      );

      // Three players finished on zero chips but hold distinct places.
      for (final place in ['1', '2', '3', '4']) {
        expect(find.text(place), findsOneWidget);
      }
      expect(find.text('Rowan'), findsOneWidget);
      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('Bors'), findsOneWidget);
    });

    testWidgets('the viewer reads as "You", not their name', (tester) async {
      await tester.pumpWidget(
        _host(
          StandingsScreen(view: _table(), viewerSeat: 0, onExit: () {}),
        ),
      );

      expect(find.text('You'), findsOneWidget);
      expect(find.text('Jeya'), findsNothing);
    });

    testWidgets('elimination hand is shown, survivors are marked', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          StandingsScreen(view: _table(), viewerSeat: 0, onExit: () {}),
        ),
      );

      expect(find.text('still standing'), findsOneWidget);
      expect(find.text('out on hand 17'), findsOneWidget);
      expect(find.text('out on hand 8'), findsOneWidget);
    });

    testWidgets('falls back to list order when a server sends no rank', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          StandingsScreen(
            viewerSeat: 9,
            onExit: () {},
            view: const GameOverView(
              youWon: false,
              winnerSeat: 3,
              detail: 'x',
              standings: [
                StandingView(3, 440, name: 'Rowan'),
                StandingView(0, 0, name: 'Ada'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('an empty standings list does not crash', (tester) async {
      await tester.pumpWidget(
        _host(
          StandingsScreen(
            viewerSeat: 0,
            onExit: () {},
            view: const GameOverView(
              youWon: false,
              winnerSeat: null,
              detail: 'Table abandoned.',
              standings: [],
            ),
          ),
        ),
      );

      expect(find.text('Table abandoned.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('headline', () {
    testWidgets('casual table says Victory or Defeat', (tester) async {
      await tester.pumpWidget(
        _host(
          StandingsScreen(
            view: _table(youWon: true),
            viewerSeat: 3,
            onExit: () {},
          ),
        ),
      );
      expect(find.text('Victory'), findsOneWidget);

      await tester.pumpWidget(
        _host(
          StandingsScreen(view: _table(), viewerSeat: 0, onExit: () {}),
        ),
      );
      expect(find.text('Defeat'), findsOneWidget);
    });

    testWidgets('tournament round replaces Victory with You advance', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          StandingsScreen(
            viewerSeat: 3,
            onExit: () {},
            onContinue: () {},
            view: _table(
              youWon: true,
              tournament: const TournamentOutcomeView(
                roundLabel: 'Round 1',
                advanced: true,
                nextRoundLabel: 'Final Table',
              ),
            ),
          ),
        ),
      );

      expect(find.text('You advance'), findsOneWidget);
      expect(find.text('ROUND 1'), findsOneWidget);
      expect(find.text('Victory'), findsNothing);
    });

    testWidgets('losing a tournament round says Knocked out', (tester) async {
      await tester.pumpWidget(
        _host(
          StandingsScreen(
            viewerSeat: 0,
            onExit: () {},
            view: _table(
              tournament: const TournamentOutcomeView(
                roundLabel: 'Round 1',
                advanced: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Knocked out'), findsOneWidget);
    });

    testWidgets('winning the final table says Champion', (tester) async {
      await tester.pumpWidget(
        _host(
          StandingsScreen(
            viewerSeat: 3,
            onExit: () {},
            view: _table(
              youWon: true,
              tournament: const TournamentOutcomeView(
                roundLabel: 'Final Table',
                advanced: false,
                isChampion: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Champion'), findsOneWidget);
    });
  });

  group('actions', () {
    testWidgets('offline offers Play Again', (tester) async {
      var replayed = false;
      await tester.pumpWidget(
        _host(
          StandingsScreen(
            view: _table(),
            viewerSeat: 0,
            onExit: () {},
            onPlayAgain: () => replayed = true,
          ),
        ),
      );

      expect(find.text('Play Again'), findsOneWidget);
      await tester.tap(find.text('Play Again'));
      expect(replayed, isTrue);
    });

    testWidgets('online offers only Leave', (tester) async {
      var left = false;
      await tester.pumpWidget(
        _host(
          StandingsScreen(
            view: _table(),
            viewerSeat: 0,
            onExit: () => left = true,
          ),
        ),
      );

      expect(find.text('Play Again'), findsNothing);
      await tester.tap(find.text('Leave'));
      expect(left, isTrue);
    });

    testWidgets('advancing replaces Play Again with the next round', (
      tester,
    ) async {
      var continued = false;
      await tester.pumpWidget(
        _host(
          StandingsScreen(
            viewerSeat: 3,
            onExit: () {},
            onPlayAgain: () {},
            onContinue: () => continued = true,
            view: _table(
              youWon: true,
              tournament: const TournamentOutcomeView(
                roundLabel: 'Round 1',
                advanced: true,
                nextRoundLabel: 'Final Table',
              ),
            ),
          ),
        ),
      );

      // There is no rematch in a tournament — advancing wins the slot.
      expect(find.text('Play Again'), findsNothing);
      expect(find.text('Continue to Final Table'), findsOneWidget);

      await tester.tap(find.text('Continue to Final Table'));
      expect(continued, isTrue);
    });

    testWidgets('a knocked-out player gets no continue button', (tester) async {
      await tester.pumpWidget(
        _host(
          StandingsScreen(
            viewerSeat: 0,
            onExit: () {},
            view: _table(
              tournament: const TournamentOutcomeView(
                roundLabel: 'Round 1',
                advanced: false,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Continue'), findsNothing);
      expect(find.text('Leave'), findsOneWidget);
    });
  });

  testWidgets('a short-handed heads-up table renders', (tester) async {
    await tester.pumpWidget(
      _host(
        StandingsScreen(
          viewerSeat: 1,
          onExit: () {},
          view: const GameOverView(
            youWon: false,
            winnerSeat: 0,
            detail: 'Rowan wins Sudden Death on the chip count.',
            standings: [
              StandingView(0, 210, name: 'Rowan', rank: 1),
              StandingView(1, 190, name: 'Jeya', rank: 2),
            ],
          ),
        ),
      ),
    );

    // Both survived to Sudden Death, so neither shows an elimination hand.
    expect(find.text('still standing'), findsNWidgets(2));
    expect(find.text('You'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

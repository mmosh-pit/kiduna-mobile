import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/games/medieval_poker/session/game_session.dart';
import 'package:kiduna/games/medieval_poker/session/standings_screen.dart';

/// Goldens for the standings surface.
///
/// The real brand fonts are loaded first — without this the test renderer
/// substitutes Ahem and every golden is a field of boxes, which regresses on
/// layout but tells you nothing about whether the screen reads well.
Future<void> _loadFonts() async {
  const families = <String, List<String>>{
    'GoudyHeavyface': ['assets/fonts/goudy-heavyface.ttf'],
    'Avenir': ['assets/fonts/avenir-book.ttf', 'assets/fonts/avenir-heavy.ttf'],
    'IBMPlexSans': [
      'assets/fonts/IBMPlexSans-Regular.ttf',
      'assets/fonts/IBMPlexSans-Medium.ttf',
    ],
  };

  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      final file = File(path);
      if (!file.existsSync()) continue;
      loader.addFont(
        file.readAsBytes().then((b) => ByteData.view(Uint8List.fromList(b).buffer)),
      );
    }
    await loader.load();
  }
}

GameOverView _table({
  bool youWon = false,
  TournamentOutcomeView? tournament,
  String detail = 'Rowan wins Sudden Death on the chip count.',
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
  debugShowCheckedModeBanner: false,
  home: Scaffold(backgroundColor: const Color(0xFF120C06), body: child),
);

void main() {
  setUpAll(_loadFonts);

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget child, {
    Size size = const Size(430, 780),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(child));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(StandingsScreen),
      matchesGoldenFile('goldens/standings_$name.png'),
    );
  }

  testWidgets('golden: casual defeat', (tester) async {
    await shoot(
      tester,
      'casual_defeat',
      StandingsScreen(view: _table(), viewerSeat: 0, onExit: () {}),
    );
  });

  testWidgets('golden: casual victory with play again', (tester) async {
    await shoot(
      tester,
      'casual_victory',
      StandingsScreen(
        view: _table(youWon: true, detail: 'Victory! You have taken the table.'),
        viewerSeat: 3,
        onExit: () {},
        onPlayAgain: () {},
      ),
    );
  });

  testWidgets('golden: tournament advance', (tester) async {
    await shoot(
      tester,
      'tournament_advance',
      StandingsScreen(
        viewerSeat: 3,
        onExit: () {},
        onContinue: () {},
        view: _table(
          youWon: true,
          detail: 'You take the table and move on.',
          tournament: const TournamentOutcomeView(
            roundLabel: 'Round 1',
            advanced: true,
            nextRoundLabel: 'Final Table',
          ),
        ),
      ),
    );
  });

  testWidgets('golden: knocked out', (tester) async {
    await shoot(
      tester,
      'tournament_knocked_out',
      StandingsScreen(
        viewerSeat: 0,
        onExit: () {},
        view: _table(
          detail: 'Out on hand 17. Rowan carries the table forward.',
          tournament: const TournamentOutcomeView(
            roundLabel: 'Round 1',
            advanced: false,
          ),
        ),
      ),
    );
  });

  testWidgets('golden: champion', (tester) async {
    await shoot(
      tester,
      'tournament_champion',
      StandingsScreen(
        viewerSeat: 3,
        onExit: () {},
        view: _table(
          youWon: true,
          detail: 'You have taken every table.',
          tournament: const TournamentOutcomeView(
            roundLabel: 'Final Table',
            advanced: false,
            isChampion: true,
          ),
        ),
      ),
    );
  });

  testWidgets('golden: short-handed heads-up', (tester) async {
    await shoot(
      tester,
      'heads_up',
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
      size: const Size(430, 620),
    );
  });
}

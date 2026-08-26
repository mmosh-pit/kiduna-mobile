import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/config/theme.dart';
import 'package:kiduna/games/medieval_poker/tournament/tournament_models.dart';
import 'package:kiduna/games/medieval_poker/tournament/widgets/bracket_view.dart';
import 'package:kiduna/l10n/app_localizations.dart';

BracketMatch _match({
  required int round,
  int index = 0,
  String status = 'active',
  String? winner,
  List<Map<String, dynamic>> players = const [],
}) => BracketMatch.fromJson({
  'id': 'm$round-$index',
  'round': round,
  'matchIndex': index,
  'roomCode': 'ROOM$index',
  'status': status,
  'winnerUserId': winner,
  'players': players,
});

const _alice = {'seat': 0, 'userId': 'u1', 'isAi': false, 'username': 'alice'};
const _bob = {'seat': 1, 'userId': 'u2', 'isAi': false, 'username': 'bob'};
const _bot = {'seat': 2, 'userId': null, 'isAi': true};

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(1000, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(width: size.width, height: size.height, child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders nothing when there is no bracket yet', (tester) async {
    await _pump(tester, const BracketView(rounds: [], viewerUserId: 'u1'));
    expect(find.byType(SizedBox), findsWidgets);
    expect(find.text('alice'), findsNothing);
  });

  testWidgets('shows every player in every heat', (tester) async {
    await _pump(
      tester,
      BracketView(
        viewerUserId: 'u1',
        rounds: [
          BracketRound(
            round: 1,
            matches: [
              _match(round: 1, players: const [_alice, _bob, _bot]),
            ],
          ),
        ],
      ),
    );

    expect(find.text('alice'), findsOneWidget);
    expect(find.text('bob'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
  });

  testWidgets('does not call round 1 the final while later rounds are pending', (
    tester,
  ) async {
    // Regression: only the rounds that already exist are passed in, because
    // the next one is not created until the current one finishes. Round 1 of a
    // two-round bracket was being labelled "Final" for being last so far.
    await _pump(
      tester,
      BracketView(
        viewerUserId: 'u1',
        totalRounds: 2,
        rounds: [
          BracketRound(
            round: 1,
            matches: [
              _match(round: 1, players: const [_alice, _bob]),
            ],
          ),
        ],
      ),
    );

    expect(find.text('Round 1'), findsOneWidget);
    expect(find.text('Final'), findsNothing);
  });

  testWidgets('labels the true final once it exists', (tester) async {
    await _pump(
      tester,
      BracketView(
        viewerUserId: 'u1',
        totalRounds: 2,
        rounds: [
          BracketRound(
            round: 1,
            matches: [
              _match(round: 1, players: const [_alice]),
            ],
          ),
          BracketRound(
            round: 2,
            matches: [
              _match(round: 2, players: const [_alice, _bob]),
            ],
          ),
        ],
      ),
    );

    expect(find.text('Round 1'), findsOneWidget);
    expect(find.text('Final'), findsOneWidget);
  });

  testWidgets('labels the last round as the final', (tester) async {
    await _pump(
      tester,
      BracketView(
        viewerUserId: 'u1',
        rounds: [
          BracketRound(
            round: 1,
            matches: [
              _match(round: 1, players: const [_alice]),
            ],
          ),
          BracketRound(
            round: 2,
            matches: [
              _match(round: 2, players: const [_alice, _bob]),
            ],
          ),
        ],
      ),
    );

    expect(find.text('Round 1'), findsOneWidget);
    expect(find.text('Final'), findsOneWidget);
    expect(find.text('Round 2'), findsNothing);
  });

  testWidgets('marks the viewer\'s own heat', (tester) async {
    await _pump(
      tester,
      BracketView(
        viewerUserId: 'u1',
        rounds: [
          BracketRound(
            round: 1,
            matches: [
              _match(round: 1, players: const [_alice]),
              _match(round: 1, index: 1, players: const [_bob]),
            ],
          ),
        ],
      ),
    );

    // Only the heat containing the viewer is flagged.
    expect(find.text('Your heat'), findsOneWidget);
  });

  testWidgets('offers an enter button only for the viewer\'s live heat', (
    tester,
  ) async {
    BracketMatch? entered;
    await _pump(
      tester,
      BracketView(
        viewerUserId: 'u1',
        onEnterMatch: (m) => entered = m,
        rounds: [
          BracketRound(
            round: 1,
            matches: [
              _match(round: 1, players: const [_alice]),
              _match(round: 1, index: 1, players: const [_bob]),
            ],
          ),
        ],
      ),
    );

    expect(find.text('Enter your table'), findsOneWidget);
    await tester.tap(find.text('Enter your table'));
    expect(entered, isNotNull);
    expect(entered!.matchIndex, 0);
  });

  testWidgets('does not offer to enter a heat that already finished', (
    tester,
  ) async {
    await _pump(
      tester,
      BracketView(
        viewerUserId: 'u1',
        onEnterMatch: (_) {},
        rounds: [
          BracketRound(
            round: 1,
            matches: [
              _match(
                round: 1,
                status: 'finished',
                winner: 'u1',
                players: const [_alice, _bob],
              ),
            ],
          ),
        ],
      ),
    );

    expect(find.text('Enter your table'), findsNothing);
    expect(find.text('Finished'), findsOneWidget);
  });

  testWidgets('stacks the rounds when the space is narrow', (tester) async {
    // The panel this lives in is resizable, so the layout must reflow on the
    // width it actually has rather than the size of the window.
    await _pump(
      tester,
      BracketView(
        viewerUserId: 'u1',
        rounds: [
          BracketRound(
            round: 1,
            matches: [
              _match(round: 1, players: const [_alice]),
            ],
          ),
          BracketRound(
            round: 2,
            matches: [
              _match(round: 2, players: const [_bob]),
            ],
          ),
        ],
      ),
      size: const Size(400, 900),
    );

    expect(
      find.byType(SingleChildScrollView),
      findsNothing,
      reason: 'narrow stacks vertically instead of scrolling sideways',
    );
    expect(find.text('alice'), findsOneWidget);
    expect(find.text('bob'), findsOneWidget);
  });

  testWidgets('lays the rounds side by side when there is room', (
    tester,
  ) async {
    await _pump(
      tester,
      BracketView(
        viewerUserId: 'u1',
        rounds: [
          BracketRound(
            round: 1,
            matches: [
              _match(round: 1, players: const [_alice]),
            ],
          ),
          BracketRound(
            round: 2,
            matches: [
              _match(round: 2, players: const [_bob]),
            ],
          ),
        ],
      ),
      size: const Size(1200, 800),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('Round 1'), findsOneWidget);
    expect(find.text('Final'), findsOneWidget);
  });
}

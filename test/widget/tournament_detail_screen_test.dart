import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/config/theme.dart';
import 'package:kiduna/games/medieval_poker/tournament/medieval_poker_tournament_detail_screen.dart';
import 'package:kiduna/games/medieval_poker/tournament/tournament_client.dart';
import 'package:kiduna/l10n/app_localizations.dart';

import '../mocks/fake_dio.dart';

Map<String, dynamic> _detail({
  String status = 'registering',
  int registered = 2,
  int size = 4,
  bool isRegistered = false,
  bool isCreator = false,
  int currentRound = 0,
  List<Map<String, dynamic>> entrants = const [],
  List<Map<String, dynamic>> bracket = const [],
  Map<String, dynamic>? myMatch,
}) => {
  'tournament': {
    'id': 't1',
    'name': 'Founders Cup',
    'status': status,
    'size': size,
    'registered': registered,
    'currentRound': currentRound,
    'totalRounds': 2,
    'isRegistered': isRegistered,
    'isCreator': isCreator,
  },
  'entrants': entrants,
  'bracket': bracket,
  'myMatch': myMatch,
};

Future<FakeDio> _pump(
  WidgetTester tester,
  FakeReply Function(dynamic options) handler, {
  String? viewerUserId = 'u1',
  Size size = const Size(900, 1000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final fake = FakeDio(handler);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MedievalPokerTournamentDetailScreen(
          tournamentId: 't1',
          onBack: () {},
          viewerUserId: viewerUserId,
          client: TournamentClient(dio: fake.dio),
          // Polling off — a periodic timer would outlive the test.
          pollInterval: Duration.zero,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fake;
}

void main() {
  testWidgets('offers registration while the field is open', (tester) async {
    await _pump(tester, (_) => FakeReply(envelope(_detail())));

    expect(find.text('Founders Cup'), findsOneWidget);
    expect(find.text('2 of 4 players'), findsWidgets);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Withdraw'), findsNothing);
  });

  testWidgets('offers withdrawal once registered', (tester) async {
    await _pump(
      tester,
      (_) => FakeReply(envelope(_detail(isRegistered: true))),
    );

    expect(find.text('Withdraw'), findsOneWidget);
    expect(find.text('Register'), findsNothing);
  });

  testWidgets('registering posts and repaints from the response', (
    tester,
  ) async {
    var registered = false;
    final fake = await _pump(tester, (options) {
      if (options.method == 'POST') {
        registered = true;
        return FakeReply(envelope(_detail(isRegistered: true, registered: 3)));
      }
      return FakeReply(envelope(_detail()));
    });

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    expect(registered, isTrue);
    expect(fake.requests.last.path, '/tournaments/t1/register');
    expect(find.text('Withdraw'), findsOneWidget);
  });

  testWidgets('shows a start button to the creator', (tester) async {
    await _pump(
      tester,
      (_) => FakeReply(envelope(_detail(isCreator: true, registered: 2))),
    );
    expect(find.text('Start now'), findsOneWidget);
  });

  testWidgets('hides the start button from everyone else', (tester) async {
    await _pump(tester, (_) => FakeReply(envelope(_detail(registered: 2))));
    expect(find.text('Start now'), findsNothing);
  });

  testWidgets('hides the start button until there are two entrants', (
    tester,
  ) async {
    await _pump(
      tester,
      (_) => FakeReply(envelope(_detail(isCreator: true, registered: 1))),
    );
    expect(find.text('Start now'), findsNothing);
  });

  testWidgets('shows the bracket and an enter button for a live heat', (
    tester,
  ) async {
    await _pump(
      tester,
      (_) => FakeReply(
        envelope(
          _detail(
            status: 'running',
            currentRound: 1,
            bracket: const [
              {
                'round': 1,
                'matches': [
                  {
                    'id': 'm1',
                    'round': 1,
                    'matchIndex': 0,
                    'roomCode': 'ROOM1',
                    'status': 'active',
                    'players': [
                      {
                        'seat': 0,
                        'userId': 'u1',
                        'isAi': false,
                        'username': 'me',
                      },
                      {
                        'seat': 1,
                        'userId': 'u2',
                        'isAi': false,
                        'username': 'rival',
                      },
                    ],
                  },
                ],
              },
            ],
            myMatch: const {
              'matchId': 'm1',
              'round': 1,
              'roomCode': 'ROOM1',
              'seat': 0,
              'seatCount': 2,
              'humans': 2,
              'gameToken': 'tok',
              'wsUrl': 'wss://backend.test/game',
            },
          ),
        ),
      ),
    );

    expect(find.text('Bracket'), findsOneWidget);
    expect(find.text('me'), findsOneWidget);
    expect(find.text('rival'), findsOneWidget);
    // One in the action area, one on the bracket card.
    expect(find.text('Enter your table'), findsNWidgets(2));
  });

  testWidgets('tells a waiting player the other heats are still going', (
    tester,
  ) async {
    await _pump(
      tester,
      (_) => FakeReply(
        envelope(
          _detail(
            status: 'running',
            currentRound: 1,
            entrants: const [
              {'userId': 'u1', 'status': 'active'},
            ],
          ),
        ),
      ),
    );

    expect(find.text('Waiting for the other heats to finish'), findsOneWidget);
    expect(find.text('Enter your table'), findsNothing);
  });

  testWidgets('tells an eliminated player where they went out', (tester) async {
    await _pump(
      tester,
      (_) => FakeReply(
        envelope(
          _detail(
            status: 'running',
            currentRound: 2,
            entrants: const [
              {'userId': 'u1', 'status': 'eliminated', 'eliminatedRound': 1},
            ],
          ),
        ),
      ),
    );

    expect(find.text('You were knocked out in round 1'), findsOneWidget);
    expect(find.text('Eliminated'), findsOneWidget);
  });

  testWidgets('congratulates the champion', (tester) async {
    await _pump(
      tester,
      (_) => FakeReply(
        envelope(
          _detail(
            status: 'finished',
            entrants: const [
              {'userId': 'u1', 'status': 'champion', 'finalRank': 1},
              {'userId': 'u2', 'status': 'eliminated', 'finalRank': 2},
            ],
          ),
        ),
      ),
    );

    expect(find.text('You are the champion'), findsOneWidget);
    expect(find.text('Champion'), findsOneWidget);
  });

  testWidgets('lists entrants by finishing position once places are awarded', (
    tester,
  ) async {
    // Regression: entrants came back in registration order, so a finished
    // tournament showed places out of sequence (1, 2, 4, 5, 3).
    await _pump(
      tester,
      (_) => FakeReply(
        envelope(
          _detail(
            status: 'finished',
            entrants: const [
              {'userId': 'u1', 'status': 'champion', 'finalRank': 1},
              {'userId': 'u4', 'status': 'eliminated', 'finalRank': 4},
              {'userId': 'u2', 'status': 'eliminated', 'finalRank': 2},
              {'userId': 'u3', 'status': 'eliminated', 'finalRank': 3},
            ],
          ),
        ),
      ),
    );

    final ranks = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .where((d) => RegExp(r'^[1-4]$').hasMatch(d))
        .toList();
    expect(ranks, ['1', '2', '3', '4'], reason: 'ascending finishing order');
  });

  testWidgets('keeps seed order while nobody has a place yet', (tester) async {
    await _pump(
      tester,
      (_) => FakeReply(
        envelope(
          _detail(
            entrants: const [
              {'userId': 'u1', 'status': 'registered'},
              {'userId': 'u2', 'status': 'registered'},
            ],
          ),
        ),
      ),
    );
    // No ranks to sort by, so the list is simply left alone.
    expect(find.text('·'), findsNWidgets(2));
  });

  testWidgets('shows an error state when the tournament cannot be loaded', (
    tester,
  ) async {
    await _pump(tester, (_) => const FakeReply(null, statusCode: 500));

    expect(find.text('Could not load tournaments'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/config/theme.dart';
import 'package:kiduna/games/medieval_poker/medieval_poker_leaderboard_screen.dart';
import 'package:kiduna/games/medieval_poker/session/lobby_client.dart';
import 'package:kiduna/l10n/app_localizations.dart';

import '../mocks/fake_dio.dart';

Map<String, dynamic> _entry(
  String userId, {
  required int rank,
  required int rating,
  String tier = 'knight',
  int games = 10,
  int wins = 5,
  String? username,
}) => {
  'userId': userId,
  'rank': rank,
  'rating': rating,
  'peakRating': rating,
  'games': games,
  'wins': wins,
  'tier': tier,
  'username': username ?? userId,
};

Map<String, dynamic> _ratingBody({
  int rating = 1200,
  int? peak,
  int games = 0,
  int? rank,
  String tier = 'knight',
  List<Map<String, dynamic>> recent = const [],
}) => {
  'seasonId': 'all',
  'rating': {
    'rating': rating,
    // Deliberately distinct from `rating` so a test asserting on one
    // figure cannot accidentally match the other.
    'peakRating': peak ?? rating + 30,
    'games': games,
    'wins': 0,
    'rank': rank,
    'tier': tier,
  },
  'recent': recent,
};

/// Routes the two calls the screen makes: the board, then the caller's rating.
FakeReply Function(dynamic) _handler({
  List<Map<String, dynamic>> board = const [],
  Map<String, dynamic>? me,
  Map<String, dynamic>? rating,
  int? failStatus,
}) => (options) {
  if (failStatus != null) return FakeReply(null, statusCode: failStatus);
  if ((options.path as String).contains('/games/rating')) {
    return FakeReply(envelope(rating ?? _ratingBody()));
  }
  return FakeReply(envelope({'leaderboard': board, 'me': me}));
};

Future<FakeDio> _pump(
  WidgetTester tester,
  FakeReply Function(dynamic) handler, {
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
        body: MedievalPokerLeaderboardScreen(
          viewerUserId: viewerUserId,
          client: LobbyClient(dio: fake.dio),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fake;
}

void main() {
  testWidgets('ranks players by rating with their tier', (tester) async {
    await _pump(
      tester,
      _handler(
        board: [
          _entry('u2', rank: 1, rating: 1650, tier: 'duke', username: 'alice'),
          _entry('u1', rank: 2, rating: 1240, tier: 'knight', username: 'bob'),
        ],
        rating: _ratingBody(rating: 1240, games: 10, rank: 2),
      ),
    );

    expect(find.text('alice'), findsOneWidget);
    expect(find.text('bob'), findsOneWidget);
    expect(find.text('1650'), findsOneWidget);
    expect(find.text('Duke'), findsOneWidget);
    // Knight appears on both the row badge and the viewer's rating card.
    expect(find.text('Knight'), findsWidgets);
  });

  testWidgets('shows the viewer\'s own rating card', (tester) async {
    await _pump(
      tester,
      _handler(
        rating: _ratingBody(
          rating: 1450,
          peak: 1520,
          games: 12,
          rank: 4,
          tier: 'baron',
        ),
      ),
    );

    expect(find.text('1450'), findsOneWidget);
    expect(find.text('#4'), findsOneWidget);
    expect(find.text('Baron'), findsOneWidget);
  });

  testWidgets('says unranked before any rated game', (tester) async {
    await _pump(tester, _handler(rating: _ratingBody(games: 0, rank: null)));

    expect(find.text('Unranked'), findsOneWidget);
    expect(find.text('No ranked games yet'), findsOneWidget);
  });

  testWidgets('pins the viewer\'s row when they fall off the page', (
    tester,
  ) async {
    await _pump(
      tester,
      _handler(
        board: [_entry('u2', rank: 1, rating: 1900, username: 'champ')],
        me: _entry('u1', rank: 57, rating: 1010, username: 'me'),
        rating: _ratingBody(rating: 1010, games: 8, rank: 57),
      ),
    );

    expect(find.text('champ'), findsOneWidget);
    expect(find.text('Your rank'), findsOneWidget);
    expect(find.text('me'), findsOneWidget);
    expect(find.text('57'), findsOneWidget);
  });

  testWidgets('does not repeat the viewer when they are already on the page', (
    tester,
  ) async {
    await _pump(
      tester,
      _handler(
        board: [_entry('u1', rank: 1, rating: 1500, username: 'me')],
        me: _entry('u1', rank: 1, rating: 1500, username: 'me'),
        rating: _ratingBody(rating: 1500, games: 9, rank: 1),
      ),
    );

    expect(find.text('me'), findsOneWidget);
    expect(find.text('Your rank'), findsNothing);
  });

  testWidgets('shows an error state rather than an empty board on failure', (
    tester,
  ) async {
    // The old screen swallowed the failure and rendered "no games recorded
    // yet", which made a missing backend look like an untouched leaderboard.
    await _pump(tester, _handler(failStatus: 404));

    expect(find.text('Could not load the leaderboard'), findsOneWidget);
    expect(find.text('No ranked games yet'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('switches to the wins board and refetches', (tester) async {
    final fake = await _pump(tester, _handler());

    expect(
      fake.requests
          .where((r) => r.path.contains('leaderboard'))
          .last
          .queryParameters['board'],
      'rating',
    );

    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<LeaderboardBoard>),
        matching: find.text('Wins'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      fake.requests
          .where((r) => r.path.contains('leaderboard'))
          .last
          .queryParameters['board'],
      'wins',
    );
  });

  testWidgets('switches to the current season and refetches', (tester) async {
    final fake = await _pump(tester, _handler());

    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<LeaderboardSeason>),
        matching: find.text('Season'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      fake.requests
          .where((r) => r.path.contains('leaderboard'))
          .last
          .queryParameters['season'],
      'current',
    );
  });

  testWidgets('shows recent rating movement', (tester) async {
    await _pump(
      tester,
      _handler(
        rating: _ratingBody(
          rating: 1260,
          games: 3,
          rank: 6,
          recent: const [
            {'delta': 14},
            {'delta': -9},
          ],
        ),
      ),
    );

    expect(find.text('+14'), findsOneWidget);
    expect(find.text('-9'), findsOneWidget);
  });
}

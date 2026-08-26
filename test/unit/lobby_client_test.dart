import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/games/medieval_poker/session/lobby_client.dart';

import '../mocks/fake_dio.dart';

void main() {
  group('LeaderboardEntry', () {
    test('parses a rating row with its tier and rank', () {
      final e = LeaderboardEntry.fromJson(const {
        'userId': 'u1',
        'rank': 3,
        'rating': 1450,
        'peakRating': 1500,
        'games': 20,
        'wins': 12,
        'tier': 'baron',
        'username': 'rogue',
      });

      expect(e.label, 'rogue');
      expect(e.rank, 3);
      expect(e.rating, 1450);
      expect(e.tier, RatingTier.baron);
      expect(e.winRate, 60);
    });

    test('does not divide by zero for a player with no games', () {
      final e = LeaderboardEntry.fromJson(const {'userId': 'u1'});
      expect(e.winRate, 0);
    });

    test('falls back to the starting rating and lowest tier', () {
      final e = LeaderboardEntry.fromJson(const {'userId': 'u1'});
      expect(e.rating, 1200);
      expect(e.tier, RatingTier.peasant, reason: 'unknown tier id');
    });
  });

  group('ratingTierOf', () {
    test('maps every tier the backend can send', () {
      expect(ratingTierOf('peasant'), RatingTier.peasant);
      expect(ratingTierOf('squire'), RatingTier.squire);
      expect(ratingTierOf('knight'), RatingTier.knight);
      expect(ratingTierOf('baron'), RatingTier.baron);
      expect(ratingTierOf('duke'), RatingTier.duke);
      expect(ratingTierOf('royal'), RatingTier.royal);
    });

    test('falls back rather than throwing on an unknown tier', () {
      expect(ratingTierOf('archduke'), RatingTier.peasant);
      expect(ratingTierOf(null), RatingTier.peasant);
    });
  });

  group('PlayerRating', () {
    test('parses the rating card with recent movement', () {
      final r = PlayerRating.fromJson(
        const {
          'rating': 1320,
          'peakRating': 1400,
          'games': 10,
          'wins': 4,
          'rank': 7,
          'tier': 'knight',
        },
        const [
          {'delta': 12},
          {'delta': -8},
        ],
      );

      expect(r.rating, 1320);
      expect(r.rank, 7);
      expect(r.isRanked, isTrue);
      expect(r.winRate, 40);
      expect(r.recentDeltas, [12, -8]);
    });

    test('is unranked when the player has no rated games', () {
      final r = PlayerRating.fromJson(const {
        'rating': 1200,
        'games': 0,
        'rank': null,
      }, const []);
      expect(r.isRanked, isFalse);
    });
  });

  group('LobbyClient leaderboard', () {
    test('requests the board and season it was asked for', () async {
      final fake = FakeDio(
        (_) => FakeReply(envelope({'leaderboard': [], 'me': null})),
      );

      await LobbyClient(dio: fake.dio).leaderboard(
        board: LeaderboardBoard.wins,
        season: LeaderboardSeason.current,
        limit: 5,
      );

      final q = fake.requests.single.queryParameters;
      expect(fake.requests.single.path, '/games/leaderboard');
      expect(q['board'], 'wins');
      expect(q['season'], 'current');
      expect(q['limit'], 5);
    });

    test('parses entries and the caller\'s own pinned row', () async {
      final fake = FakeDio(
        (_) => FakeReply(
          envelope({
            'leaderboard': [
              {
                'userId': 'u1',
                'rank': 1,
                'rating': 1600,
                'games': 9,
                'wins': 7,
              },
            ],
            'me': {
              'userId': 'u9',
              'rank': 42,
              'rating': 1100,
              'games': 3,
              'wins': 0,
            },
          }),
        ),
      );

      final page = await LobbyClient(dio: fake.dio).leaderboard();

      expect(page.entries, hasLength(1));
      expect(page.entries.single.rank, 1);
      expect(page.me!.userId, 'u9');
      expect(page.me!.rank, 42, reason: 'shown even from outside the page');
      expect(page.isEmpty, isFalse);
    });

    test('reports an empty board without a "me" row', () async {
      final fake = FakeDio(
        (_) => FakeReply(envelope({'leaderboard': [], 'me': null})),
      );
      final page = await LobbyClient(dio: fake.dio).leaderboard();
      expect(page.isEmpty, isTrue);
      expect(page.me, isNull);
    });

    test('fetches the caller\'s rating', () async {
      final fake = FakeDio(
        (_) => FakeReply(
          envelope({
            'seasonId': 'all',
            'rating': {
              'rating': 1250,
              'games': 4,
              'wins': 2,
              'rank': 5,
              'tier': 'knight',
            },
            'recent': [
              {'delta': 5},
            ],
          }),
        ),
      );

      final r = await LobbyClient(dio: fake.dio).myRating();

      expect(r.rating, 1250);
      expect(r.tier, RatingTier.knight);
      expect(r.recentDeltas, [5]);
      expect(fake.requests.single.path, '/games/rating');
    });

    test('flags a bare 404 as a missing endpoint', () async {
      // Distinguishes "the backend does not serve this" from "no games yet",
      // which previously both rendered as an empty leaderboard.
      final fake = FakeDio((_) => const FakeReply(null, statusCode: 404));

      await expectLater(
        LobbyClient(dio: fake.dio).leaderboard(),
        throwsA(
          isA<LobbyException>().having(
            (e) => e.isMissingEndpoint,
            'isMissingEndpoint',
            isTrue,
          ),
        ),
      );
    });

    test('surfaces a server error message verbatim', () async {
      final fake = FakeDio(
        (_) => const FakeReply({'error': 'room-not-found'}, statusCode: 404),
      );

      await expectLater(
        LobbyClient(dio: fake.dio).getRoom('ZZZZZ'),
        throwsA(
          isA<LobbyException>()
              .having((e) => e.message, 'message', 'room-not-found')
              .having((e) => e.isMissingEndpoint, 'isMissingEndpoint', isFalse),
        ),
      );
    });
  });
}

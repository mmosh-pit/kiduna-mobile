import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/games/medieval_poker/tournament/tournament_client.dart';
import 'package:kiduna/games/medieval_poker/tournament/tournament_models.dart';

import '../mocks/fake_dio.dart';

Map<String, dynamic> _tournament({
  String id = 't1',
  String status = 'registering',
  int size = 4,
  int registered = 1,
}) => {
  'id': id,
  'name': 'Founders Cup',
  'status': status,
  'size': size,
  'registered': registered,
  'currentRound': 0,
  'totalRounds': 1,
  'isRegistered': false,
  'isCreator': true,
};

Map<String, dynamic> _detail({String status = 'registering'}) => {
  'tournament': _tournament(status: status),
  'entrants': const [
    {'userId': 'u1', 'status': 'registered'},
  ],
  'bracket': const [],
  'myMatch': null,
};

void main() {
  group('TournamentClient', () {
    test('lists tournaments and passes the status filter through', () async {
      final fake = FakeDio(
        (_) => FakeReply(
          envelope({
            'tournaments': [_tournament(), _tournament(id: 't2')],
          }),
        ),
      );
      final client = TournamentClient(dio: fake.dio);

      final rows = await client.list(status: 'registering');

      expect(rows, hasLength(2));
      expect(rows.first.name, 'Founders Cup');
      expect(fake.requests.single.path, '/tournaments');
      expect(fake.requests.single.queryParameters['status'], 'registering');
    });

    test('omits absent query parameters entirely', () async {
      final fake = FakeDio((_) => FakeReply(envelope({'tournaments': []})));
      await TournamentClient(dio: fake.dio).list();

      expect(
        fake.requests.single.queryParameters.containsKey('status'),
        isFalse,
      );
      expect(
        fake.requests.single.queryParameters.containsKey('limit'),
        isFalse,
      );
    });

    test('creates a tournament with its name and size', () async {
      final fake = FakeDio((_) => FakeReply(envelope(_detail())));
      final detail = await TournamentClient(dio: fake.dio)
          .create(name: 'Cup', size: 8);

      expect(detail.tournament.id, 't1');
      final req = fake.requests.single;
      expect(req.method, 'POST');
      expect(req.path, '/tournaments');
      expect((req.data as Map)['name'], 'Cup');
      expect((req.data as Map)['size'], 8);
    });

    test('registers and withdraws on the right verbs', () async {
      final fake = FakeDio((_) => FakeReply(envelope(_detail())));
      final client = TournamentClient(dio: fake.dio);

      await client.register('t1');
      await client.withdraw('t1');

      expect(fake.requests[0].method, 'POST');
      expect(fake.requests[0].path, '/tournaments/t1/register');
      expect(fake.requests[1].method, 'DELETE');
      expect(fake.requests[1].path, '/tournaments/t1/register');
    });

    test('starts a tournament', () async {
      final fake = FakeDio(
        (_) => FakeReply(envelope(_detail(status: 'running'))),
      );
      final detail = await TournamentClient(dio: fake.dio).start('t1');

      expect(detail.tournament.status, TournamentStatus.running);
      expect(fake.requests.single.path, '/tournaments/t1/start');
    });

    test('returns null when there is no table waiting', () async {
      final fake = FakeDio((_) => FakeReply(envelope({'myMatch': null})));
      expect(await TournamentClient(dio: fake.dio).myMatch('t1'), isNull);
    });

    test('parses a live match into join details', () async {
      final fake = FakeDio(
        (_) => FakeReply(
          envelope({
            'myMatch': {
              'matchId': 'm1',
              'round': 1,
              'roomCode': 'K7QMX',
              'seat': 2,
              'seatCount': 4,
              'humans': 3,
              'gameToken': 'tok',
              'wsUrl': 'wss://backend.test/game',
            },
          }),
        ),
      );

      final m = await TournamentClient(dio: fake.dio).myMatch('t1');

      expect(m!.roomCode, 'K7QMX');
      expect(m.seat, 2);
      expect(m.humans, 3);
    });

    test('surfaces the server error message', () async {
      final fake = FakeDio(
        (_) => const FakeReply({'error': 'tournament-full'}, statusCode: 400),
      );

      await expectLater(
        TournamentClient(dio: fake.dio).register('t1'),
        throwsA(
          isA<TournamentException>()
              .having((e) => e.message, 'message', 'tournament-full')
              .having((e) => e.isMissingEndpoint, 'isMissingEndpoint', isFalse),
        ),
      );
    });

    test('flags a bare 404 as a missing endpoint, not an empty result', () async {
      // An un-deployed backend answers 404 with no error body. Treating that as
      // "no tournaments" would hide a deployment problem behind an empty list.
      final fake = FakeDio((_) => const FakeReply(null, statusCode: 404));

      await expectLater(
        TournamentClient(dio: fake.dio).list(),
        throwsA(
          isA<TournamentException>().having(
            (e) => e.isMissingEndpoint,
            'isMissingEndpoint',
            isTrue,
          ),
        ),
      );
    });

    test('rejects a response that is not in the data envelope', () async {
      final fake = FakeDio((_) => const FakeReply({'tournaments': []}));

      await expectLater(
        TournamentClient(dio: fake.dio).list(),
        throwsA(isA<TournamentException>()),
      );
    });
  });
}

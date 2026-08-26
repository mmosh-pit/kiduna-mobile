import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/games/medieval_poker/tournament/tournament_models.dart';

void main() {
  group('TournamentSummary', () {
    test('parses a tournament open for registration', () {
      final t = TournamentSummary.fromJson(const {
        'id': 't1',
        'name': 'Founders Cup',
        'status': 'registering',
        'size': 8,
        'registered': 3,
        'currentRound': 0,
        'totalRounds': 2,
        'isRegistered': true,
        'isCreator': true,
      });

      expect(t.name, 'Founders Cup');
      expect(t.status, TournamentStatus.registering);
      expect(t.isOpen, isTrue);
      expect(t.isFull, isFalse);
      expect(t.isRegistered, isTrue);
    });

    test('knows when the field is full', () {
      final t = TournamentSummary.fromJson(const {
        'id': 't1',
        'name': 'Cup',
        'status': 'registering',
        'size': 4,
        'registered': 4,
      });
      expect(t.isFull, isTrue);
    });

    test('falls back to registering for an unknown status', () {
      final t = TournamentSummary.fromJson(const {'id': 't1', 'status': 'wat'});
      expect(t.status, TournamentStatus.registering);
    });

    test('parses running and finished states', () {
      expect(
        TournamentSummary.fromJson(const {'id': 'a', 'status': 'running'})
            .isRunning,
        isTrue,
      );
      expect(
        TournamentSummary.fromJson(const {'id': 'a', 'status': 'finished'})
            .isFinished,
        isTrue,
      );
    });

    test('tolerates a response missing every optional field', () {
      final t = TournamentSummary.fromJson(const {'id': 't1'});
      expect(t.name, '');
      expect(t.registered, 0);
      expect(t.isRegistered, isFalse);
    });
  });

  group('Entrant', () {
    test('prefers the username for display', () {
      final e = Entrant.fromJson(const {
        'userId': 'u1',
        'username': 'rogue',
        'name': 'Rogue Player',
      });
      expect(e.label, 'rogue');
    });

    test('falls back to the name, then to a generic label', () {
      expect(
        Entrant.fromJson(const {'userId': 'u1', 'name': 'Named'}).label,
        'Named',
      );
      expect(Entrant.fromJson(const {'userId': 'u1'}).label, 'Player');
    });

    test('reports elimination and championship', () {
      final out = Entrant.fromJson(const {
        'userId': 'u1',
        'status': 'eliminated',
        'eliminatedRound': 1,
      });
      expect(out.isEliminated, isTrue);
      expect(out.eliminatedRound, 1);

      final champ = Entrant.fromJson(const {
        'userId': 'u2',
        'status': 'champion',
      });
      expect(champ.isChampion, isTrue);
    });
  });

  group('MatchPlayer', () {
    test('labels an AI seat as AI regardless of any name', () {
      final p = MatchPlayer.fromJson(const {
        'seat': 1,
        'isAi': true,
        'username': 'ignored',
      });
      expect(p.label, 'AI');
    });
  });

  group('BracketMatch', () {
    final match = BracketMatch.fromJson(const {
      'id': 'm1',
      'round': 1,
      'matchIndex': 0,
      'roomCode': 'K7QMX',
      'status': 'active',
      'winnerUserId': null,
      'players': [
        {'seat': 0, 'userId': 'u1', 'isAi': false, 'username': 'alice'},
        {'seat': 1, 'userId': null, 'isAi': true},
      ],
    });

    test('parses players in seat order with their status', () {
      expect(match.status, MatchStatus.active);
      expect(match.roomCode, 'K7QMX');
      expect(match.players.map((p) => p.label), ['alice', 'AI']);
    });

    test('knows whether a given player is in it', () {
      expect(match.contains('u1'), isTrue);
      expect(match.contains('u9'), isFalse);
      expect(match.contains(null), isFalse, reason: 'a signed-out viewer');
    });
  });

  group('TournamentDetail', () {
    final detail = TournamentDetail.fromJson(const {
      'tournament': {
        'id': 't1',
        'name': 'Cup',
        'status': 'running',
        'size': 8,
        'registered': 8,
        'currentRound': 2,
        'totalRounds': 2,
      },
      'entrants': [
        {'userId': 'u1', 'status': 'active'},
        {'userId': 'u2', 'status': 'eliminated', 'eliminatedRound': 1},
      ],
      'bracket': [
        {
          'round': 1,
          'matches': [
            {
              'id': 'm1',
              'round': 1,
              'status': 'finished',
              'winnerUserId': 'u1',
              'players': [
                {'seat': 0, 'userId': 'u1', 'isAi': false},
              ],
            },
          ],
        },
        {
          'round': 2,
          'matches': [
            {
              'id': 'm2',
              'round': 2,
              'status': 'active',
              'players': [
                {'seat': 0, 'userId': 'u1', 'isAi': false},
              ],
            },
          ],
        },
      ],
      'myMatch': {
        'matchId': 'm2',
        'round': 2,
        'roomCode': 'ABCDE',
        'seat': 0,
        'seatCount': 2,
        'humans': 2,
        'gameToken': 'jwt.token.here',
        'wsUrl': 'wss://backend.test/game',
      },
    });

    test('parses the bracket round by round', () {
      expect(detail.bracket.map((r) => r.round), [1, 2]);
      expect(detail.bracket[0].matches.single.winnerUserId, 'u1');
    });

    test('carries everything needed to join the live table', () {
      final m = detail.myMatch!;
      expect(m.roomCode, 'ABCDE');
      expect(m.seat, 0);
      expect(m.seatCount, 2, reason: 'a heads-up final is a real 2-seat table');
      expect(m.gameToken, isNotEmpty);
      expect(m.wsUrl, startsWith('wss://'));
    });

    test('finds the viewer among the entrants', () {
      expect(detail.entrantFor('u2')!.isEliminated, isTrue);
      expect(detail.entrantFor('nobody'), isNull);
      expect(detail.entrantFor(null), isNull);
    });

    test('handles a tournament with no bracket or match yet', () {
      final open = TournamentDetail.fromJson(const {
        'tournament': {'id': 't2', 'status': 'registering'},
      });
      expect(open.bracket, isEmpty);
      expect(open.entrants, isEmpty);
      expect(open.myMatch, isNull);
    });
  });
}

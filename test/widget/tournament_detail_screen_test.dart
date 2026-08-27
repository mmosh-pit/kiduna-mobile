import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/games/medieval_poker/tournament/tournament_detail_screen.dart';
import 'package:kiduna/games/medieval_poker/tournament/tournament_models.dart';
import 'package:kiduna/games/medieval_poker/tournament/tournament_source.dart';
import 'package:kiduna/games/medieval_poker/tournament/widgets/start_countdown.dart';

/// A source that returns exactly what a test hands it, so each screen state can
/// be pinned without driving a clock.
class _StubSource implements TournamentSource {
  TournamentDetail detailValue;
  int registerCalls = 0;
  int withdrawCalls = 0;

  _StubSource(this.detailValue);

  @override
  Future<List<TournamentSummary>> list() async => [detailValue.summary];

  @override
  Future<TournamentDetail> detail(String id) async => detailValue;

  @override
  Future<TournamentDetail> register(String id) async {
    registerCalls++;
    return detailValue;
  }

  @override
  Future<TournamentDetail> withdraw(String id) async {
    withdrawCalls++;
    return detailValue;
  }

  @override
  Future<TournamentDetail> create({
    required String name,
    required DateTime startsAt,
    int? maxTables,
    int? seatsPerTable,
    int? minSeatsPerTable,
  }) async => throw UnimplementedError();

  @override
  void dispose() {}
}

final _startsAt = DateTime.utc(2026, 9, 24, 19, 0);

TournamentSummary _summary({
  TournamentStatus status = TournamentStatus.scheduled,
  int registered = 9,
  bool isRegistered = false,
  int capacity = 16,
}) => TournamentSummary(
  id: 't1',
  name: 'The Winter Crown',
  status: status,
  startsAt: _startsAt,
  registered: registered,
  capacity: capacity,
  minEntrants: 2,
  isRegistered: isRegistered,
);

EntrantView _e(String id, String name, {bool active = true, int? rank}) =>
    EntrantView(userId: id, name: name, active: active, finalRank: rank);

TableView _table(
  int i,
  List<EntrantView> players, {
  TableStatus status = TableStatus.pending,
  String? winner,
}) => TableView(
  index: i,
  players: players,
  status: status,
  winnerUserId: winner,
  roomCode: 't1-r1-t$i',
);

Widget _host(Widget child) => MaterialApp(home: child);

Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(_host(screen));
  await tester.pump(); // let the first refresh land
}

void main() {
  group('before the clock fires', () {
    testWidgets('shows a countdown and the field, not a bracket', (
      tester,
    ) async {
      final src = _StubSource(
        TournamentDetail(
          summary: _summary(),
          entrants: [_e('you', 'You'), _e('p1', 'Rowan')],
          rounds: const [],
        ),
      );

      await _pump(
        tester,
        TournamentDetailScreen(
          source: src,
          tournamentId: 't1',
          viewerId: 'you',
        ),
      );

      expect(find.byType(StartCountdown), findsOneWidget);
      expect(find.text('Entered'.toUpperCase()), findsOneWidget);
      expect(find.text('Rowan'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      // No bracket exists yet — the shape is not known before the start.
      expect(find.textContaining('Table 1'), findsNothing);
    });

    testWidgets('offers entry, and withdrawal once entered', (tester) async {
      final src = _StubSource(
        TournamentDetail(
          summary: _summary(),
          entrants: [_e('p1', 'Rowan')],
          rounds: const [],
        ),
      );

      await _pump(
        tester,
        TournamentDetailScreen(
          source: src,
          tournamentId: 't1',
          viewerId: 'you',
        ),
      );

      expect(find.text('Enter tournament'), findsOneWidget);
      await tester.tap(find.text('Enter tournament'));
      await tester.pump();
      expect(src.registerCalls, 1);

      src.detailValue = TournamentDetail(
        summary: _summary(isRegistered: true),
        entrants: [_e('you', 'You'), _e('p1', 'Rowan')],
        rounds: const [],
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Withdraw'), findsOneWidget);
      await tester.tap(find.text('Withdraw'));
      await tester.pump();
      expect(src.withdrawCalls, 1);
    });

    testWidgets('a full field refuses entry', (tester) async {
      final src = _StubSource(
        TournamentDetail(
          summary: _summary(registered: 16),
          entrants: [for (var i = 0; i < 16; i++) _e('p$i', 'Player $i')],
          rounds: const [],
        ),
      );

      await _pump(
        tester,
        TournamentDetailScreen(
          source: src,
          tournamentId: 't1',
          viewerId: 'you',
        ),
      );

      expect(find.text('The field is full.'), findsOneWidget);
      expect(find.text('Enter tournament'), findsNothing);
    });

    testWidgets('an empty field says so rather than showing a blank box', (
      tester,
    ) async {
      final src = _StubSource(
        TournamentDetail(
          summary: _summary(registered: 0),
          entrants: const [],
          rounds: const [],
        ),
      );

      await _pump(
        tester,
        TournamentDetailScreen(
          source: src,
          tournamentId: 't1',
          viewerId: 'you',
        ),
      );

      expect(find.text('Nobody has entered yet.'), findsOneWidget);
    });
  });

  group('cancelled', () {
    testWidgets('explains why instead of showing an empty bracket', (
      tester,
    ) async {
      final src = _StubSource(
        TournamentDetail(
          summary: _summary(status: TournamentStatus.cancelled, registered: 1),
          entrants: [_e('ghost', 'Solitary Knight')],
          rounds: const [],
          cancelledReason: 'Only 1 player turned up — 2 are needed.',
        ),
      );

      await _pump(
        tester,
        TournamentDetailScreen(
          source: src,
          tournamentId: 't1',
          viewerId: 'you',
        ),
      );

      expect(find.text('Cancelled'), findsOneWidget);
      expect(
        find.text('Only 1 player turned up — 2 are needed.'),
        findsOneWidget,
      );
      expect(find.byType(StartCountdown), findsNothing);
    });
  });

  group('running', () {
    TournamentDetail running({TableStatus status = TableStatus.active}) =>
        TournamentDetail(
          summary: _summary(status: TournamentStatus.running),
          entrants: [
            _e('you', 'You'),
            _e('p1', 'Rowan'),
            _e('p2', 'Ada'),
            _e('p3', 'Bors'),
            _e('p4', 'Isolde'),
          ],
          rounds: [
            RoundView(
              number: 1,
              isFinal: false,
              tables: [
                _table(0, [
                  _e('you', 'You'),
                  _e('p1', 'Rowan'),
                  _e('p2', 'Ada'),
                ], status: status),
                _table(1, [
                  _e('p3', 'Bors'),
                  _e('p4', 'Isolde'),
                ], status: status),
              ],
            ),
          ],
        );

    testWidgets('renders the round and both tables', (tester) async {
      await _pump(
        tester,
        TournamentDetailScreen(
          source: _StubSource(running()),
          tournamentId: 't1',
          viewerId: 'you',
        ),
      );

      expect(find.text('ROUND 1'), findsOneWidget);
      expect(find.text('Table 1'), findsOneWidget);
      expect(find.text('Table 2'), findsOneWidget);
      expect(find.text('2 tables'), findsOneWidget);
    });

    testWidgets('marks the short-handed table', (tester) async {
      await _pump(
        tester,
        TournamentDetailScreen(
          source: _StubSource(running()),
          tournamentId: 't1',
          viewerId: 'you',
        ),
      );

      // Both tables are under four seats in this fixture.
      expect(find.text('short-handed'), findsNWidgets(2));
    });

    testWidgets('offers a seat only at the viewer\'s own live table', (
      tester,
    ) async {
      String? entered;
      await _pump(
        tester,
        TournamentDetailScreen(
          source: _StubSource(running()),
          tournamentId: 't1',
          viewerId: 'you',
          onEnterTable: (code) => entered = code,
        ),
      );

      expect(find.text('Take your seat'), findsOneWidget);
      await tester.tap(find.text('Take your seat'));
      expect(entered, 't1-r1-t0');
    });

    testWidgets('no seat offered before the table is dealt', (tester) async {
      await _pump(
        tester,
        TournamentDetailScreen(
          source: _StubSource(running(status: TableStatus.pending)),
          tournamentId: 't1',
          viewerId: 'you',
          onEnterTable: (_) {},
        ),
      );

      expect(find.text('Take your seat'), findsNothing);
      expect(find.text('seated'), findsNWidgets(2));
    });

    testWidgets('a spectator is offered no seat at all', (tester) async {
      await _pump(
        tester,
        TournamentDetailScreen(
          source: _StubSource(running()),
          tournamentId: 't1',
          viewerId: 'nobody',
          onEnterTable: (_) {},
        ),
      );

      expect(find.text('Take your seat'), findsNothing);
    });
  });

  group('finished', () {
    testWidgets('names the champion, and says so when it is you', (
      tester,
    ) async {
      final detail = TournamentDetail(
        summary: _summary(status: TournamentStatus.finished),
        championUserId: 'you',
        entrants: [_e('you', 'You', rank: 1), _e('p1', 'Rowan', rank: 2)],
        rounds: [
          RoundView(
            number: 1,
            isFinal: true,
            tables: [
              _table(
                0,
                [_e('you', 'You', rank: 1), _e('p1', 'Rowan', rank: 2)],
                status: TableStatus.finished,
                winner: 'you',
              ),
            ],
          ),
        ],
      );

      await _pump(
        tester,
        TournamentDetailScreen(
          source: _StubSource(detail),
          tournamentId: 't1',
          viewerId: 'you',
        ),
      );

      expect(find.text('You are champion'), findsOneWidget);
      expect(find.text('FINAL TABLE'), findsOneWidget);
      expect(find.text('1 table'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
    });

    testWidgets('a single-table field never shows a Round 1', (tester) async {
      final detail = TournamentDetail(
        summary: _summary(status: TournamentStatus.running, registered: 3),
        entrants: [_e('you', 'You'), _e('p1', 'Rowan'), _e('p2', 'Ada')],
        rounds: [
          RoundView(
            number: 1,
            isFinal: true,
            tables: [
              _table(0, [_e('you', 'You'), _e('p1', 'Rowan'), _e('p2', 'Ada')]),
            ],
          ),
        ],
      );

      await _pump(
        tester,
        TournamentDetailScreen(
          source: _StubSource(detail),
          tournamentId: 't1',
          viewerId: 'you',
        ),
      );

      expect(find.text('FINAL TABLE'), findsOneWidget);
      expect(
        find.text('ROUND 1'),
        findsNothing,
        reason:
            'one table is the final — calling it Round 1 promises a round '
            'that never comes',
      );
    });
  });

  group('countdown formatting', () {
    test('drops the hour when there is none', () {
      expect(formatCountdown(const Duration(seconds: 9)), '0:09');
      expect(formatCountdown(const Duration(minutes: 4, seconds: 9)), '4:09');
      expect(
        formatCountdown(const Duration(hours: 1, minutes: 4, seconds: 9)),
        '1:04:09',
      );
    });

    test('never runs negative', () {
      expect(formatCountdown(const Duration(seconds: -5)), '0:00');
    });
  });
}

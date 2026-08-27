import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/games/medieval_poker/tournament/tournament_list_screen.dart';
import 'package:kiduna/games/medieval_poker/tournament/tournament_models.dart';
import 'package:kiduna/games/medieval_poker/tournament/tournament_source.dart';
import 'package:kiduna/games/medieval_poker/tournament/widgets/tournament_card.dart';

class _StubSource implements TournamentSource {
  List<TournamentSummary> rows;
  Object? failWith;
  _StubSource(this.rows);

  @override
  Future<List<TournamentSummary>> list() async {
    if (failWith != null) throw failWith!;
    return rows;
  }

  @override
  Future<TournamentDetail> detail(String id) async =>
      throw UnimplementedError();
  @override
  Future<TournamentDetail> register(String id) async =>
      throw UnimplementedError();
  @override
  Future<TournamentDetail> withdraw(String id) async =>
      throw UnimplementedError();

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

final _now = DateTime.utc(2026, 9, 24, 18, 52, 40);

TournamentSummary _t(
  String id,
  String name, {
  TournamentStatus status = TournamentStatus.scheduled,
  int minutesAway = 8,
  int registered = 9,
  bool isRegistered = false,
  int minEntrants = 2,
}) => TournamentSummary(
  id: id,
  name: name,
  status: status,
  startsAt: _now.add(Duration(minutes: minutesAway)),
  registered: registered,
  capacity: 16,
  minEntrants: minEntrants,
  isRegistered: isRegistered,
);

Future<void> _pump(
  WidgetTester tester,
  TournamentSource source, {
  void Function(TournamentSummary)? onOpen,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TournamentListScreen(
        source: source,
        viewerId: 'you',
        clock: () => _now,
        onOpen: onOpen,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('renders a card per tournament', (tester) async {
    await _pump(
      tester,
      _StubSource([_t('a', 'The Winter Crown'), _t('b', 'Blackwater Open')]),
    );

    expect(find.byType(TournamentCard), findsNWidgets(2));
    expect(find.text('The Winter Crown'), findsOneWidget);
    expect(find.text('Blackwater Open'), findsOneWidget);
  });

  group('sections', () {
    testWidgets('separates what you are in from what you could enter', (
      tester,
    ) async {
      await _pump(
        tester,
        _StubSource([
          _t('a', 'Mine', isRegistered: true),
          _t('b', 'Open to all'),
        ]),
      );

      expect(find.text('YOUR TOURNAMENTS'), findsOneWidget);
      expect(find.text('OPEN TO ENTER'), findsOneWidget);
      expect(find.text('FINISHED'), findsNothing);
    });

    testWidgets('an empty section is not rendered at all', (tester) async {
      await _pump(tester, _StubSource([_t('b', 'Open to all')]));

      expect(find.text('OPEN TO ENTER'), findsOneWidget);
      expect(
        find.text('YOUR TOURNAMENTS'),
        findsNothing,
        reason: 'an empty heading is noise',
      );
    });

    testWidgets('finished and cancelled drop below, out of the live sets', (
      tester,
    ) async {
      await _pump(
        tester,
        _StubSource([
          _t(
            'a',
            'Done',
            status: TournamentStatus.finished,
            isRegistered: true,
          ),
          _t('b', 'Called off', status: TournamentStatus.cancelled),
          _t('c', 'Live', status: TournamentStatus.running, isRegistered: true),
        ]),
      );

      expect(find.text('FINISHED'), findsOneWidget);
      // A finished tournament you entered is not still "yours" to attend.
      expect(find.text('YOUR TOURNAMENTS'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // two in the finished section
    });
  });

  group('card state', () {
    testWidgets('a scheduled tournament counts down', (tester) async {
      await _pump(tester, _StubSource([_t('a', 'Soon', minutesAway: 7)]));
      expect(find.text('7:00'), findsOneWidget);
    });

    testWidgets('past its time but not yet seated reads as starting', (
      tester,
    ) async {
      await _pump(tester, _StubSource([_t('a', 'Now', minutesAway: -1)]));
      expect(find.text('starting'), findsOneWidget);
    });

    testWidgets('running, finished and cancelled state themselves', (
      tester,
    ) async {
      await _pump(
        tester,
        _StubSource([
          _t('a', 'A', status: TournamentStatus.running),
          _t('b', 'B', status: TournamentStatus.finished),
          _t('c', 'C', status: TournamentStatus.cancelled),
        ]),
      );

      expect(find.text('playing'), findsOneWidget);
      expect(find.text('finished'), findsOneWidget);
      expect(find.text('cancelled'), findsOneWidget);
    });

    testWidgets('marks the ones you have entered', (tester) async {
      await _pump(
        tester,
        _StubSource([_t('a', 'Mine', isRegistered: true), _t('b', 'Theirs')]),
      );
      expect(find.text('you are in'), findsOneWidget);
    });

    testWidgets('warns when a field is too small to run', (tester) async {
      await _pump(
        tester,
        _StubSource([_t('a', 'Thin', registered: 1, minEntrants: 2)]),
      );
      expect(find.text('needs more players'), findsOneWidget);
    });

    testWidgets('shows how full the field is', (tester) async {
      await _pump(tester, _StubSource([_t('a', 'A', registered: 9)]));
      expect(find.text('9 of 16 entered'), findsOneWidget);
    });
  });

  group('interaction', () {
    testWidgets('tapping a card opens it', (tester) async {
      TournamentSummary? opened;
      await _pump(
        tester,
        _StubSource([_t('a', 'The Winter Crown')]),
        onOpen: (t) => opened = t,
      );

      await tester.tap(find.byType(TournamentCard));
      expect(opened?.id, 'a');
    });
  });

  group('empty and error', () {
    testWidgets('says so when there is nothing scheduled', (tester) async {
      await _pump(tester, _StubSource([]));
      expect(find.textContaining('No tournaments scheduled'), findsOneWidget);
    });

    testWidgets('a failing source shows the problem, not a dead spinner', (
      tester,
    ) async {
      final src = _StubSource([])..failWith = StateError('network is down');
      await _pump(tester, src);
      await tester.pump();

      expect(find.textContaining('network is down'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}

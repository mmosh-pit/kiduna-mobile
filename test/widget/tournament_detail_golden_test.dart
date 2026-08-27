import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/games/medieval_poker/tournament/tournament_detail_screen.dart';
import 'package:kiduna/games/medieval_poker/tournament/tournament_models.dart';
import 'package:kiduna/games/medieval_poker/tournament/tournament_source.dart';

/// Goldens for the tournament screen's four states.
///
/// The clock is injected, so the countdown is fixed rather than ticking under
/// the golden. Real brand fonts are loaded — without them the renderer
/// substitutes Ahem and the goldens catch layout drift but say nothing about
/// whether the screen reads.
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
        file.readAsBytes().then(
          (b) => ByteData.view(Uint8List.fromList(b).buffer),
        ),
      );
    }
    await loader.load();
  }
}

class _StubSource implements TournamentSource {
  final TournamentDetail value;
  _StubSource(this.value);

  @override
  Future<List<TournamentSummary>> list() async => [value.summary];
  @override
  Future<TournamentDetail> detail(String id) async => value;
  @override
  Future<TournamentDetail> register(String id) async => value;
  @override
  Future<TournamentDetail> withdraw(String id) async => value;

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
final _startsAt = DateTime.utc(2026, 9, 24, 19, 0);

TournamentSummary _summary({
  TournamentStatus status = TournamentStatus.scheduled,
  int registered = 9,
  bool isRegistered = false,
}) => TournamentSummary(
  id: 't1',
  name: 'The Winter Crown',
  status: status,
  startsAt: _startsAt,
  registered: registered,
  capacity: 16,
  minEntrants: 2,
  isRegistered: isRegistered,
);

EntrantView _e(String id, String name, {bool active = true, int? rank}) =>
    EntrantView(userId: id, name: name, active: active, finalRank: rank);

void main() {
  setUpAll(_loadFonts);

  Future<void> shoot(
    WidgetTester tester,
    String name,
    TournamentDetail detail, {
    String viewerId = 'you',
    Size size = const Size(430, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: TournamentDetailScreen(
          source: _StubSource(detail),
          tournamentId: 't1',
          viewerId: viewerId,
          clock: () => _now,
          onEnterTable: (_) {},
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(TournamentDetailScreen),
      matchesGoldenFile('goldens/tournament_$name.png'),
    );
  }

  testWidgets('golden: waiting for the clock', (tester) async {
    await shoot(
      tester,
      'scheduled',
      TournamentDetail(
        summary: _summary(),
        entrants: [
          _e('you', 'You'),
          _e('p1', 'Rowan'),
          _e('p2', 'Ada'),
          _e('p3', 'Bors', active: false),
          _e('p4', 'Isolde'),
        ],
        rounds: const [],
      ),
    );
  });

  testWidgets('golden: under way', (tester) async {
    await shoot(
      tester,
      'running',
      TournamentDetail(
        summary: _summary(status: TournamentStatus.running, isRegistered: true),
        entrants: const [],
        rounds: [
          RoundView(
            number: 1,
            isFinal: false,
            tables: [
              TableView(
                index: 0,
                status: TableStatus.active,
                roomCode: 't1-r1-t0',
                players: [_e('you', 'You'), _e('p1', 'Rowan'), _e('p2', 'Ada')],
              ),
              TableView(
                index: 1,
                status: TableStatus.finished,
                winnerUserId: 'p3',
                roomCode: 't1-r1-t1',
                players: [_e('p3', 'Bors'), _e('p4', 'Isolde', rank: 5)],
              ),
            ],
          ),
        ],
      ),
    );
  });

  testWidgets('golden: cancelled for want of players', (tester) async {
    await shoot(
      tester,
      'cancelled',
      TournamentDetail(
        summary: _summary(status: TournamentStatus.cancelled, registered: 1),
        entrants: [_e('ghost', 'Solitary Knight')],
        rounds: const [],
        cancelledReason: 'Only 1 player turned up — 2 are needed.',
      ),
      size: const Size(430, 460),
    );
  });

  testWidgets('golden: champion', (tester) async {
    await shoot(
      tester,
      'champion',
      TournamentDetail(
        summary: _summary(status: TournamentStatus.finished, registered: 3),
        championUserId: 'you',
        entrants: const [],
        rounds: [
          RoundView(
            number: 1,
            isFinal: true,
            tables: [
              TableView(
                index: 0,
                status: TableStatus.finished,
                winnerUserId: 'you',
                roomCode: 't1-r1-t0',
                players: [
                  _e('you', 'You', rank: 1),
                  _e('p1', 'Rowan', rank: 2),
                  _e('p2', 'Ada', rank: 3),
                ],
              ),
            ],
          ),
        ],
      ),
      size: const Size(430, 620),
    );
  });
}

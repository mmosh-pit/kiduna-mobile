import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/games/medieval_poker/tournament/tournament_list_screen.dart';
import 'package:kiduna/games/medieval_poker/tournament/tournament_models.dart';
import 'package:kiduna/games/medieval_poker/tournament/tournament_source.dart';

/// Golden for the list, with the real brand fonts loaded and a fixed clock so
/// the countdowns do not tick under it.
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
  final List<TournamentSummary> rows;
  _StubSource(this.rows);
  @override
  Future<List<TournamentSummary>> list() async => rows;
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

void main() {
  setUpAll(_loadFonts);

  testWidgets('golden: the tournament list', (tester) async {
    tester.view.physicalSize = const Size(430, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: TournamentListScreen(
          source: _StubSource([
            _t(
              'a',
              'Blackwater Open',
              status: TournamentStatus.running,
              isRegistered: true,
            ),
            _t('b', 'The Winter Crown', minutesAway: 7, isRegistered: true),
            _t('c', 'Tavern Duel', minutesAway: 22, registered: 3),
            _t(
              'd',
              'The Empty Hall',
              minutesAway: 41,
              registered: 1,
              minEntrants: 2,
            ),
            _t(
              'e',
              'Harvest Cup',
              status: TournamentStatus.finished,
              registered: 16,
            ),
          ]),
          viewerId: 'you',
          clock: () => _now,
          onOpen: (_) {},
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(TournamentListScreen),
      matchesGoldenFile('goldens/tournament_list.png'),
    );
  });
}

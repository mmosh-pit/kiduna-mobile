import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/config/theme.dart';
import 'package:kiduna/games/medieval_poker/tournament/medieval_poker_tournament_list_screen.dart';
import 'package:kiduna/games/medieval_poker/tournament/tournament_client.dart';
import 'package:kiduna/l10n/app_localizations.dart';

import '../mocks/fake_dio.dart';

Map<String, dynamic> _row(String id, String name, {int registered = 2}) => {
  'id': id,
  'name': name,
  'status': 'registering',
  'size': 4,
  'registered': registered,
  'currentRound': 0,
  'totalRounds': 1,
  'isRegistered': false,
  'isCreator': false,
};

Future<FakeDio> _pump(
  WidgetTester tester,
  FakeReply Function(dynamic options) handler, {
  void Function(String id)? onOpen,
  Size size = const Size(900, 900),
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
        body: MedievalPokerTournamentListScreen(
          client: TournamentClient(dio: fake.dio),
          onOpen: onOpen ?? (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fake;
}

void main() {
  testWidgets('lists the open tournaments', (tester) async {
    await _pump(
      tester,
      (_) => FakeReply(
        envelope({
          'tournaments': [_row('t1', 'Founders Cup'), _row('t2', 'Rogue Open')],
        }),
      ),
    );

    expect(find.text('Founders Cup'), findsOneWidget);
    expect(find.text('Rogue Open'), findsOneWidget);
    expect(find.text('2 of 4 players'), findsNWidgets(2));
  });

  testWidgets('shows an empty state when nobody has made one', (tester) async {
    await _pump(tester, (_) => FakeReply(envelope({'tournaments': []})));

    expect(find.text('No tournaments yet'), findsOneWidget);
    expect(find.text('Create Tournament'), findsOneWidget);
  });

  testWidgets('shows an error state — not an empty list — when loading fails', (
    tester,
  ) async {
    // A failed request previously looked identical to "there are none", which
    // hides a broken backend from the player.
    await _pump(tester, (_) => const FakeReply(null, statusCode: 500));

    expect(find.text('Could not load tournaments'), findsOneWidget);
    expect(find.text('No tournaments yet'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('opens the tournament that was tapped', (tester) async {
    String? opened;
    await _pump(
      tester,
      (_) => FakeReply(
        envelope({
          'tournaments': [_row('t1', 'Founders Cup')],
        }),
      ),
      onOpen: (id) => opened = id,
    );

    await tester.tap(find.text('Founders Cup'));
    await tester.pumpAndSettle();

    expect(opened, 't1');
  });

  testWidgets('switches the status filter and refetches', (tester) async {
    final fake = await _pump(
      tester,
      (_) => FakeReply(envelope({'tournaments': []})),
    );

    expect(fake.requests.last.queryParameters['status'], 'registering');

    await tester.tap(find.text('Finished'));
    await tester.pumpAndSettle();

    expect(fake.requests.last.queryParameters['status'], 'finished');
  });

  testWidgets('creates a tournament from the sheet and opens it', (
    tester,
  ) async {
    String? opened;
    await _pump(tester, (options) {
      if (options.method == 'POST') {
        return FakeReply(
          envelope({
            'tournament': _row('new-1', 'My Cup'),
            'entrants': const [],
            'bracket': const [],
            'myMatch': null,
          }),
        );
      }
      return FakeReply(envelope({'tournaments': []}));
    }, onOpen: (id) => opened = id);

    await tester.tap(find.text('Create Tournament'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'My Cup');
    await tester.tap(find.text('8'));
    await tester.pumpAndSettle();

    // The sheet's own submit button, not the list's.
    await tester.tap(find.text('Create Tournament').last);
    await tester.pumpAndSettle();

    expect(opened, 'new-1');
  });

  testWidgets('will not create a tournament with a blank name', (tester) async {
    await _pump(tester, (_) => FakeReply(envelope({'tournaments': []})));

    await tester.tap(find.text('Create Tournament'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Tournament').last);
    await tester.pumpAndSettle();

    // Still on the sheet.
    expect(find.byType(TextField), findsOneWidget);
  });
}

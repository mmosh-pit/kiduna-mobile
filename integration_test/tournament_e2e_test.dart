import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:kiduna/main.dart' as app;

/// End-to-end journey for tournaments, through the real app.
///
/// This is the definition of done. It drives the shipped `main.dart` — real
/// login, real navigation, real backend — rather than a harness, so a step only
/// passes when a logged-in player can actually do it.
///
/// **Steps that are not wired yet fail on purpose.** Each one names what is
/// missing, so the output reads as a checklist of remaining work rather than a
/// pile of red. Do not weaken an assertion to make it green: delete it only
/// when the thing it describes genuinely works.
///
/// Needs a running backend and a real account:
///
///   flutter test integration_test/tournament_e2e_test.dart \
///     -d chrome \
///     --dart-define=E2E_EMAIL=you@example.com \
///     --dart-define=E2E_PASSWORD=... \
///     --dart-define=E2E_TOURNAMENT="The Winter Crown"
///
/// On a device or simulator, swap `-d chrome` for its id. Without credentials
/// the suite skips rather than failing, so it stays useful in CI before secrets
/// are wired.

const _email = String.fromEnvironment('E2E_EMAIL');
const _password = String.fromEnvironment('E2E_PASSWORD');
const _tournamentName = String.fromEnvironment(
  'E2E_TOURNAMENT',
  defaultValue: 'The Winter Crown',
);

bool get _haveCredentials => _email.isNotEmpty && _password.isNotEmpty;

/// Pumps until [finder] matches, or gives up after [timeout].
///
/// The app polls the backend on timers, so waiting on a real state change means
/// pumping repeatedly — `pumpAndSettle` would time out against a screen that
/// never stops ticking.
Future<bool> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return true;
  }
  return false;
}

/// Fails with a message that says what is missing, not just what did not match.
void expectWired(bool found, String what, String missing) {
  expect(
    found,
    isTrue,
    reason:
        '\n  NOT WIRED: $what'
        '\n  Missing:   $missing\n',
  );
}

Future<void> logIn(WidgetTester tester) async {
  app.main();
  await tester.pump(const Duration(seconds: 2));

  final emailField = find.widgetWithText(TextField, 'name@example.com');
  final byLabel = find.text('Email address');
  final foundLogin = await pumpUntil(
    tester,
    byLabel.evaluate().isNotEmpty ? byLabel : emailField,
  );
  expect(foundLogin, isTrue, reason: 'the app did not reach the login screen');

  final fields = find.byType(TextField);
  expect(
    fields.evaluate().length,
    greaterThanOrEqualTo(2),
    reason: 'expected an email and a password field on the login screen',
  );

  await tester.enterText(fields.at(0), _email);
  await tester.pump();
  await tester.enterText(fields.at(1), _password);
  await tester.pump();

  await tester.tap(find.text('Log in'));
  await tester.pump();

  final landed = await pumpUntil(
    tester,
    find.text('Standings'),
    timeout: const Duration(seconds: 30),
  );
  expect(
    landed,
    isTrue,
    reason:
        'login did not reach the dashboard — check the credentials and that '
        'the backend is reachable',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('tournament journey', () {
    testWidgets('a logged-in player reaches tournaments', (tester) async {
      if (!_haveCredentials) {
        markTestSkipped('set E2E_EMAIL and E2E_PASSWORD to run');
        return;
      }

      await logIn(tester);

      // The Standings tab already exists in the dashboard; today it renders a
      // "coming soon" placeholder.
      await tester.tap(find.text('Standings'));
      await tester.pump(const Duration(seconds: 1));

      final listed = await pumpUntil(tester, find.text('Tournaments'));
      expectWired(
        listed,
        'the Standings tab shows tournaments',
        'the Standings tab hosts TournamentsPanel. If this fails the backend '
            'is unreachable or has no /tournaments route — those live on '
            'kinship-backend branch feat/tournaments.',
      );
    });

    testWidgets('entering a tournament shows the field and a countdown', (
      tester,
    ) async {
      if (!_haveCredentials) {
        markTestSkipped('set E2E_EMAIL and E2E_PASSWORD to run');
        return;
      }

      await logIn(tester);
      await tester.tap(find.text('Standings'));
      await tester.pump(const Duration(seconds: 1));

      final open = find.text(_tournamentName);
      final found = await pumpUntil(tester, open);
      expectWired(
        found,
        'a tournament is listed by name',
        'no tournament named "$_tournamentName" reached the app. Either the '
            'list is not mounted, or the backend has none scheduled.',
      );

      await tester.tap(open);
      await tester.pump(const Duration(seconds: 1));

      expectWired(
        await pumpUntil(tester, find.text('STARTS IN')),
        'the detail screen counts down to the start',
        'TournamentDetailScreen is not reachable from the list.',
      );
      expect(
        find.text('Enter tournament').evaluate().isNotEmpty ||
            find.text('Withdraw').evaluate().isNotEmpty,
        isTrue,
        reason: 'a scheduled tournament must offer entry or withdrawal',
      );
    });

    testWidgets('the bracket appears when the clock fires', (tester) async {
      if (!_haveCredentials) {
        markTestSkipped('set E2E_EMAIL and E2E_PASSWORD to run');
        return;
      }

      await logIn(tester);
      await tester.tap(find.text('Standings'));
      await tester.pump(const Duration(seconds: 1));

      final open = find.text(_tournamentName);
      if (!await pumpUntil(tester, open)) {
        expectWired(false, 'a tournament is listed', 'see the previous test');
        return;
      }
      await tester.tap(open);
      await tester.pump(const Duration(seconds: 1));

      // Enter if not already in, then wait out the clock.
      if (find.text('Enter tournament').evaluate().isNotEmpty) {
        await tester.tap(find.text('Enter tournament'));
        await tester.pump(const Duration(seconds: 1));
      }

      final seated = await pumpUntil(
        tester,
        find.textContaining('Table 1'),
        timeout: const Duration(minutes: 3),
      );
      expectWired(
        seated,
        'the bracket is seated once the start time passes',
        'no table appeared. The backend seats the field on its clock — check '
            'the tournament actually started and had enough active entrants.',
      );

      // A short-handed table must say so rather than looking under-filled.
      expect(
        find.text('short-handed').evaluate().isNotEmpty ||
            find.text('playing').evaluate().isNotEmpty ||
            find.text('seated').evaluate().isNotEmpty,
        isTrue,
        reason: 'a seated table must show its state',
      );
    });

    testWidgets('taking your seat opens a real table', (tester) async {
      if (!_haveCredentials) {
        markTestSkipped('set E2E_EMAIL and E2E_PASSWORD to run');
        return;
      }

      await logIn(tester);
      await tester.tap(find.text('Standings'));
      await tester.pump(const Duration(seconds: 1));

      final open = find.text(_tournamentName);
      if (!await pumpUntil(tester, open)) {
        expectWired(false, 'a tournament is listed', 'see the earlier tests');
        return;
      }
      await tester.tap(open);
      await tester.pump(const Duration(seconds: 1));

      final seat = find.text('Take your seat');
      final offered = await pumpUntil(
        tester,
        seat,
        timeout: const Duration(minutes: 3),
      );
      expectWired(
        offered,
        'your own live table offers a seat',
        'the viewer id passed to TournamentDetailScreen must be the '
            'logged-in user, or no table will match them.',
      );

      await tester.tap(seat);
      await tester.pump(const Duration(seconds: 2));

      // The table itself: the HUD is what proves the handoff worked.
      final atTable = await pumpUntil(
        tester,
        find.textContaining('Ante'),
        timeout: const Duration(seconds: 45),
      );
      expectWired(
        atTable,
        'taking a seat joins the actual game',
        'the seat goes through the lobby join, which returns the seat the '
            'bracket assigned and a token signing the table size. If this '
            'fails, the game-service is unreachable or the WS proxy is not '
            'attached — the REST half is covered by '
            'scripts/tournament-api-smoke.ts.',
      );
    });

    testWidgets('finishing a table shows ranked standings', (tester) async {
      if (!_haveCredentials) {
        markTestSkipped('set E2E_EMAIL and E2E_PASSWORD to run');
        return;
      }

      // Deliberately does not log in: this step is blocked upstream, so
      // driving the app first would replace its message with whatever failed
      // earlier. It reports the blockage instead.
      expectWired(
        false,
        'a finished tournament table shows ranked standings',
        'StandingsScreen renders ranked places already, but nothing tells it '
            'the table was a tournament heat: GameOverView.tournament is never '
            'populated, so it offers "Play Again" instead of "Continue to '
            'Final Table". Populate TournamentOutcomeView when the room '
            'belongs to a tournament.',
      );
    });

    testWidgets('winning advances you to the final table', (tester) async {
      if (!_haveCredentials) {
        markTestSkipped('set E2E_EMAIL and E2E_PASSWORD to run');
        return;
      }

      // As above — reported directly rather than behind a login.
      expectWired(
        false,
        'winning a table advances you to the final',
        'the backend seats the next round when every table reports '
            '(scripts/tournament-api-smoke.ts covers it). What is missing is '
            'the client following it: after winning, returning to the detail '
            'screen should show FINAL TABLE and offer a seat at it.',
      );
    });
  });
}

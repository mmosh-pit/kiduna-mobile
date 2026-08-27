# End-to-end tests

These drive the **real app** — `lib/main.dart`, real login, real backend. Not a
harness. A step passes only when a logged-in player can actually do the thing.

## Running on the web

`flutter test -d chrome` does **not** work — it answers *"Web devices are not
supported for integration tests yet."* The browser path goes through
`flutter drive` with chromedriver, which is what `test_driver/integration_test.dart`
is for.

```bash
# once: install the driver, and clear the macOS quarantine flag Homebrew sets,
# or it exits silently with no output
brew install --cask chromedriver
xattr -d com.apple.quarantine "$(readlink -f "$(which chromedriver)")"

# leave running in another shell
chromedriver --port=4444

flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/tournament_e2e_test.dart \
  -d chrome --browser-name=chrome \
  --dart-define=E2E_EMAIL=you@example.com \
  --dart-define=E2E_PASSWORD=... \
  --dart-define=E2E_TOURNAMENT="The Winter Crown"
```

chromedriver's major version must match the installed Chrome. For CI, add
`--headless` so no browser window opens.

### Other platforms

```bash
flutter test integration_test/tournament_e2e_test.dart -d macos [--dart-define=...]
```

macOS, a simulator or a device all work through plain `flutter test -d <id>`;
only web needs the driver.

Without credentials every test **skips** rather than failing, so this stays
green in CI until secrets are wired.

### CORS

The web build runs on an origin the backend must allow. `kinship-backend`
registers `cors` with `origin: "*"`, so a local run is fine; a locked-down
deployment needs the test origin allowed.

Needs a backend with at least one scheduled tournament. The tournament routes
live on `kinship-backend`, branch `feat/tournaments`.

## Read the failures as a checklist

`tournament_e2e_test.dart` is the definition of done for tournaments, and it is
**written to fail where the feature is not wired**. Each failure names the gap:

```
NOT WIRED: taking a seat joins the actual game
Missing:   the tournament match carries a roomCode, but nothing connects it
           to RemoteSession. Mint a game token for the room and push the poker
           table the way MedievalPokerLobbyScreen does on join. …
```

Work top to bottom; each step unblocks the next.

**Do not weaken an assertion to make it green.** Delete a step only when the
thing it describes genuinely works.

## What is wired today

| Step | |
|---|---|
| Log in and reach the dashboard | ✅ ships already |
| Standings tab shows tournaments | ❌ tab 2 renders `_ComingSoonPanel` |
| Enter a tournament, see the countdown | ❌ list not mounted |
| Bracket appears when the clock fires | ❌ blocked above (backend side works) |
| Take your seat → a real table | ❌ **the main gap** — no WS handoff |
| Finished table shows ranked standings | ❌ blocked on the handoff |
| Winning advances you to the final | ❌ blocked on the handoff |

The pieces those steps need all exist and are tested in isolation —
`TournamentListScreen`, `TournamentDetailScreen`, `RestTournamentSource`,
`StandingsScreen`. What is missing is mounting them and the seat handoff.

## One trap before wiring the seat

Tournament tables are **short-handed** — a heat can seat two or three players.
The game-service takes table size from the `?seats=` query parameter, which the
client supplies and the service trusts, and the first connection to a room fixes
its size. Move the seat count into the signed game token (the service already
verifies room and seat from it) **before** wiring the handoff, or a client can
set its own table size.

## The other half

The server side has its own end-to-end, and it passes:

```bash
# in kinship-backend, on feat/tournaments
createdb tournament_verify
for f in drizzle/*.sql; do psql -v ON_ERROR_STOP=1 -d tournament_verify -f "$f"; done
DATABASE_URL=postgresql://$USER@localhost:5432/tournament_verify \
  JWT_SECRET=verify-secret NODE_ENV=test \
  npx tsx scripts/tournament-api-smoke.ts
dropdb tournament_verify
```

35 checks over a whole tournament: create → register → the clock fires → the
bracket is seated → tables report → the next round is seated → champion,
including five players opening 3 + 2 rather than 4 + 1, rooms created at their
real short-handed size, and a retried result not advancing the bracket twice.

`scripts/tournament-bracket-smoke.ts` separately pins the TypeScript bracket to
the Dart one, so the shape the server seats and the shape the client renders
cannot drift.

## A note on Playwright

Playwright cannot assert on this app. Flutter renders to a single `<canvas>`,
so there is no DOM to query — it can screenshot and confirm the page boots, and
nothing more. It is worth having as a deploy smoke test for the web build; it is
not a substitute for these.

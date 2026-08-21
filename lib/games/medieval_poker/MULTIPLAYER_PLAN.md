# Medieval Poker — Multiplayer Implementation Plan

> Status: **Phases 0–6 complete (2026-08)** · Offline (single-player vs AI) stays available and is now also convergeable onto the shared seam (LocalSession).
> This document is the reference plan + build log for the **online multiplayer** mode.
>
> **Deferred items — finished in code (2026-08):**
> - ✅ **Power Deck viewer parity** — `TableSnapshot` now carries the viewer's own deck breakdown (`yourPowerHand`/`yourDrawDeck`/`yourDiscard`/`yourOneShot`; draw deck name-sorted server-side to hide order); `serializeFor` populates it; `SessionHud` gained a Deck viewer overlay (works online *and* on the converged offline path). Verified: the offline full-game test asserts the snapshot carries the deck.
> - ✅ **Timed-levels passthrough** — client sends the room's `timedLevels` as a `?timed=` WS hint; the game-service builds that room's `PokerConfig` from it (added `PokerConfig.copyWith`) and the level clock respects the per-room config. Verified by `tool/timed_passthrough_smoke.dart`.
> - ✅ **Seat-ownership hardening (stale-ticket reclaim, in-reach part)** — once a userId claims a seat, a ticket for a *different* user is refused even while the seat is unattached/AI-held. Verified by `tool/seat_lock_smoke.dart`. **Residual:** airtight revocation across a legitimate lobby *reassignment* (user A leaves, B takes the seat, A replays a still-valid ticket and connects *first*) still needs the game-service to consult Node's seat-ownership — a server-to-server check left as a future item (the common case is closed; the residual is griefing-only, no data leak).
>
> **Remaining (genuinely blocked on infra / a device / your decision — NOT code):**
> - **Node never executed against Postgres** — the whole backend is typecheck-verified only; Drizzle runtime behaviors + the full 3-process end-to-end path are unrun (no PG/Node deploy reachable here).
> - ✅ **Production entry point added (2026-08)** — tapping the Medieval Poker card now opens `MedievalPokerModeScreen` (route `medievalPokerModeRoute`): **Single-player vs AI** (offline, works anywhere) or **Play Online** (→ lobby: create/join by code, Find a Public Game, Leaderboard). Long-press still opens the debug sandbox. Online still requires the game-service + backend running and the user signed in (see `ONLINE_BRINGUP.md`) — but it's now discoverable in the normal UI.
> - ✅ **Node runtime proven against real Postgres (2026-08)** — isolated Docker PG + a games-only Fastify harness ran the full flow (create/join/ready/start, matchmaking `FOR UPDATE SKIP LOCKED`, idempotent secret-gated result report, leaderboard/stats/history `@>`) — 16/16. The remaining unrun piece is only the on-device app UI + a single live 3-process loop.
> - **On-device visual/UX passes** — need a device.
> - **Anti-cheat audit log + Redis** — Redis only if multi-instance (premature); audit log is a future add (server-authoritative no-leak design already covers the core threat).
> - **Ops:** backend (`kinship/plugin/kinship-backend`) changes are uncommitted on `main` for review; the pre-existing `agents` schema↔migration drift (Phase 3) is a team reconcile.
>
> **Audit (2026-08, "double-check") findings:**
> - ✅ **Cross-language JWT verified** — a real `@fastify/jwt`-minted token validates in the Dart `GameTokenVerifier` (claims match; wrong secret rejected). The lobby↔service auth handshake is proven, not assumed.
> - 🐛 **Fixed:** the lobby's create allowed `seats: 2–8` while the game-service is fixed at 4 and silently clamps `seat ≥ 4 → 0` (a joiner would collide onto the host). The lobby now always creates 4-seat rooms (empty seats AI-filled). Variable seat counts still need a configurable game-service.
> - ⚠️ **Not executed:** the whole Node backend is **typecheck-verified only** — never run against Postgres. Runtime behaviors (Drizzle `transaction` + `FOR UPDATE SKIP LOCKED`, `onConflictDoUpdate` increments, the `participant_ids @> …::jsonb` history query, empty-body POST handling) are unproven. The full three-process path (Flutter client ↔ game-service ↔ Node ↔ PG) has **never been run end-to-end**.
> - ⚠️ **No production entry point:** online play (lobby / matchmaking / online table / leaderboard) is reachable **only from the debug sandbox**, and depends on the app holding a valid `user_token`. There is no "Play Online" in the app's real navigation, and the app's login/auth state was not verified.

## Decisions locked in

| Question | Decision |
|---|---|
| Authoritative engine location | **Reuse the Dart `PokerGame` engine** in a small Dart WebSocket game-service (one rules engine, no divergence). Node handles auth/matchmaking/persistence. |
| Matchmaking | **Both** — friends-only invite rooms in **v1**, public matchmaking queue in **v2**. |
| Pace | **Real-time** — all players present; per-turn clock (~30s); timeout → fold / pass / AI. |
| AI in online tables | **Yes** — backfill empty seats and disconnected players with the existing `AiBrain`; a match never stalls. |

## Why server-authoritative
Poker is a hidden-information game. The server must hold the deck and each player's hole cards and reveal them **per-player**. A relay/"host" model would leak cards, so the engine runs on a **trusted server** and each client only ever receives its own secrets.

## Backend visibility (confirmed)
`kinship-backend` = **`mmosh-backend-node`** at `kinship/plugin/kinship-backend` (a **separate git repo**), readable/editable via absolute paths. Stack:
- **Fastify 5** (TypeScript) with **`@fastify/websocket` already registered**; working WS route pattern in `src/routes/chat.ts` (`fastify.get("/chat", { websocket: true }, …)`).
- **`@fastify/jwt`** auth (`src/routes/auth.ts`), CORS/helmet.
- **Drizzle ORM → PostgreSQL**, 26 tables, schema at `src/db/schema/index.ts`.
- Docker/deploy scripts present.

## Topology
```
Flutter client (kinship-app)
  ├─ offline → LocalSession  → in-app PokerGame            (unchanged)
  └─ online  → RemoteSession → WS → Dart game-service      (authoritative)

Dart game-service (NEW): hosts PokerGame per room, per-player views,
    turn clock, AI backfill (reuses AiBrain). Validates Node-signed JWT.

Node backend (mmosh-backend-node): REST lobby/matchmaking, JWT, Drizzle/pg
    (rooms, seats, results). Client connects to the game-service WS directly,
    presenting a token minted by Node.
```

**De-risking insight:** the throwaway sims already written for the engine *are* headless drivers of `PokerGame`. The server's game loop is a productionized version of that sim loop, with one new seam — a **`PlayerAgent`** interface:
- `human` → send a network prompt, await response with a timeout
- `AI` → call `AiBrain`

Offline stays exactly as-is; the server driver is new code modeled on the proven sim patterns.

---

## Phases

### Phase 0 — Foundations & contracts ✅ DONE (2026-08)
- ✅ Extracted the engine into a **shared pure-Dart package** at
  `kinship-app/packages/medieval_poker_engine/` (lib/src/ = the 8 engine files;
  barrel `medieval_poker_engine.dart`). No Flutter dep. App depends on it via a
  path dependency; the 5 Flame consumers import the barrel. Offline unchanged.
  Verified: `dart analyze` clean, app `flutter analyze` clean, and a headless
  `dart run` smoke test resolved 5/5 games (proves it runs server-side).
- ✅ Drafted the **wire protocol** as a separate shared library
  `package:medieval_poker_engine/protocol.dart` (lib/src/protocol/):
  - `card_code.dart` — compact card encoding (`As`, `WILD`, `I:<id>`, `??`).
  - `snapshot.dart` — `TableSnapshot` / `SeatSnapshot` / `PowerCardView` /
    `ItemView` (the per-player `serializeFor` output shape; opponents' hole
    cards carried as `??`).
  - `prompt.dart` — `PromptSpec` / `PromptKind` (all ~15 interactive windows) /
    `PromptOption`.
  - `messages.dart` — `ClientMessage` / `ServerMessage` envelopes +
    `GameActionKind`.
  - Verified: full JSON round-trip smoke test passes.
- ⏳ JWT strategy (game-service validates Node-signed tokens) — deferred to
  Phase 1/3 when the service and lobby exist.

### Phase 1 — Dart game-service (authoritative, AI-only first) ✅ DONE (2026-08)
- WS server + room manager hosting `PokerGame` + the driver with the `PlayerAgent` seam.
- **`serializeFor(player)`** — the security core: include your hole cards / power hand / items / tokens; opponents' hole cards **hidden (count only)** except at showdown or a legitimate PEEK scoped to you; the deck is never sent.
- Server-owned **turn clock** (~30s) → timeout defaults (fold / pass / auto).
- Validate end-to-end with **all-AI rooms** driven headlessly (reuse the sim harness against the socket).

  **Delivered** in `packages/medieval_poker_service/`:
  - `serialize.dart` — `serializeFor()` builds a per-seat `TableSnapshot`; a seat's hole cards are visible iff `seat==viewer || revealSeats.contains(seat)`, else all `CardCode.hidden`. Deck never serialized.
  - `agent.dart` / `ai_agent.dart` / `remote_agent.dart` — the `PlayerAgent` seam. `AiAgent` wraps `AiBrain`; `RemoteAgent` sends a `PromptSpec` per decision and awaits the client response with `.timeout(turnTimeout)` → safe default (betting: check-if-free else fold).
  - `game_driver.dart` — the shared hand loop (setup → betting/board → showdown → settle), driving every seat through its agent; emits `onState(revealSeats)` / `onResult` / `onGameOver`.
  - `game_room.dart` — turns driver events into per-seat `ServerMessage`s via `serializeFor` (state/handResult/gameOver), scopes the log tail, exposes `levelSecondsLeft`.
  - `game_server.dart` + `bin/server.dart` — dart:io WS server (`/game?room=&seat=`, `/health`). A connecting human swaps their seat AI→`RemoteAgent`; disconnect swaps back to AI so the match never stalls. Wall-clock ante levels driven by a `Timer.periodic` (`_startLevelTimer`); Sudden Death ends the game.
  - **Verified:** `dart analyze` clean (engine + service); headless all-AI room via the real driver ran to `gameOver` with the hidden-info contract holding; end-to-end **WS smoke** (`GameServer` → real WebSocket client) reached `gameOver` over the socket with own cards visible and **zero** opponent hole-card leaks on non-`handOver` streets. App `flutter analyze` shows 0 issues in game code.

### Phase 2 — Client `RemoteSession` + HUD wiring → _first playable online table_ ✅ MOSTLY DONE (2026-08)
- Introduce a `GameSession` interface; `LocalSession` wraps today's offline path; `RemoteSession` = WS client.
- Route the HUD's data source + submit callbacks through the session (panels already exist — swap local completers for WS sends). Render server snapshots.
- **Milestone:** 2 humans + 2 AI in a hardcoded test room.

  **Delivered** (client stack lives in `kinship-app/lib/games/medieval_poker/`):
  - `session/game_session.dart` — the UI-facing `GameSession` seam: `ValueListenable`s for `phase`/`table`/`prompt`/`handResult`/`gameOver`/`peek` + `viewerSeat` + `answer(kind, payload)` + `dispose()`. View-models `HandResultView`/`GameOverView`/`StandingView`. The renderer + HUD bind ONLY to this — never to an engine or socket.
  - `session/remote_session.dart` — `RemoteSession implements GameSession` over `web_socket_channel` (already an app dep; no server-package coupling). Parses `welcome`/`state`/`resync`/`prompt`/`reveal`/`handResult`/`gameOver`/`pong` into notifiers; `answer` sends a `ClientMessage` action referencing the live promptId and optimistically clears the prompt; heartbeat timer; connect via `RemoteSession.connect(wsUrl, room, seat)`. Transport-agnostic core (`incoming` stream + `send` sink) so it's unit-testable with no socket (`RemoteSession.debug`).
  - `flame/components/card_component.dart` — added `applyCode(String?)` so a card renders from a wire `CardCode` (`??` → face-down back). Offline path untouched.
  - `flame/components/snapshot_seat_component.dart` — renders one seat from a `SeatSnapshot` (a card is face-up iff its code ≠ `??` — the server decides visibility). Visual twin of the offline `SeatComponent`.
  - `flame/table_renderer.dart` — `TableRenderer extends FlameGame` that renders purely from `session.table` (no engine): builds seats on the first snapshot, viewer at the bottom, others spread across the top arc; board + pot from the snapshot.
  - `session/session_hud.dart` — `SessionHud` bound to a `GameSession`: banner/stage/pot/log/power-hand-fan/peek from `table`; maps every one of the 15 `PromptKind`s to a panel (betting bar, power/counter/board/item card-lists, item mode/pick lists, target picker, pay/chip-sell two-button, class/court overlays, deck-builder); win/lose flash with self-dismiss (decoupled from snapshot cadence); game-over + connection overlays.
  - `medieval_poker_online_screen.dart` — hosts `RemoteSession` + `TableRenderer` + `SessionHud`. Launchable from the debug sandbox ("Online test room": WS URL + room + seat 0–3).
  - **Server support:** `GameServer` gained `humansToStart` (default 1) so a hardcoded room waits for both humans before setup — so both get class/court/deck prompts (proper ready-up is Phase 3).
  - **Verified:** `packages/medieval_poker_service/tool/two_humans_smoke.dart` — 2 scripted human WS clients (seats 0/1) + AI backfill (2/3) play to `gameOver`; both receive class/court/deck + betting prompts; own cards always visible; **zero** opponent leaks on non-`handOver` streets. App `flutter analyze` clean across the game code; `test/medieval_poker/remote_session_test.dart` (8 tests) covers parse + answer-serialization over an in-memory channel.
  - **Deferred to a follow-up (needs on-device iteration):** (1) ~~`LocalSession`~~ → **DONE (2026-08), see below.** (2) ~~State pacing/animation~~ → **DONE (2026-08), see below.** (3) On-device visual pass of the online table.

### Deferred-item: client-side state pacing ✅ DONE (2026-08)
The authoritative driver has no pacing, so AI-only runs (opponent actions, board deals, showdown) arrived back-to-back and blurred past on the online table. Fixed with a **`GameSession` decorator** `session/paced_session.dart` `PacedSession`:
- Buffers the wrapped session's `table` snapshots and releases them one at a time no faster than `minInterval` (default 350ms), so each change lingers a beat; **fast-forwards** (drops stale intermediate frames past a `backlogCap`) if it falls too far behind.
- **Flushes to the latest snapshot immediately on a `prompt`**, so the human always acts on current information.
- **Withholds the win/lose flash + game-over** until the queued run-out has drained, then holds `resultHold` (default 2.4s) so the outcome reads clearly.
- `phase`/`prompt`/`peek` pass straight through; `answer`/`dispose` delegate (dispose also disposes the inner session). Reusable for a future `LocalSession`.
- Wired in `medieval_poker_online_screen.dart` (`PacedSession(RemoteSession.connect(...))`); renderer/HUD unchanged (they bind to `GameSession`). Verified by `test/medieval_poker/paced_session_test.dart` (spacing vs instant-latest, flush-on-prompt, result-after-run-out, pass-through, dispose) — `flutter test` medieval_poker suite 14/14; `flutter analyze` clean.

### Deferred-item: LocalSession — offline through the unified seam ✅ DONE (2026-08)
The offline game now runs through the **same** `GameSession` seam as online, so one renderer + one HUD + one authoritative driver serve both modes.
- **Relocation** — the transport-agnostic core (`serialize`, `agent`, `ai_agent`, `game_driver`, `remote_agent`) moved from the service package into the **engine** as `package:medieval_poker_engine/service.dart`. The service package now holds only the dart:io transport (`game_room`, `game_server`, `bin`) and re-exports the core. This lets the app drive an in-process authoritative game with **zero client→server-package coupling**. Its barrel re-exports the engine core, so the service tools/imports are unchanged. All engine+service analysis clean; all 5 service smokes still green.
- `session/local_session.dart` `LocalSession implements GameSession` — builds a `PokerGame` (human seat 0 + AI opponents), runs the shared `GameDriver` with `AiAgent` opponents and a **loopback `RemoteAgent`** for the human (its prompts become `prompt`; `answer` feeds `onResponse`), and wires `onState`/`onResult`/`onGameOver` + engine `onPeek` + a wall-clock level timer into the session notifiers. `revealAll` (sandbox) reveals all seats; no turn clock (6h loopback timeout).
- **Bug fixed in the shared core:** `RemoteAgent._ask` dereferenced `_pending!` *after* sending, which crashed when a loopback sink completes the response synchronously (offline). Now it captures the result future before sending — correct for both the async socket and the sync loopback. (Online smokes re-verified.)
- **HUD parity:** `SessionHud` gained an optional **Play Again** (offline) on game-over and a self-contained **Rules** reference overlay (useful online too).
- `medieval_poker_local_screen.dart` = `PacedSession(LocalSession(...))` → shared `TableRenderer` + `SessionHud`, with screen-level Play Again (recreates the session + renderer). Launched from the sandbox ("Start — Unified UI (beta)"). **The legacy Flame `MedievalPokerScreen` remains the default offline entry** (zero regression) pending an on-device pass.
- **Verified:** `test/medieval_poker/local_session_test.dart` drives a full offline game through the seam to `gameOver` by auto-answering prompts — own cards visible, **zero** opponent leaks before showdown, all setup prompts fired; medieval_poker suite 15/15; analyze clean.
- **Parity gaps before it can replace the default:** the in-game **Power Deck viewer** (needs a snapshot extension or an offline-only hook — the snapshot intentionally omits draw-deck contents), the "cut for the deal" banner, and an on-device visual/UX pass. Class/court/deck-build, all power/item/court windows, PEEK toasts, status badges, reveal-all, results, game-over, and Play Again all work through the seam.

### Phase 3 — Lobby v1 (Node): friends-only invite rooms ✅ DONE (2026-08)
- REST: create room → `{ code, gameToken, wsUrl }`, join by code, ready-up, leave.
- `game_rooms` / `game_seats` Drizzle tables. Client create/join lobby screen.

  **Delivered — Node backend** (`kinship/plugin/kinship-backend`, Fastify 5 + Drizzle/postgres.js):
  - `src/db/schema/games.ts` — `game_rooms` (id, code unique, game, status `lobby|active|finished`, seat_count, config jsonb, ws_url, created_by, timestamps), `game_seats` (id, room_id, seat, user_id?, is_ai, ready, joined_at; unique(room_id,seat) + room index), `game_results` (id, room_id, standings jsonb, winner_user_id, ended_at — for Phase 6). Re-exported from `schema/index.ts`.
  - Migration `drizzle/0006_medieval_poker_lobby.sql` — generated via drizzle-kit, then **hand-scoped to only the three game tables**: the generator also emitted `CREATE TABLE "agents"` because `agents` is pre-existing schema↔migration drift (in `schema/agents.ts` but absent from the 0005 snapshot; never captured in any migration). Creating it as a side effect of the lobby could break `migrate` on a DB that already has it, so it was removed from the SQL; the 0006 snapshot still carries `agents`, so this doesn't re-introduce the drift. **Flagged for the team to reconcile separately.**
  - `src/routes/games.ts` (mounted at `/games`, all `fastify.authenticate`): `POST /rooms` (host takes seat 0), `POST /rooms/:code/join` (claims first open seat, idempotent), `POST /rooms/:code/ready {ready}`, `POST /rooms/:code/start` (host-only; requires all occupied seats ready → flips empty seats to AI + status `active`), `POST /rooms/:code/leave`, `GET /rooms/:code` (poll), `GET /rooms` (caller's active rooms). Mints a short-lived game ticket (`fastify.jwt.sign({typ:'game',roomId,code,seat,userId}, {expiresIn:'3h'})`); `wsUrl` from `GAME_SERVICE_WS_URL` (default `ws://localhost:8080/game`); room view returns a `humans` count for the start-gate hint. Registered in `app.ts`.
  - **Verified:** `tsc --noEmit` shows only the 11 pre-existing `payload.ts` errors — **zero** from the lobby; migration generated + scoped. (No DB in this env, so runtime SQL not executed.)

  **Delivered — game-service bridge** (Dart, `medieval_poker_service`): `GameServer` now honors a `?humans=N` WS query hint that raises a room's per-room start threshold, so a lobby-created multi-human room waits for everyone before setup (so all humans get class/court/deck prompts). Verified by the updated `tool/two_humans_smoke.dart` (server default `humansToStart:1`; clients pass `humans=2` → game correctly waits for both).

  **Delivered — Flutter client** (`kinship-app/lib/games/medieval_poker/`):
  - `session/lobby_client.dart` — `LobbyClient` over the app's `DioClient()` (targets `BACKEND_URL`, auto-attaches the bearer token). Models `LobbyRoom`/`LobbySeat`/`LobbyTicket`; methods create/join/ready/start/leave/getRoom; `LobbyException` surfaces server `err()` messages.
  - `medieval_poker_lobby_screen.dart` — create or join-by-code, seat list with 2s polling, ready toggle, host Start; on `status:active` hands off to `MedievalPokerOnlineScreen(wsUrl, room:code, seat, humans, token)`. Launchable from the debug sandbox ("Multiplayer lobby").
  - `RemoteSession.connect` + `MedievalPokerOnlineScreen` gained optional `humans` + `token`, forwarded on the WS query (`&humans=&token=`; the service uses `humans` now and will use `token` once it validates tickets).
  - **Verified:** `flutter analyze` clean across the game code; `RemoteSession` tests still 8/8.

  **Deferred / open:** (1) the Dart game-service does not yet **validate** the lobby's `gameToken` (accepts any socket) — token verification (shared `JWT_SECRET`, HS256) is the security follow-up (Phase 4/security). (2) `GAME_SERVICE_WS_URL` + a real game-service **deploy target** must be set for non-local use (open item #1). (3) Lobby→service room **config** (seat count, timed levels) is not yet passed to the service (it uses its construction defaults); carrying it in the validated token is the clean path. (4) Variable seat counts on the service (fixed at 4).

### Phase 4 — Robustness ✅ DONE (2026-08)
- Reconnection token + resync; disconnect **grace period → AI takeover** (reclaim seat + stack on return); heartbeats; room teardown.

  **Delivered — game-service** (`medieval_poker_service`):
  - **Token auth** — `src/game_token.dart` `GameTokenVerifier` validates the lobby's HS256 ticket (`crypto` dep): signature over `header.payload` with the shared `JWT_SECRET`, `exp`, `typ=='game'`, and `code`/`seat` binding. `GameServer(jwtSecret: …)` rejects the WS upgrade (401) unless a valid seat/room-bound ticket is presented; **omit the secret → open dev mode** (any socket, any seat). `bin/server.dart` reads `GAME_JWT_SECRET ?? JWT_SECRET`. **This closes the Phase-3 security gap.**
  - **Reconnection + resync + grace** — `RemoteAgent` refactored to attach/detach a socket and re-send its outstanding prompt on reattach. On disconnect the seat is **detached, not forfeited** (the turn clock still prevents stalls); a `graceDuration` (default 20s) timer hands the seat to AI only if no reconnect arrives. On reconnect the same seat re-attaches (or reclaims from AI), the client gets an immediate `resync` (full snapshot, own cards visible) plus any pending prompt — stack/cards are the untouched `PokerPlayer`, so the seat is reclaimed intact. A superseded socket's late close is ignored. Contention guard: a live seat owned by a different `userId` can't be kicked.
  - **Teardown** — abandoned, never-started rooms are reaped after `emptyRoomTimeout` (default 60s); all per-room timers are cancelled on game-over/teardown.
  - **Heartbeats** — client heartbeat → server `pong` (already present).
  - **Verified (real sockets, dart run):** `tool/token_test.dart` (verifier: accept valid; reject tamper/wrong-secret/expiry/type/garbage), `tool/auth_smoke.dart` (server rejects no/bad/wrong-secret/seat-mismatch upgrades, admits a valid ticket), `tool/reconnect_smoke.dart` (drop mid-game → reconnect → `resync` + own cards → seat reclaimed → play to gameOver, no leaks), and the `tool/two_humans_smoke.dart` regression still green. `dart analyze` clean (engine + service).

  **Delivered — client** (`RemoteSession`): auto-reconnect with exponential backoff (1→16s, 5 attempts) — rebuilds the WS channel on an unexpected drop, shows `connecting`, clears stale prompts, and repaints from the `resync`; a clean `gameOver` does not reconnect. Reconnect state machine covered by a `flutter test` (`debugReconnectable`); `RemoteSession` suite now 9/9; `flutter analyze` clean across game code.

  **Reconnection token:** the lobby's `gameToken` **is** the reconnection token — a client reconnects by re-presenting it (seat+room+userId bound, 3h TTL). No separate token needed.

  **Open:** (1) leaving a lobby seat doesn't invalidate an already-minted ticket (a stale ticket could reclaim a since-freed seat if the new owner isn't connected) — minor, needs a revocation/nonce check. (2) An all-AI in-progress room still plays to completion with nobody watching (per-seat grace covers players; no whole-room mid-run abort). (3) Lobby→service room config still not passed (carry in the validated token).

### Phase 5 — Public matchmaking (v2) ✅ DONE (2026-08)
- "Find Game" queue + auto-fill 4 seats; partial-table handling; AI backfill.

  **Delivered — Node backend:**
  - `src/db/schema/games.ts` — `matchmaking_queue` (id, user_id unique, game, status `waiting|matched`, room_id?, seat?, enqueued_at; lookup index on game+status+enqueued_at). Migration `drizzle/0007_matchmaking_queue.sql` (clean — only the new table; the 0006 snapshot fix kept `agents` from reappearing).
  - `src/matchmaking/plan.ts` — **pure** `planMatch(waiting, now, {size, maxWaitMs})`: a full table (≥4) forms immediately with no AI; otherwise once the *oldest* waiter passes `maxWaitMs` (15s) it forms a partial table with everyone present + AI-fills the rest; else keep waiting. No DB/IO → unit-tested standalone.
  - `src/routes/games.ts` — `POST/GET/DELETE /games/queue` (enqueue / poll / cancel). A transactional `runMatch()` (row-locked `SELECT … FOR UPDATE SKIP LOCKED` so concurrent callers don't double-match) applies the plan: creates an **`active`** room + seats (matched humans + AI backfill), flips the queue rows to `matched` with their room/seat. Matching runs opportunistically on enqueue and on each waiting poll (the poll also drives the partial-table timeout — no background worker needed). The status poll mints each player's game ticket on read and returns `{room, seat, gameToken, wsUrl}`. tsc: only the 11 pre-existing `payload.ts` errors.
  - **Verified:** `planMatch` logic test (full / partial-timeout / solo / empty) run via Playwright's bundled node + tsx.

  **Delivered — game-service:** `GameServer.startDeadline` — a matchmade room announced for N humans still **force-starts** with whoever's present once the deadline elapses (so a no-show can't hang the table); `bin/server.dart` defaults it to 30s (`GAME_START_DEADLINE_SECONDS`). Start logic refactored into `_maybeStart(force)`. Verified by `tool/start_deadline_smoke.dart` (1 of 2 announced humans → force-starts + finishes); `two_humans` / `reconnect` regressions still green; `dart analyze` clean.

  **Delivered — client:** `LobbyClient.enqueue/queueStatus/leaveQueue` + `QueueStatus` model; `medieval_poker_matchmaking_screen.dart` (enqueue → poll every 2s → on `matched` `pushReplacement` to the online table; Cancel dequeues; best-effort dequeue on dispose). Launched from a "Find a Public Game" button on the lobby entry view. `flutter analyze` clean across the game code.

  **Open:** (1) concurrent matchers using SKIP LOCKED can each form a smaller partial table under load — fine at low volume, revisit for scale. (2) Stale `matched` queue rows are cleared on the user's next enqueue but not otherwise reaped (a cron sweep is a Phase-6 nicety). (3) Same lobby→service room-config gap as Phase 3/4.

### Phase 6 — Polish & scale ✅ DONE (2026-08)
- Results/history + optional leaderboard; anti-cheat audit log; Redis pub/sub _only if_ multi-instance; latency/load testing.

  **Delivered — results/history/leaderboard** (written from the trusted game-service, never clients):
  - Backend schema `player_stats` (userId PK, games, wins) + `game_results` gained `game`, `participant_ids` (jsonb, for history lookups) and a unique `room_id` (idempotent). Migration `drizzle/0008_game_stats.sql` (scoped: creates player_stats, alters game_results).
  - `POST /games/internal/result` — server-to-server (guarded by `GAME_SERVICE_SECRET` header, **not** user auth; idempotent per room): writes `game_results`, upserts `player_stats` (games++/wins+= via `onConflictDoUpdate`), marks the room `finished`, frees the players' queue rows. `GET /games/leaderboard` (top 20 by wins, joined to users), `GET /games/stats` (caller's aggregate), `GET /games/history` (caller's recent games via `participant_ids @> [uid]`). tsc: only the 11 pre-existing `payload.ts` errors.
  - Game-service: `GameServer.resultReporter` + per-room `seatUserIds` (kept across AI takeovers) → on game-over builds a `GameResultReport {roomCode, winnerSeat, seats:[{seat,userId?,isAi,stack}]}` and reports it (best-effort). `bin/server.dart` wires a dart:io HTTP reporter to `$KINSHIP_BACKEND_URL/games/internal/result` with the shared secret (off unless configured).
  - Client: `LobbyClient.leaderboard()/myStats()` + `LeaderboardEntry`/`PlayerStats`; `medieval_poker_leaderboard_screen.dart` (own record + top players), opened from a trophy action on the lobby.

  **Delivered — load/soak testing:** `tool/load_smoke.dart` runs **8 concurrent 4-human rooms** (32 sockets) to completion, asserting every room finishes, **zero** hole-card leaks under load, and that the result reporter fires exactly once per room with a coherent winner (holds the largest stack) — verified in-process (an injected reporter stands in for the backend). Ran clean in ~2.3s. Full service smoke suite (token/auth/reconnect/start-deadline/two-humans/load) green.

  **Explicitly scoped out (per the plan's conditions):**
  - **Redis pub/sub** — "only if multi-instance." The game-service is single-instance (live state in memory); a shared bus is premature. Revisit when horizontal scaling is actually needed.
  - **Anti-cheat audit log** — deferred. The server-authoritative design + the verified no-leak `serializeFor` already close the core threat (clients never receive others' secrets); a per-action audit trail is a future add for dispute review.

**Cross-cutting throughout:** hidden-info tests (a player's snapshot must never contain an opponent's hole cards except at showdown or a legit PEEK), multi-client integration tests, and keep the offline sims green.

---

## Protocol sketch (Phase 0 deliverable)

### Client → server
- `join` `{ roomId, gameToken }`
- `action` `{ seq, promptId, kind, payload }` where `kind` ∈:
  - betting: `check | call | fold | bet(to) | raise(to)`
  - `playPower(cardId, target?)`, `pass`
  - `counter(cardId)`, `showdown(cardId)`, `boardCounter(cardId)`
  - `playItem(id, mode?, pick?)`, `payChoice(bool)`, `sellChip(bool)`
  - `targetPick(idx)`, `classPick(idx)`, `courtPick(idx)`, `deckBuild(ids)`
- `heartbeat`

### Server → client
- `state` — per-player snapshot: masked seats/board, pot, stage + level clock, **your** hole cards / power hand / items / tokens / comp chips, recent log tail.
- `prompt` `{ promptId, kind, options, deadlineMs }` — "your decision now".
- `reveal` — showdown (all hole cards) or a PEEK reveal scoped to the recipient.
- `handResult`, `gameOver`, `error`, `resync`.

Server rules: accept an `action` only from the acting player for the matching `promptId`; validate legality; on timeout/disconnect apply the default action.

### `serializeFor(player)` contract
- **Always visible to `player`:** own hole cards, own power hand, own items/tokens, own comp chips, public board, pot, stage/clock, all players' stacks + status badges (HOT/TILT/chips/tokens counts) + last action.
- **Hidden from `player`:** every other player's hole cards (send count only), the deck, other players' power hands/items contents.
- **Exceptions (reveal):** showdown reveals contesting hands; a PEEK effect reveals a specific opponent's card(s) **only to the peeking player**.

### Prompt surface to protocolize
Betting action · Setup / Round / Counter / Showdown windows · board-counter · target pick · item mode + card pick · pay-with-chip · chip sell · class pick · court pick · deck-build. Each: `prompt → response → timeout default`.

---

## Persistence (Node / Drizzle / pg)
- `game_rooms` (id, code, status, config JSON, created_by, created_at)
- `game_seats` (room_id, seat, user_id?, is_ai, joined_at)
- _(optional, later)_ `game_results` (room_id, standings JSON, winner_id, ended_at) for history / leaderboard.
- Live per-hand state lives in the **game-service memory** (real-time, single instance); Node persists lobby + results, not per-hand state.

## Repo boundaries (2–3 repos to coordinate)
- **kinship-app** — shared engine package + client `GameSession`/`RemoteSession` + lobby UI.
- **game-service** — new Dart package/folder (in studio, or its own repo).
- **mmosh-backend-node** (`plugin/kinship-backend`) — REST lobby/matchmaking + tables.

## Open items (deferrable past Phase 0)
1. **Deploy target for the Dart game-service** — new runtime; needs its own container/deploy (backend already has Docker).
2. **Repo layout** for the game-service (studio vs own repo).
3. **Game token** — full JWT vs short-lived room ticket minted by Node.

## Biggest risks
- **Hidden-info integrity** — the client holds full engine state offline (fine); in remote mode it must *only* receive its own secrets. Drives the `serializeFor` design + tests.
- **Prompt surface** — ~10 interactive windows to protocolize with timeouts/defaults.
- **Engine divergence** — avoided by the shared package (not re-porting to TS).

## Recommended start
**Phase 0** — extract the engine into a shared package and pin down the protocol/snapshot models. Low risk, offline untouched, prerequisite for both the service and the client refactor.

---

## Migration: run the game *through* the Node backend (bundled Dart service) — PLAN (2026-08)

**Decision (Option A):** Node **supervises** the Dart game-service as a child process and **reverse-proxies** its WebSocket, so operators run/deploy **one thing** (Node) and clients only ever hit the Node backend (`:6050`). Keeps the **single Dart rules engine** — no offline/online drift. Chosen over a full TS re-port (2 engines to maintain) and dart→JS-in-Node (interop cost).

**Target topology**
```
client ─HTTP :6050────────▶ Node  (lobby / matchmaking / results)
client ─WS   :6050/game───▶ Node reverse-proxy ─▶ 127.0.0.1:<internal>  Dart game-service (authoritative)
Dart service ─HTTP 127.0.0.1:6050/games/internal/result─▶ Node  (stats)
                              └── Dart engine reused by the Flutter offline mode too (one engine)
```

**Phases**
- **M1 — Node supervises the Dart child.** New `src/services/gameService.ts`: on boot spawn the service (dev: `dart run bin/server.dart`; prod: a `dart compile exe` binary) bound to **127.0.0.1** on an internal port; inherit `JWT_SECRET` + `GAME_SERVICE_SECRET` (so they always match Node); set `KINSHIP_BACKEND_URL=http://127.0.0.1:6050`; pipe its logs through Node's logger; supervise (restart w/ backoff); kill on shutdown. Small Dart change: `bin/server.dart` reads `GAME_SERVICE_HOST` (default `0.0.0.0`) so Node can bind it loopback-only. Wire into `index.ts` startup.
- **M2 — Reverse-proxy `/game` WS through Node.** Add `@fastify/http-proxy` (`websocket:true`, upstream `http://127.0.0.1:<internal>`, prefix `/game`) — OR a raw `upgrade`-event proxy for `/game` if it conflicts with the existing `@fastify/websocket` (`/chat`). **Flagged risk:** `/chat` (fastify-websocket) + `/game` (proxy) upgrade-handler coexistence — verify with a spike. The proxy is transparent; the Dart service still enforces the token (forwarded through).
- **M3 — Lobby returns a Node-relative wsUrl.** `gameWsUrl()` builds from the **request host/proto** (X-Forwarded-* aware) + `/game`, so the client connects back through whatever host it already used for REST — **eliminates the localhost / 10.0.2.2 / LAN-IP config pain**. `GAME_SERVICE_WS_URL` env becomes an optional override.
- **M4 — One-artifact packaging.** Multi-stage Dockerfile: build Node (tsc) + `dart compile exe` the service; final image = Node runtime + the Dart binary; Node (PID 1) spawns/supervises it. Requires the Dart SDK at build time.
- **M5 — Verify + docs.** Local: `npm run dev` brings up the Dart child; with Postgres, play a full match hitting **only :6050**. Update `ONLINE_BRINGUP.md` + memory.

**Notes / risks:** the internal Dart port must stay **loopback-only** (public surface = Node only); reconnection/grace/token/result features are unchanged (proxy is transparent) but re-test through the proxy; if the Dart child dies, in-progress matches drop (live state is in memory) and a restart brings a fresh service — same as today. Not chosen but noted: this keeps a Dart child under the hood — a true single-language/in-process move would be Option B (compile Dart→JS) or C (TS re-port).

### Migration progress — M1 + M2 + M3 DONE & verified (2026-08)
- **M1 (Node supervises the Dart child):** `kinship-backend/src/services/gameService.ts` — spawns the game-service (dev `dart run`, prod `GAME_SERVICE_BIN`), loopback (`GAME_SERVICE_HOST=127.0.0.1`), inherits `JWT_SECRET`/`GAME_SERVICE_SECRET`, sets `KINSHIP_BACKEND_URL`, pipes logs, restart-on-crash, `installShutdown`. **Orphan-reap fix:** `dart run` reparents its `dartvm` so `child.kill()`/group-kill don't reap it → added `reapPort()` (lsof-based) run before every spawn, so a restart always gets a clean port; prod should use a compiled binary (single process, clean kill — `dart compile exe`). Small Dart change: `bin/server.dart` reads `GAME_SERVICE_HOST`. Wired in `index.ts`. **Verified live:** the `:8080` game-service is a child of the running `:6050` backend and respawns when killed.
- **M2 (reverse-proxy /game):** `src/services/gameWsProxy.ts` — a raw `net` byte-passthrough for `/game` upgrades → `127.0.0.1:<port>`, wrapping (and delegating non-`/game` to) the existing `@fastify/websocket` handler. **No new dep.** **Verified live:** a WS client to `ws://localhost:6050/game` with a valid token → `welcome`; without a token → `401`; `/chat` WS still works (coexistence).
- **M3 (Node-relative wsUrl):** `gameWsUrl(req)` derives `ws(s)://<request host>/game` (X-Forwarded-* aware; `GAME_SERVICE_WS_URL` optional override). **Kills the localhost/10.0.2.2/LAN-IP config pain** — the client connects back to whatever host it used for REST. **Verified:** create room → `wsUrl` = the request host + `/game`.
- **Net:** clients hit ONLY the Node backend (`:6050`) for both REST and the game WS; the Dart engine stays authoritative and unchanged; `tsc` clean (only the 11 pre-existing `payload.ts` errors). **Still TODO:** M4 (one Docker image: Node + `dart compile exe`, Node PID 1 supervises) and an on-device run. Note: `.env.example` updated (WS URL now optional + supervisor knobs).

### M4 — one Docker image ✅ DONE & verified (2026-08)
The whole online stack now builds + deploys as a **single image** (Node backend + the compiled Dart game-service); Node (PID 1) supervises the binary and proxies `/game` to it.
- **The two-repo problem:** the Dart source lives in the app repo, but Cloud Build's context is the backend dir. Solved with `kinship-backend/scripts/stage-game-service.sh` — before the build it `rsync`s `medieval_poker_engine` + `medieval_poker_service` (sibling layout preserved so the path dep resolves) into `./game-service/` (gitignored build artifact). `deploy.sh` / `deploy-dev.sh` run it before `gcloud builds submit`.
- **Dockerfile:** added a `FROM dart:stable AS game-service` stage that `dart pub get` + `dart compile exe bin/server.dart -o /game-service`; the runner stage `COPY --from=game-service /game-service /app/game-service` and sets `ENV GAME_SERVICE_BIN=/app/game-service`. The existing Node deps/builder/runner stages are unchanged. Only `:6050` is exposed; the game-service binds loopback inside the container. The child inherits `JWT_SECRET`/`GAME_SERVICE_SECRET` from Node's env (baked `.env`).
- **Why a compiled binary:** single process (unlike `dart run` which reparents a `dartvm`), so `child.kill()` reaps it cleanly — no orphan, no port-conflict on restart.
- **Verified with real `docker build`:** the Dart stage compiles the service inside `dart:stable`, and the resulting binary **runs on the `node:22-slim` runner base** (`/health = ok`; no Dart SDK in the final image; glibc-compatible). The full 4-stage image (incl. `npm ci`) wasn't built locally (unchanged from the proven pattern; runs in Cloud Build).
- **Deploy is unchanged for you:** `./deploy.sh` (it now stages + submits). For a manual `docker build`, run `scripts/stage-game-service.sh` first.

**Migration COMPLETE (M1–M4).** One backend to run locally (`npm run dev`) and one image to deploy; clients hit only `:6050`; the Dart engine stays the single authoritative rules engine. Remaining: an on-device end-to-end pass.

# Medieval Poker — Online bring-up runbook

Why a tap drops you straight into bots: `flow_screen.dart` wires a **tap** on the
Medieval Poker card to the offline single-player-vs-AI screen. The online modes
exist but currently live behind a **long-press** (debug sandbox), and they need
the two services below running + you signed in. There is not yet a "Play Online"
mode-picker in the main UI (deferred until this stack is deployed).

The #1 reason online didn't work when tried: **the backend process running on
:6050 predates these changes** (a `GET /games/*` probe returns 404). It must be
restarted on the current code so the `/games/*` routes + migrations load.

## What must be running
1. **Postgres** (already up in Docker on :5432 in dev).
2. **Node backend** (`kinship/plugin/kinship-backend`) — restarted on current code.
3. **Dart game-service** (`kinship-app/packages/medieval_poker_service`).
4. The **app** pointed at the backend, and you **signed in** (lobby uses your JWT).

## 1. Backend (restart on current code + migrate)
```bash
cd kinship/plugin/kinship-backend
# .env needs (see .env.example): DATABASE_URL, JWT_SECRET, and add:
#   GAME_SERVICE_WS_URL=ws://<host-reachable-from-device>:8080/game
#   GAME_SERVICE_SECRET=<shared-with-game-service>
npm run db:migrate      # applies 0006/0007/0008 (game_rooms/seats/queue/results/player_stats)
npm run dev             # tsx watch — loads the /games routes  (or: npm run build && npm start)
```
Verify the routes are live (expect **401**, not 404):
```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:6050/games/leaderboard   # 401 = good
```

## 2. Game-service
```bash
cd kinship/plugin/kinship-backend        # (or wherever) then:
cd kinship-app/packages/medieval_poker_service
JWT_SECRET=<same as backend> \
GAME_SERVICE_SECRET=<same as backend> \
KINSHIP_BACKEND_URL=http://<host>:6050 \
dart run bin/server.dart                 # listens ws://0.0.0.0:8080/game
```
- `JWT_SECRET` **must equal the backend's** — that's how the lobby ticket validates.
- Omit `JWT_SECRET` for open dev mode (any socket; no ticket required).
- `KINSHIP_BACKEND_URL` + `GAME_SERVICE_SECRET` enable end-of-game result reporting.

## 3. App config + reaching the lobby
- `kinship-app/.env` → `BACKEND_URL` must point at the backend **as the device sees it**.
- **Device networking** (applies to both `BACKEND_URL` and `GAME_SERVICE_WS_URL`):
  - iOS simulator → `localhost`
  - Android emulator → `10.0.2.2`
  - physical device → the Mac's LAN IP (e.g. `192.168.x.x`)
- **Sign in** in the app (the lobby calls use your `user_token`).
- Reach the lobby (until a real entry is added): **long-press** the Medieval Poker
  card → sandbox → **Multiplayer lobby (friends) → Open Lobby**. Create a room
  (share the code) or **Find a Public Game**; empty seats are AI-filled.

## Proven (2026-08, against a real Postgres)
The whole server side was verified end-to-end in an isolated harness:
create → join → ready → host-start (empty seats → AI) → matchmaking full-table
(transactional, `FOR UPDATE SKIP LOCKED`) → result report (idempotent, service-
secret-gated) → leaderboard / stats / history (jsonb `@>`). The lobby's
`@fastify/jwt` ticket validates in the game-service's Dart verifier. The
game-service itself passes auth / reconnection-grace / start-deadline / 2-human /
8-room-load smokes. What remains untested is only the on-device app UI itself.

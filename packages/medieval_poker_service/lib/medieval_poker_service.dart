/// Online transport for Medieval Poker: the dart:io WebSocket server that hosts
/// the shared game-service core (re-exported from the engine) per room, with a
/// per-room turn clock, auth, reconnection/grace, and AI backfill.
library;

// The transport-agnostic core now lives in the engine so it can be reused
// in-process by the app's offline LocalSession as well as by this server.
export 'package:medieval_poker_engine/service.dart';

export 'src/game_room.dart';
export 'src/game_server.dart';
export 'src/game_token.dart';
export 'src/result_report.dart';

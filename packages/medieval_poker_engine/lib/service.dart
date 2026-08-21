/// The transport-agnostic game-service core: the `PlayerAgent` seam (AI + a
/// remote/UI human), the shared `GameDriver` hand loop, and `serializeFor`
/// (per-player snapshot projection). Pure Dart — no dart:io — so it drives both
/// the online WebSocket server (`medieval_poker_service`) and the in-process
/// offline `LocalSession` in the app off exactly the same logic.
///
/// Kept separate from the main `medieval_poker_engine.dart` barrel so plain
/// engine consumers don't pull in the service concepts.
library;

export 'src/service/agent.dart';
export 'src/service/ai_agent.dart';
export 'src/service/game_driver.dart';
export 'src/service/remote_agent.dart';
export 'src/service/serialize.dart';

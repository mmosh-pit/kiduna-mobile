/// Medieval Poker online wire protocol — shared by the Flutter client and the
/// server-side game-service so both agree on message shapes.
///
/// Import separately from the engine:
///   import 'package:medieval_poker_engine/protocol.dart';
library;

export 'src/protocol/card_code.dart';
export 'src/protocol/snapshot.dart';
export 'src/protocol/prompt.dart';
export 'src/protocol/messages.dart';

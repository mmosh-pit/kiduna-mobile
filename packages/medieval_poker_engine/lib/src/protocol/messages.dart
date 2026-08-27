/// Top-level wire envelopes exchanged over the game WebSocket. All payloads are
/// plain JSON maps (see snapshot.dart / prompt.dart for their shapes).
library;

// ── Client → server ────────────────────────────────────────────────────

enum ClientMsgType { join, ready, leave, action, heartbeat }

/// The kinds of decision a client can submit in response to a prompt.
enum GameActionKind {
  check,
  call,
  fold,
  bet, // payload: {to}
  raise, // payload: {to}
  playPower, // payload: {cardId, targetSeat?}
  pass, // decline a window (setup/round/counter/showdown/board/item)
  counter, // payload: {cardId}
  showdown, // payload: {cardId}
  boardCounter, // payload: {cardId}
  playItem, // payload: {itemId, mode?, pick?}
  payChoice, // payload: {useChip}
  sellChip, // payload: {sell}
  targetPick, // payload: {seat} or {optionId}
  classPick, // payload: {index}
  courtPick, // payload: {index}
  deckBuild, // payload: {cardIds}
}

GameActionKind gameActionKindFromName(String n) =>
    GameActionKind.values.firstWhere((k) => k.name == n);

class ClientMessage {
  final ClientMsgType type;

  /// Monotonic client sequence number (for ordering / de-dupe).
  final int? seq;

  /// The prompt this message answers (for [ClientMsgType.action]).
  final String? promptId;

  final GameActionKind? actionKind;
  final Map<String, dynamic> payload;

  const ClientMessage({
    required this.type,
    this.seq,
    this.promptId,
    this.actionKind,
    this.payload = const {},
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        if (seq != null) 'seq': seq,
        if (promptId != null) 'promptId': promptId,
        if (actionKind != null) 'action': actionKind!.name,
        if (payload.isNotEmpty) 'payload': payload,
      };

  factory ClientMessage.fromJson(Map<String, dynamic> j) => ClientMessage(
        type: ClientMsgType.values.firstWhere((t) => t.name == j['type']),
        seq: j['seq'] as int?,
        promptId: j['promptId'] as String?,
        actionKind: j['action'] == null
            ? null
            : gameActionKindFromName(j['action'] as String),
        payload: (j['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

// ── Server → client ────────────────────────────────────────────────────

enum ServerMsgType {
  welcome, // handshake accepted (payload: {seat, room, seats})
  state, // payload: TableSnapshot
  prompt, // payload: PromptSpec
  reveal, // payload: {seats:[{seat, holeCards[]}], reason}  (showdown / PEEK)
  handResult, // payload: {won, detail, winners[]}
  gameOver, // payload: {winnerSeat, standings[]}
  error, // payload: {code, message}
  resync, // full state after reconnect (payload: TableSnapshot + optional prompt)
  pong,
}

class ServerMessage {
  final ServerMsgType type;

  /// Monotonic server sequence number (clients drop stale / detect gaps).
  final int? seq;

  final Map<String, dynamic> payload;

  const ServerMessage({required this.type, this.seq, this.payload = const {}});

  Map<String, dynamic> toJson() => {
        'type': type.name,
        if (seq != null) 'seq': seq,
        if (payload.isNotEmpty) 'payload': payload,
      };

  factory ServerMessage.fromJson(Map<String, dynamic> j) => ServerMessage(
        type: ServerMsgType.values.firstWhere((t) => t.name == j['type']),
        seq: j['seq'] as int?,
        payload: (j['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

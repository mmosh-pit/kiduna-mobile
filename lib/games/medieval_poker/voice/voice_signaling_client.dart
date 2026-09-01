import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Callback types for signaling events.
typedef OnVoiceJoined = void Function(int seat, String userId, String? name);
typedef OnVoiceLeft = void Function(int seat);
typedef OnVoiceMute = void Function(int seat, bool muted);
typedef OnVoiceParticipants = void Function(
    List<Map<String, dynamic>> participants);
typedef OnSignaling = void Function(
    String type, int fromSeat, Map<String, dynamic> data);

/// WebSocket client for voice signaling to kinship-backend.
///
/// Connects to `/games/voice/:code?token=` and relays WebRTC
/// signaling messages (offer/answer/ICE) between players.
class VoiceSignalingClient {
  VoiceSignalingClient({
    required this.wsUrl,
    required this.roomCode,
    required this.token,
    this.playerName,
    this.onVoiceJoined,
    this.onVoiceLeft,
    this.onVoiceMute,
    this.onVoiceParticipants,
    this.onSignaling,
    this.onError,
    this.onDisconnected,
  });

  final String wsUrl;
  final String roomCode;
  final String token;
  final String? playerName;

  final OnVoiceJoined? onVoiceJoined;
  final OnVoiceLeft? onVoiceLeft;
  final OnVoiceMute? onVoiceMute;
  final OnVoiceParticipants? onVoiceParticipants;
  final OnSignaling? onSignaling;
  final void Function(String error)? onError;
  final VoidCallback? onDisconnected;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  bool _disposed = false;

  bool get isConnected => _channel != null && !_disposed;

  /// Connect to the signaling server.
  Future<bool> connect() async {
    if (_disposed) return false;

    try {
      // Build WS URL: replace http(s) with ws(s)
      var base = wsUrl;
      if (base.startsWith('https://')) {
        base = 'wss://${base.substring(8)}';
      } else if (base.startsWith('http://')) {
        base = 'ws://${base.substring(7)}';
      } else if (!base.startsWith('ws')) {
        base = 'ws://$base';
      }
      // Remove trailing /game if present (game WS proxy path)
      if (base.endsWith('/game')) {
        base = base.substring(0, base.length - 5);
      }

      final nameParam = playerName != null && playerName!.isNotEmpty
          ? '&name=${Uri.encodeComponent(playerName!)}'
          : '';
      final uri = Uri.parse('$base/games/voice/$roomCode?token=$token$nameParam');
      print('[VoiceSignaling] Connecting to $uri');

      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _sub = _channel!.stream.listen(
        _onMessage,
        onError: (e) {
          print('[VoiceSignaling] Error: $e');
          onError?.call(e.toString());
        },
        onDone: () {
          print('[VoiceSignaling] Disconnected');
          if (!_disposed) onDisconnected?.call();
        },
      );

      print('[VoiceSignaling] Connected');
      return true;
    } catch (e) {
      print('[VoiceSignaling] Connect failed: $e');
      onError?.call('Failed to connect to voice server.');
      return false;
    }
  }

  void _onMessage(dynamic raw) {
    if (_disposed) return;
    try {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = msg['type'] as String? ?? '';

      switch (type) {
        case 'voice-participants':
          final list = (msg['participants'] as List? ?? [])
              .cast<Map<String, dynamic>>();
          onVoiceParticipants?.call(list);

        case 'voice-joined':
          onVoiceJoined?.call(
            msg['seat'] as int,
            msg['userId'] as String? ?? '',
            msg['name'] as String?,
          );

        case 'voice-left':
          onVoiceLeft?.call(msg['seat'] as int);

        case 'voice-mute':
          onVoiceMute?.call(
            msg['seat'] as int,
            msg['muted'] as bool? ?? false,
          );

        case 'offer':
        case 'answer':
        case 'ice-candidate':
          onSignaling?.call(
            type,
            msg['from'] as int? ?? -1,
            msg,
          );
      }
    } catch (e) {
      print('[VoiceSignaling] Parse error: $e');
    }
  }

  // ── Send methods ─────────────────────────────────────────────────────

  void sendMute() => _send({'type': 'mute'});
  void sendUnmute() => _send({'type': 'unmute'});

  void sendOffer(int toSeat, String sdp) => _send({
        'type': 'offer',
        'to': toSeat,
        'sdp': sdp,
      });

  void sendAnswer(int toSeat, String sdp) => _send({
        'type': 'answer',
        'to': toSeat,
        'sdp': sdp,
      });

  void sendIceCandidate(int toSeat, Map<String, dynamic> candidate) => _send({
        'type': 'ice-candidate',
        'to': toSeat,
        'candidate': candidate,
      });

  void _send(Map<String, dynamic> msg) {
    if (_disposed || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode(msg));
    } catch (e) {
      print('[VoiceSignaling] Send error: $e');
    }
  }

  /// Disconnect and cleanup.
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}

typedef VoidCallback = void Function();

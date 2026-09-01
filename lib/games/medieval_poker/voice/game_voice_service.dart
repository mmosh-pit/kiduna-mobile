import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'voice_signaling_client.dart';
import 'voice_state.dart';

/// Manages voice chat for a game room using WebRTC peer connections.
///
/// Each other player in voice gets one [RTCPeerConnection]. Audio flows
/// directly between players (peer-to-peer). The signaling server only
/// relays offer/answer/ICE — no audio passes through it.
class GameVoiceService {
  GameVoiceService({
    required this.wsUrl,
    required this.roomCode,
    required this.mySeat,
    required this.token,
    this.playerName,
  });

  final String wsUrl;
  final String roomCode;
  final int mySeat;
  final String token;
  final String? playerName;

  final state = ValueNotifier<VoiceState>(const VoiceState());

  VoiceSignalingClient? _signaling;
  MediaStream? _localStream;

  /// Seat → peer connection
  final _peers = <int, RTCPeerConnection>{};

  /// Seat → remote audio renderer
  final _remoteStreams = <int, MediaStream>{};

  /// Auto-reconnect state
  bool _wasInVoice = false;
  bool _wasMuted = false;
  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 3;
  static const _reconnectDelay = Duration(seconds: 5);
  bool _disposed = false;

  static const _iceServers = <Map<String, dynamic>>[
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
  ];

  // ── Public API ─────────────────────────────────────────────────────

  /// Join voice chat — request mic, connect signaling, set up peers.
  Future<void> join() async {
    if (state.value.joined || state.value.connecting) return;

    state.value = state.value.copyWith(connecting: true, clearError: true);

    try {
      // 1. Get microphone
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });

      // 2. Connect signaling
      _signaling = VoiceSignalingClient(
        wsUrl: wsUrl,
        roomCode: roomCode,
        token: token,
        playerName: playerName,
        onVoiceParticipants: _onParticipants,
        onVoiceJoined: _onPlayerJoined,
        onVoiceLeft: _onPlayerLeft,
        onVoiceMute: _onPlayerMute,
        onSignaling: _onSignaling,
        onError: (e) {
          state.value = state.value.copyWith(error: e);
        },
        onDisconnected: _onSignalingDisconnected,
      );

      final connected = await _signaling!.connect();
      if (!connected) {
        _localStream?.dispose();
        _localStream = null;
        state.value = const VoiceState(
          error: 'Could not connect to voice server.',
        );
        return;
      }

      // Track for auto-reconnect
      _wasInVoice = true;
      _wasMuted = false;
      _reconnectAttempts = 0;

      state.value = state.value.copyWith(
        joined: true,
        connecting: false,
        muted: false,
      );

      print('[GameVoice] Joined voice chat — seat=$mySeat');
    } catch (e) {
      _localStream?.dispose();
      _localStream = null;
      state.value = VoiceState(error: 'Mic access failed: $e');
      print('[GameVoice] Join failed: $e');
    }
  }

  /// Leave voice chat — close all connections.
  void leave() {
    print('[GameVoice] Leaving voice chat');
    _wasInVoice = false; // Manual leave — don't auto-reconnect
    _cleanup();
    state.value = const VoiceState();
  }

  /// Mute local microphone.
  void mute() {
    _setLocalAudioEnabled(false);
    _signaling?.sendMute();
    state.value = state.value.copyWith(muted: true);
  }

  /// Unmute local microphone.
  void unmute() {
    _setLocalAudioEnabled(true);
    _signaling?.sendUnmute();
    state.value = state.value.copyWith(muted: false);
  }

  /// Turn speaker off — mute all incoming audio.
  void speakerOff() {
    _setAllRemoteAudioEnabled(false);
    state.value = state.value.copyWith(speakerOff: true);
  }

  /// Turn speaker on — unmute all incoming audio (except individually muted).
  void speakerOn() {
    _setAllRemoteAudioEnabled(true);
    // Re-apply individual mutes
    for (final seat in state.value.mutedUsers) {
      _setRemoteAudioEnabled(seat, false);
    }
    state.value = state.value.copyWith(speakerOff: false);
  }

  /// Mute a specific user's audio (local only — they don't know).
  void muteUser(int seat) {
    _setRemoteAudioEnabled(seat, false);
    final updated = Set<int>.from(state.value.mutedUsers)..add(seat);
    state.value = state.value.copyWith(mutedUsers: updated);
  }

  /// Unmute a specific user's audio.
  void unmuteUser(int seat) {
    _setRemoteAudioEnabled(seat, true);
    final updated = Set<int>.from(state.value.mutedUsers)..remove(seat);
    state.value = state.value.copyWith(mutedUsers: updated);
  }

  /// Dispose everything.
  void dispose() {
    _disposed = true;
    _wasInVoice = false;
    _cleanup();
    state.dispose();
  }

  // ── Auto-reconnect ──────────────────────────────────────────────────

  bool _reconnecting = false;

  void _onSignalingDisconnected() {
    if (_disposed) {
      print('[GameVoice] Disconnected but disposed — ignoring');
      return;
    }
    if (!_wasInVoice) {
      print('[GameVoice] Disconnected but wasInVoice=false — ignoring');
      return;
    }
    if (_reconnecting) {
      print('[GameVoice] Disconnected during reconnect — ignoring');
      return;
    }

    print('[GameVoice] Disconnected — starting auto-reconnect');

    // Save mute state before cleanup
    _wasMuted = state.value.muted;

    // Close peer connections but keep local stream
    for (final pc in _peers.values) {
      pc.close();
    }
    _peers.clear();
    _remoteStreams.clear();
    _signaling = null; // Don't dispose — already disconnected

    state.value = state.value.copyWith(
      connecting: true,
      error: null,
      participants: const {},
    );

    _attemptReconnect();
  }

  Future<void> _attemptReconnect() async {
    if (_disposed || !_wasInVoice) return;

    _reconnecting = true;
    _reconnectAttempts++;

    if (_reconnectAttempts > _maxReconnectAttempts) {
      print('[GameVoice] Auto-reconnect failed after $_maxReconnectAttempts attempts');
      _reconnecting = false;
      _wasInVoice = false;
      _localStream?.dispose();
      _localStream = null;
      state.value = const VoiceState(
        error: 'Voice disconnected. Tap Join Voice to reconnect.',
      );
      return;
    }

    print('[GameVoice] Reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts — waiting ${_reconnectDelay.inSeconds}s');

    // Wait before retry
    await Future.delayed(_reconnectDelay);
    if (_disposed || !_wasInVoice) {
      _reconnecting = false;
      return;
    }

    print('[GameVoice] Reconnecting now...');

    try {
      // Get mic again if lost
      if (_localStream == null) {
        print('[GameVoice] Re-acquiring microphone');
        _localStream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': false,
        });
      }

      // Reconnect signaling
      final signaling = VoiceSignalingClient(
        wsUrl: wsUrl,
        roomCode: roomCode,
        token: token,
        playerName: playerName,
        onVoiceParticipants: _onParticipants,
        onVoiceJoined: _onPlayerJoined,
        onVoiceLeft: _onPlayerLeft,
        onVoiceMute: _onPlayerMute,
        onSignaling: _onSignaling,
        onError: (e) {
          print('[GameVoice] Signaling error during reconnect: $e');
        },
        onDisconnected: _onSignalingDisconnected,
      );

      final connected = await signaling.connect();

      if (!connected) {
        print('[GameVoice] Reconnect attempt $_reconnectAttempts — signaling failed');
        signaling.dispose();
        _reconnecting = false;
        _attemptReconnect();
        return;
      }

      if (_disposed || !_wasInVoice) {
        signaling.dispose();
        _reconnecting = false;
        return;
      }

      _signaling = signaling;

      // Reconnected successfully
      _reconnectAttempts = 0;
      _reconnecting = false;

      // Restore mute state
      if (_wasMuted) {
        _setLocalAudioEnabled(false);
        _signaling?.sendMute();
      }

      state.value = state.value.copyWith(
        joined: true,
        connecting: false,
        muted: _wasMuted,
        clearError: true,
      );

      print('[GameVoice] Auto-reconnected successfully!');
    } catch (e) {
      print('[GameVoice] Reconnect attempt $_reconnectAttempts error: $e');
      _signaling?.dispose();
      _signaling = null;
      _reconnecting = false;
      _attemptReconnect();
    }
  }

  // ── Signaling callbacks ────────────────────────────────────────────

  void _onParticipants(List<Map<String, dynamic>> list) {
    final participants = <int, VoiceParticipant>{};
    for (final p in list) {
      final seat = p['seat'] as int;
      if (seat == mySeat) continue;
      participants[seat] = VoiceParticipant(
        seat: seat,
        userId: p['userId'] as String? ?? '',
        muted: p['muted'] as bool? ?? false,
        name: p['name'] as String?,
      );
      _createPeerForSeat(seat, createOffer: true);
    }
    state.value = state.value.copyWith(participants: participants);
  }

  void _onPlayerJoined(int seat, String userId, String? name) {
    if (seat == mySeat) return;
    final updated = Map<int, VoiceParticipant>.from(state.value.participants);
    updated[seat] = VoiceParticipant(seat: seat, userId: userId, name: name);
    state.value = state.value.copyWith(participants: updated);

    // New player joined — they will send us an offer (we wait)
    print('[GameVoice] Player joined voice — seat=$seat');
  }

  void _onPlayerLeft(int seat) {
    final updated = Map<int, VoiceParticipant>.from(state.value.participants);
    updated.remove(seat);
    state.value = state.value.copyWith(participants: updated);

    // Close peer connection
    _closePeer(seat);
    print('[GameVoice] Player left voice — seat=$seat');
  }

  void _onPlayerMute(int seat, bool muted) {
    final updated = Map<int, VoiceParticipant>.from(state.value.participants);
    final p = updated[seat];
    if (p != null) {
      updated[seat] = p.copyWith(muted: muted);
      state.value = state.value.copyWith(participants: updated);
    }
  }

  Future<void> _onSignaling(
      String type, int fromSeat, Map<String, dynamic> data) async {
    switch (type) {
      case 'offer':
        await _handleOffer(fromSeat, data['sdp'] as String);
      case 'answer':
        await _handleAnswer(fromSeat, data['sdp'] as String);
      case 'ice-candidate':
        await _handleIceCandidate(
            fromSeat, data['candidate'] as Map<String, dynamic>);
    }
  }

  // ── WebRTC peer management ─────────────────────────────────────────

  Future<RTCPeerConnection> _createPeerForSeat(
    int seat, {
    bool createOffer = false,
  }) async {
    // Close existing peer if any
    await _closePeer(seat);

    final pc = await createPeerConnection({
      'iceServers': _iceServers,
    });

    _peers[seat] = pc;

    // Add local audio tracks
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    }

    // Handle remote tracks
    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStreams[seat] = event.streams[0];
        print('[GameVoice] Receiving audio from seat=$seat');
      }
    };

    // Handle ICE candidates
    pc.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _signaling?.sendIceCandidate(seat, {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    pc.onIceConnectionState = (iceState) {
      print('[GameVoice] ICE state for seat=$seat: $iceState');
    };

    // Create offer if we're the initiator
    if (createOffer) {
      final offer = await pc.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false,
      });
      await pc.setLocalDescription(offer);
      _signaling?.sendOffer(seat, offer.sdp!);
      print('[GameVoice] Sent offer to seat=$seat');
    }

    return pc;
  }

  Future<void> _handleOffer(int fromSeat, String sdp) async {
    print('[GameVoice] Received offer from seat=$fromSeat');
    final pc = await _createPeerForSeat(fromSeat);
    await pc.setRemoteDescription(
        RTCSessionDescription(sdp, 'offer'));

    final answer = await pc.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });
    await pc.setLocalDescription(answer);
    _signaling?.sendAnswer(fromSeat, answer.sdp!);
    print('[GameVoice] Sent answer to seat=$fromSeat');
  }

  Future<void> _handleAnswer(int fromSeat, String sdp) async {
    print('[GameVoice] Received answer from seat=$fromSeat');
    final pc = _peers[fromSeat];
    if (pc == null) return;
    await pc.setRemoteDescription(
        RTCSessionDescription(sdp, 'answer'));
  }

  Future<void> _handleIceCandidate(
      int fromSeat, Map<String, dynamic> data) async {
    final pc = _peers[fromSeat];
    if (pc == null) return;
    await pc.addCandidate(RTCIceCandidate(
      data['candidate'] as String?,
      data['sdpMid'] as String?,
      data['sdpMLineIndex'] as int?,
    ));
  }

  Future<void> _closePeer(int seat) async {
    final pc = _peers.remove(seat);
    if (pc != null) {
      await pc.close();
    }
    _remoteStreams.remove(seat);
  }

  // ── Helpers ────────────────────────────────────────────────────────

  void _setLocalAudioEnabled(bool enabled) {
    if (_localStream == null) return;
    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = enabled;
    }
  }

  /// Enable/disable audio from a specific remote peer.
  void _setRemoteAudioEnabled(int seat, bool enabled) {
    final stream = _remoteStreams[seat];
    if (stream == null) return;
    for (final track in stream.getAudioTracks()) {
      track.enabled = enabled;
    }
  }

  /// Enable/disable ALL remote audio.
  void _setAllRemoteAudioEnabled(bool enabled) {
    for (final stream in _remoteStreams.values) {
      for (final track in stream.getAudioTracks()) {
        track.enabled = enabled;
      }
    }
  }

  void _cleanup() {
    // Close all peers
    for (final pc in _peers.values) {
      pc.close();
    }
    _peers.clear();
    _remoteStreams.clear();

    // Stop local stream
    _localStream?.dispose();
    _localStream = null;

    // Disconnect signaling
    _signaling?.dispose();
    _signaling = null;
  }
}

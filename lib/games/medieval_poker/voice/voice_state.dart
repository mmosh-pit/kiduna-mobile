import 'package:flutter/foundation.dart';

/// One player in the voice chat.
class VoiceParticipant {
  final int seat;
  final String userId;
  final bool muted;

  const VoiceParticipant({
    required this.seat,
    required this.userId,
    this.muted = false,
  });

  VoiceParticipant copyWith({bool? muted}) => VoiceParticipant(
        seat: seat,
        userId: userId,
        muted: muted ?? this.muted,
      );
}

/// Current voice chat state for the local player.
@immutable
class VoiceState {
  const VoiceState({
    this.joined = false,
    this.muted = false,
    this.connecting = false,
    this.error,
    this.participants = const {},
  });

  /// Whether the local player has joined voice chat.
  final bool joined;

  /// Whether the local player's mic is muted.
  final bool muted;

  /// Whether we're currently connecting.
  final bool connecting;

  /// Error message, if any.
  final String? error;

  /// All players currently in voice chat (seat → participant).
  final Map<int, VoiceParticipant> participants;

  VoiceState copyWith({
    bool? joined,
    bool? muted,
    bool? connecting,
    String? error,
    bool clearError = false,
    Map<int, VoiceParticipant>? participants,
  }) =>
      VoiceState(
        joined: joined ?? this.joined,
        muted: muted ?? this.muted,
        connecting: connecting ?? this.connecting,
        error: clearError ? null : (error ?? this.error),
        participants: participants ?? this.participants,
      );
}

import 'package:flutter/foundation.dart';

/// One player in the voice chat.
class VoiceParticipant {
  final int seat;
  final String userId;
  final bool muted;
  final String? name;

  const VoiceParticipant({
    required this.seat,
    required this.userId,
    this.muted = false,
    this.name,
  });

  VoiceParticipant copyWith({bool? muted, String? name}) => VoiceParticipant(
        seat: seat,
        userId: userId,
        muted: muted ?? this.muted,
        name: name ?? this.name,
      );
}

/// Current voice chat state for the local player.
@immutable
class VoiceState {
  const VoiceState({
    this.joined = false,
    this.muted = false,
    this.speakerOff = false,
    this.connecting = false,
    this.error,
    this.participants = const {},
    this.mutedUsers = const {},
  });

  /// Whether the local player has joined voice chat.
  final bool joined;

  /// Whether the local player's mic is muted.
  final bool muted;

  /// Whether the speaker is off (all incoming audio muted).
  final bool speakerOff;

  /// Whether we're currently connecting.
  final bool connecting;

  /// Error message, if any.
  final String? error;

  /// All players currently in voice chat (seat → participant).
  final Map<int, VoiceParticipant> participants;

  /// Seats whose audio we've individually muted (local only).
  final Set<int> mutedUsers;

  /// Check if a specific user is muted by us.
  bool isUserMuted(int seat) => mutedUsers.contains(seat);

  VoiceState copyWith({
    bool? joined,
    bool? muted,
    bool? speakerOff,
    bool? connecting,
    String? error,
    bool clearError = false,
    Map<int, VoiceParticipant>? participants,
    Set<int>? mutedUsers,
  }) =>
      VoiceState(
        joined: joined ?? this.joined,
        muted: muted ?? this.muted,
        speakerOff: speakerOff ?? this.speakerOff,
        connecting: connecting ?? this.connecting,
        error: clearError ? null : (error ?? this.error),
        participants: participants ?? this.participants,
        mutedUsers: mutedUsers ?? this.mutedUsers,
      );
}

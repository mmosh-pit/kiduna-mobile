import 'package:flutter/material.dart';

import 'game_voice_service.dart';
import 'voice_state.dart';

/// Voice chat controls overlay for the game screen.
///
/// Shows a join button when not in voice, or mute/leave controls when joined.
/// Positioned by the parent (typically bottom-left of the game screen).
class VoiceControls extends StatelessWidget {
  const VoiceControls({super.key, required this.voiceService});

  final GameVoiceService voiceService;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VoiceState>(
      valueListenable: voiceService.state,
      builder: (context, state, _) {
        if (state.connecting) {
          return _Container(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Connecting...',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          );
        }

        if (!state.joined) {
          return _JoinButton(
            onPressed: voiceService.join,
            error: state.error,
          );
        }

        return _ActiveControls(
          muted: state.muted,
          participantCount: state.participants.length,
          onMuteToggle: state.muted ? voiceService.unmute : voiceService.mute,
          onLeave: voiceService.leave,
        );
      },
    );
  }
}

class _Container extends StatelessWidget {
  const _Container({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: child,
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({required this.onPressed, this.error});
  final Future<void> Function() onPressed;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Container(
          child: InkWell(
            onTap: onPressed,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mic, size: 18, color: Colors.white70),
                SizedBox(width: 6),
                Text(
                  'Join Voice',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              error!,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActiveControls extends StatelessWidget {
  const _ActiveControls({
    required this.muted,
    required this.participantCount,
    required this.onMuteToggle,
    required this.onLeave,
  });

  final bool muted;
  final int participantCount;
  final VoidCallback onMuteToggle;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return _Container(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Participant count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, size: 12, color: Color(0xFF4CAF50)),
                const SizedBox(width: 3),
                Text(
                  '${participantCount + 1}', // +1 for self
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Mute/unmute toggle
          InkWell(
            onTap: onMuteToggle,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: muted
                    ? Colors.red.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
              ),
              child: Icon(
                muted ? Icons.mic_off : Icons.mic,
                size: 16,
                color: muted ? Colors.red : const Color(0xFF4CAF50),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Leave button
          InkWell(
            onTap: onLeave,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withValues(alpha: 0.2),
              ),
              child: const Icon(
                Icons.call_end,
                size: 16,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small indicator for a seat showing voice status.
class VoiceSeatIndicator extends StatelessWidget {
  const VoiceSeatIndicator({super.key, required this.participant});

  final VoiceParticipant? participant;

  @override
  Widget build(BuildContext context) {
    if (participant == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.6),
      ),
      child: Icon(
        participant!.muted ? Icons.mic_off : Icons.mic,
        size: 12,
        color: participant!.muted ? Colors.red : const Color(0xFF4CAF50),
      ),
    );
  }
}

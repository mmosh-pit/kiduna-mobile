import 'package:flutter/material.dart';

import 'game_voice_service.dart';
import 'voice_state.dart';

/// Voice chat controls overlay for the game screen.
class VoiceControls extends StatelessWidget {
  const VoiceControls({super.key, required this.voiceService});

  final GameVoiceService voiceService;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VoiceState>(
      valueListenable: voiceService.state,
      builder: (context, state, _) {
        if (state.connecting) {
          return const _ConnectingIndicator();
        }

        if (!state.joined) {
          return _JoinButton(
            onPressed: voiceService.join,
            error: state.error,
          );
        }

        return _ActiveVoicePanel(
          state: state,
          mySeat: voiceService.mySeat,
          onMuteToggle: state.muted ? voiceService.unmute : voiceService.mute,
          onSpeakerToggle:
              state.speakerOff ? voiceService.speakerOn : voiceService.speakerOff,
          onMuteUser: (seat) {
            if (state.isUserMuted(seat)) {
              voiceService.unmuteUser(seat);
            } else {
              voiceService.muteUser(seat);
            }
          },
          onLeave: voiceService.leave,
        );
      },
    );
  }
}

// ── Connecting ─────────────────────────────────────────────────────────

class _ConnectingIndicator extends StatefulWidget {
  const _ConnectingIndicator();
  @override
  State<_ConnectingIndicator> createState() => _ConnectingIndicatorState();
}

class _ConnectingIndicatorState extends State<_ConnectingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.5, end: 1.0).animate(_pulse),
      child: _Pill(
        color: Colors.black87,
        borderColor: const Color(0xFFEDC169).withValues(alpha: 0.4),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5, color: Color(0xFFEDC169),
              ),
            ),
            SizedBox(width: 8),
            Text('Connecting...', style: TextStyle(
              color: Color(0xFFEDC169), fontSize: 11, fontWeight: FontWeight.w500,
            )),
          ],
        ),
      ),
    );
  }
}

// ── Join button ────────────────────────────────────────────────────────

class _JoinButton extends StatefulWidget {
  const _JoinButton({required this.onPressed, this.error});
  final Future<void> Function() onPressed;
  final String? error;
  @override
  State<_JoinButton> createState() => _JoinButtonState();
}

class _JoinButtonState extends State<_JoinButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() { _glow.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _glow,
          builder: (context, child) => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50)
                      .withValues(alpha: 0.15 + _glow.value * 0.15),
                  blurRadius: 12, spreadRadius: 1,
                ),
              ],
            ),
            child: child,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(22),
              child: _Pill(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                borderColor: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.headset_mic, size: 16, color: Color(0xFF4CAF50)),
                    SizedBox(width: 6),
                    Text('Join Voice', style: TextStyle(
                      color: Color(0xFF4CAF50), fontSize: 12,
                      fontWeight: FontWeight.w600, letterSpacing: 0.3,
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.error != null) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxWidth: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(widget.error!,
                style: const TextStyle(color: Colors.white, fontSize: 10)),
          ),
        ],
      ],
    );
  }
}

// ── Active voice panel ─────────────────────────────────────────────────

class _ActiveVoicePanel extends StatelessWidget {
  const _ActiveVoicePanel({
    required this.state,
    required this.mySeat,
    required this.onMuteToggle,
    required this.onSpeakerToggle,
    required this.onMuteUser,
    required this.onLeave,
  });

  final VoiceState state;
  final int mySeat;
  final VoidCallback onMuteToggle;
  final VoidCallback onSpeakerToggle;
  final void Function(int seat) onMuteUser;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                const _LiveDot(),
                const SizedBox(width: 6),
                Text(
                  'Voice Chat · ${state.participants.length + 1}',
                  style: const TextStyle(
                    color: Colors.white70, fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Leave button
                _MiniButton(
                  onTap: onLeave,
                  icon: Icons.call_end_rounded,
                  color: const Color(0xFFEF5350),
                  bgColor: const Color(0xFFEF5350).withValues(alpha: 0.2),
                  size: 22,
                ),
              ],
            ),
          ),

          // ── Participant list ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Self
                _ParticipantTile(
                  label: 'You',
                  isSelf: true,
                  micMuted: state.muted,
                  locallyMuted: false,
                  onMuteToggle: null,
                ),
                // Others
                for (final p in state.participants.values)
                  _ParticipantTile(
                    label: p.name ?? 'Seat ${p.seat + 1}',
                    isSelf: false,
                    micMuted: p.muted,
                    locallyMuted: state.isUserMuted(p.seat),
                    onMuteToggle: () => onMuteUser(p.seat),
                  ),
              ],
            ),
          ),

          // ── Controls bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(13)),
            ),
            child: Row(
              children: [
                // Mic toggle
                Expanded(
                  child: _ControlButton(
                    onTap: onMuteToggle,
                    icon: state.muted
                        ? Icons.mic_off_rounded
                        : Icons.mic_rounded,
                    color: state.muted
                        ? const Color(0xFFEF5350)
                        : const Color(0xFF4CAF50),
                    bgColor: state.muted
                        ? const Color(0xFFEF5350).withValues(alpha: 0.2)
                        : const Color(0xFF4CAF50).withValues(alpha: 0.15),
                    label: state.muted ? 'Unmute' : 'Mute',
                  ),
                ),
                const SizedBox(width: 6),
                // Speaker toggle
                Expanded(
                  child: _ControlButton(
                    onTap: onSpeakerToggle,
                    icon: state.speakerOff
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    color: state.speakerOff
                        ? const Color(0xFFEF5350)
                        : const Color(0xFF64B5F6),
                    bgColor: state.speakerOff
                        ? const Color(0xFFEF5350).withValues(alpha: 0.2)
                        : const Color(0xFF64B5F6).withValues(alpha: 0.15),
                    label: state.speakerOff ? 'On' : 'Off',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Participant tile ───────────────────────────────────────────────────

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.label,
    required this.isSelf,
    required this.micMuted,
    required this.locallyMuted,
    this.onMuteToggle,
  });

  final String label;
  final bool isSelf;
  final bool micMuted;
  final bool locallyMuted;
  final VoidCallback? onMuteToggle;

  @override
  Widget build(BuildContext context) {
    final nameColor = isSelf
        ? const Color(0xFFEDC169)
        : locallyMuted
            ? Colors.white38
            : Colors.white70;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Mic status icon
          Icon(
            micMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            size: 13,
            color: micMuted
                ? const Color(0xFFEF5350).withValues(alpha: 0.7)
                : const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 6),
          // Name
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: nameColor,
                fontSize: 11,
                fontWeight: isSelf ? FontWeight.w600 : FontWeight.w400,
                decoration: locallyMuted ? TextDecoration.lineThrough : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Per-user mute button (not for self)
          if (!isSelf)
            _MiniButton(
              onTap: onMuteToggle,
              icon: locallyMuted
                  ? Icons.volume_off_rounded
                  : Icons.volume_up_rounded,
              color: locallyMuted
                  ? const Color(0xFFEF5350)
                  : Colors.white38,
              bgColor: locallyMuted
                  ? const Color(0xFFEF5350).withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              size: 20,
            ),
        ],
      ),
    );
  }
}

// ── Live dot ───────────────────────────────────────────────────────────

class _LiveDot extends StatefulWidget {
  const _LiveDot();
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF4CAF50),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50)
                  .withValues(alpha: 0.3 + _pulse.value * 0.4),
              blurRadius: 4 + _pulse.value * 4,
              spreadRadius: _pulse.value * 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Control button (with label) ────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.onTap,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.label,
  });

  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w600,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mini button ────────────────────────────────────────────────────────

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    this.onTap,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.size = 24,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
          child: Icon(icon, size: size * 0.6, color: color),
        ),
      ),
    );
  }
}

// ── Pill container ─────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  const _Pill({required this.child, required this.color, required this.borderColor});
  final Widget child;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: child,
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
        border: Border.all(
          color: participant!.muted
              ? const Color(0xFFEF5350).withValues(alpha: 0.5)
              : const Color(0xFF4CAF50).withValues(alpha: 0.5),
        ),
      ),
      child: Icon(
        participant!.muted ? Icons.mic_off_rounded : Icons.mic_rounded,
        size: 12,
        color: participant!.muted ? const Color(0xFFEF5350) : const Color(0xFF4CAF50),
      ),
    );
  }
}

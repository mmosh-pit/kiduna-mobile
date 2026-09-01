import 'package:flutter/material.dart';

import 'game_voice_service.dart';
import 'voice_state.dart';

/// Voice chat controls overlay for the game screen.
///
/// Shows a join button when not in voice, or mute/leave controls + participant
/// list when joined. Positioned by the parent (typically bottom-left).
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
          muted: state.muted,
          mySeat: voiceService.mySeat,
          participants: state.participants,
          onMuteToggle: state.muted ? voiceService.unmute : voiceService.mute,
          onLeave: voiceService.leave,
        );
      },
    );
  }
}

// ── Connecting indicator ───────────────────────────────────────────────

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
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.5, end: 1.0).animate(_pulse),
      child: _Pill(
        color: Colors.white10,
        borderColor: Colors.white24,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0xFFEDC169),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Connecting...',
              style: TextStyle(
                color: Color(0xFFEDC169),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
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
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _glow,
          builder: (context, child) {
            final glowOpacity = 0.15 + (_glow.value * 0.15);
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withValues(alpha: glowOpacity),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: child,
            );
          },
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
                    Text(
                      'Join Voice',
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
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
            child: Text(
              widget.error!,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Active voice panel ─────────────────────────────────────────────────

class _ActiveVoicePanel extends StatelessWidget {
  const _ActiveVoicePanel({
    required this.muted,
    required this.mySeat,
    required this.participants,
    required this.onMuteToggle,
    required this.onLeave,
  });

  final bool muted;
  final int mySeat;
  final Map<int, VoiceParticipant> participants;
  final VoidCallback onMuteToggle;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Participant avatars ──
        _ParticipantRow(
          mySeat: mySeat,
          myMuted: muted,
          participants: participants,
        ),
        const SizedBox(height: 6),

        // ── Controls row ──
        _Pill(
          color: Colors.black.withValues(alpha: 0.75),
          borderColor: const Color(0xFF4CAF50).withValues(alpha: 0.3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live indicator
              const _LiveDot(),
              const SizedBox(width: 6),
              Text(
                '${participants.length + 1} in voice',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),

              // Mute button
              _ControlButton(
                onTap: onMuteToggle,
                icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                color: muted ? const Color(0xFFEF5350) : const Color(0xFF4CAF50),
                bgColor: muted
                    ? const Color(0xFFEF5350).withValues(alpha: 0.2)
                    : const Color(0xFF4CAF50).withValues(alpha: 0.15),
                tooltip: muted ? 'Unmute' : 'Mute',
              ),
              const SizedBox(width: 6),

              // Leave button
              _ControlButton(
                onTap: onLeave,
                icon: Icons.call_end_rounded,
                color: const Color(0xFFEF5350),
                bgColor: const Color(0xFFEF5350).withValues(alpha: 0.2),
                tooltip: 'Leave voice',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Participant row (avatars + names) ──────────────────────────────────

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.mySeat,
    required this.myMuted,
    required this.participants,
  });

  final int mySeat;
  final bool myMuted;
  final Map<int, VoiceParticipant> participants;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        // Self
        _ParticipantChip(
          label: 'You',
          muted: myMuted,
          isSelf: true,
        ),
        // Others
        for (final p in participants.values)
          _ParticipantChip(
            label: p.name ?? 'Seat ${p.seat + 1}',
            muted: p.muted,
            isSelf: false,
          ),
      ],
    );
  }
}

class _ParticipantChip extends StatefulWidget {
  const _ParticipantChip({
    required this.label,
    required this.muted,
    required this.isSelf,
  });

  final String label;
  final bool muted;
  final bool isSelf;

  @override
  State<_ParticipantChip> createState() => _ParticipantChipState();
}

class _ParticipantChipState extends State<_ParticipantChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _speakPulse;

  @override
  void initState() {
    super.initState();
    _speakPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (!widget.muted) _speakPulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_ParticipantChip old) {
    super.didUpdateWidget(old);
    if (widget.muted && _speakPulse.isAnimating) {
      _speakPulse.stop();
      _speakPulse.value = 0;
    } else if (!widget.muted && !_speakPulse.isAnimating) {
      _speakPulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _speakPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final micColor = widget.muted
        ? const Color(0xFFEF5350)
        : const Color(0xFF4CAF50);

    return AnimatedBuilder(
      animation: _speakPulse,
      builder: (context, child) {
        final borderOpacity = widget.muted ? 0.3 : (0.3 + _speakPulse.value * 0.4);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: micColor.withValues(alpha: borderOpacity),
              width: widget.muted ? 1 : 1.5,
            ),
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.muted ? Icons.mic_off_rounded : Icons.mic_rounded,
            size: 11,
            color: micColor,
          ),
          const SizedBox(width: 4),
          Text(
            widget.label,
            style: TextStyle(
              color: widget.isSelf
                  ? const Color(0xFFEDC169)
                  : Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Live dot (pulsing green) ───────────────────────────────────────────

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
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4CAF50),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.3 + _pulse.value * 0.4),
                blurRadius: 4 + _pulse.value * 4,
                spreadRadius: _pulse.value * 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Control button ─────────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.onTap,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.tooltip,
  });

  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

// ── Shared pill container ──────────────────────────────────────────────

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

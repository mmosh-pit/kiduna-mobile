import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// Premium countdown timer with large digit boxes, gradient accents,
/// and subtle glow effects. Ticks every second.
class PresaleCountdown extends StatefulWidget {
  const PresaleCountdown({
    super.key,
    required this.targetDate,
    required this.label,
  });

  final String targetDate;
  final String label;

  @override
  State<PresaleCountdown> createState() => _PresaleCountdownState();
}

class _PresaleCountdownState extends State<PresaleCountdown> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final target = DateTime.tryParse(widget.targetDate);
    if (target == null) return;
    final now = DateTime.now().toUtc();
    setState(() {
      _remaining = target.difference(now);
      if (_remaining.isNegative) _remaining = Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final ended = _remaining == Duration.zero;

    if (ended) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.muted.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Ended',
          style: context.kidunaText.label.copyWith(color: colors.muted),
        ),
      );
    }

    final days = _remaining.inDays;
    final hours = _remaining.inHours.remainder(24);
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    final isEnds = widget.label.toLowerCase().contains('end');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: context.kidunaText.micro.copyWith(
            color: colors.quiet,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _DigitBox(
              value: days,
              label: 'DAYS',
              accentColor: isEnds ? colors.sky : colors.gold,
            ),
            _Colon(),
            _DigitBox(
              value: hours,
              label: 'HRS',
              accentColor: isEnds ? colors.sky : colors.gold,
            ),
            _Colon(),
            _DigitBox(
              value: minutes,
              label: 'MIN',
              accentColor: isEnds ? colors.sky : colors.gold,
            ),
            _Colon(),
            _DigitBox(
              value: seconds,
              label: 'SEC',
              accentColor: isEnds ? colors.sky : colors.gold,
              isSeconds: true,
            ),
          ],
        ),
      ],
    );
  }
}

/// Single digit box — gradient background, accent top edge, bold number.
class _DigitBox extends StatelessWidget {
  const _DigitBox({
    required this.value,
    required this.label,
    required this.accentColor,
    this.isSeconds = false,
  });

  final int value;
  final String label;
  final Color accentColor;
  final bool isSeconds;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Container(
      width: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accentColor.withValues(alpha: 0.06),
            colors.deep,
          ],
        ),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.04),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top accent line ──
          Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 8),
          // ── Number ──
          Text(
            value.toString().padLeft(2, '0'),
            style: context.kidunaText.heading.copyWith(
              color: colors.cream,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          // ── Label ──
          Text(
            label,
            style: context.kidunaText.micro.copyWith(
              color: colors.quiet,
              fontSize: 8,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Animated colon separator.
class _Colon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        width: 16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ColonDot(),
            const SizedBox(height: 6),
            _ColonDot(),
          ],
        ),
      ),
    );
  }
}

class _ColonDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.kiduna.quiet.withValues(alpha: 0.6),
      ),
    );
  }
}

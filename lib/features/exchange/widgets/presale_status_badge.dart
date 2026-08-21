import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// Colour-coded status chip with a pulsing dot for live presales.
///
/// * `live`      → mint with pulsing dot
/// * `upcoming`  → camel/gold
/// * `completed` → muted
class PresaleStatusBadge extends StatefulWidget {
  const PresaleStatusBadge({super.key, required this.status});

  final String status;

  @override
  State<PresaleStatusBadge> createState() => _PresaleStatusBadgeState();
}

class _PresaleStatusBadgeState extends State<PresaleStatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool get _isLive => widget.status.toLowerCase() == 'live';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_isLive) _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final (bg, fg) = _resolveColors(colors);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLive) ...[
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) {
                return Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fg.withValues(alpha: _pulseAnimation.value),
                    boxShadow: [
                      BoxShadow(
                        color: fg.withValues(alpha: _pulseAnimation.value * 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
          ],
          Text(
            widget.status.toUpperCase(),
            style: context.kidunaText.micro.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  (Color bg, Color fg) _resolveColors(dynamic colors) {
    switch (widget.status.toLowerCase()) {
      case 'live':
        return (colors.mint.withValues(alpha: 0.12), colors.mint);
      case 'upcoming':
        return (colors.gold.withValues(alpha: 0.10), colors.gold);
      case 'completed':
        return (colors.muted.withValues(alpha: 0.10), colors.muted);
      default:
        return (colors.muted.withValues(alpha: 0.10), colors.muted);
    }
  }
}

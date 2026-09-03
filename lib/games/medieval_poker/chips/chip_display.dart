import 'package:flutter/material.dart';

import 'chip_model.dart';

/// Renders a chip image from assets.
class ChipIcon extends StatelessWidget {
  const ChipIcon({super.key, required this.type, this.size = 28});
  final ChipType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      type.asset,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// Shows a chip stack: one chip image with count.
class ChipStackWidget extends StatelessWidget {
  const ChipStackWidget({super.key, required this.stack, this.chipSize = 24});
  final ChipStack stack;
  final double chipSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChipIcon(type: stack.type, size: chipSize),
        const SizedBox(width: 3),
        Text(
          '×${stack.count}',
          style: TextStyle(
            color: stack.type.color,
            fontSize: chipSize * 0.45,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Full chip display: gem chip images + total number.
class ChipDisplay extends StatelessWidget {
  const ChipDisplay({super.key, required this.total, this.chipSize = 22, this.compact = false});
  final int total;
  final double chipSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final stacks = breakdownChips(total);
    final visible = stacks.take(3).toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          ChipStackWidget(stack: visible[i], chipSize: chipSize),
        ],
        if (!compact) ...[
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: chipSize * 0.7,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(width: 8),
        ] else
          const SizedBox(width: 6),
        Text(
          _formatNumber(total),
          style: TextStyle(
            color: const Color(0xFFEDC169),
            fontSize: compact ? chipSize * 0.5 : chipSize * 0.6,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    return '$n';
  }
}

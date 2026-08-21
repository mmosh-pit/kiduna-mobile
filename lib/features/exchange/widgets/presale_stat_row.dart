import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// A single key–value row used in presale cards and detail views.
///
/// Label on the left (muted), value on the right (cream or custom colour).
/// Consistent 32px height across all stat rows.
class PresaleStatRow extends StatelessWidget {
  const PresaleStatRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  /// Stat label (e.g. "Price", "Min Purchase").
  final String label;

  /// Stat value (e.g. "\$0.01", "10 USDC").
  final String value;

  /// Override for value text colour. Defaults to cream.
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final textStyle = context.kidunaText.bodySm;

    return SizedBox(
      height: 32,
      child: Row(
        children: [
          Text(label, style: textStyle.copyWith(color: colors.muted)),
          const Spacer(),
          Text(
            value,
            style: textStyle.copyWith(color: valueColor ?? colors.cream),
          ),
        ],
      ),
    );
  }
}

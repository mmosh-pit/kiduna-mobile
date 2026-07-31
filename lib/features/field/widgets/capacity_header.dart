import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// Shared header for all five capacity workspace panels.
/// Eyebrow (sky, uppercase) + heading (cream, Goudy) + status (muted, right).
class CapacityHeader extends StatelessWidget {
  const CapacityHeader({
    super.key,
    required this.eyebrow,
    required this.heading,
    required this.status,
  });

  final String eyebrow;
  final String heading;
  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.camel.withValues(alpha: 0.14)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: text.micro.copyWith(
                    color: colors.sky,
                    fontWeight: FontWeight.w700,
                    fontSize: 8,
                    letterSpacing: 0.16 * 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  heading,
                  style: text.h4.copyWith(
                    color: colors.cream,
                    fontSize: 21,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Flexible(
            child: Text(
              status,
              textAlign: TextAlign.right,
              style: text.micro.copyWith(color: colors.muted, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}

/// A row in an asset/skill list: name + classification on left, action buttons
/// on right.
class AssetRow extends StatelessWidget {
  const AssetRow({
    super.key,
    required this.name,
    required this.detail,
    required this.actions,
  });

  final String name;
  final String detail;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(6, 3, 4, 0.36),
        border: Border.all(color: colors.camel.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: text.label.copyWith(
                    color: colors.cream,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(detail, style: text.micro.copyWith(color: colors.quiet)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(spacing: 5, children: actions),
        ],
      ),
    );
  }
}

/// Small sky-outlined action button used in capacity panels.
class CapacityActionButton extends StatelessWidget {
  const CapacityActionButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 28),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        foregroundColor: colors.sky,
        backgroundColor: colors.sky.withValues(alpha: 0.045),
        side: BorderSide(color: colors.sky.withValues(alpha: 0.22)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        textStyle: context.kidunaText.micro,
      ),
      child: Text(label),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// Token identity header — circular logo, token name, and symbol.
///
/// Used in both [PresaleCard] and [PresaleDetailView]. The logo loads from
/// [metadataUri] if available; otherwise shows a placeholder with the first
/// letter of the symbol.
class PresaleTokenHeader extends StatelessWidget {
  const PresaleTokenHeader({
    super.key,
    required this.name,
    required this.symbol,
    this.metadataUri,
    this.logoSize = 40,
  });

  final String name;
  final String symbol;
  final String? metadataUri;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Row(
      children: [
        // ── Logo ──
        _TokenLogo(
          symbol: symbol,
          metadataUri: metadataUri,
          size: logoSize,
        ),
        const SizedBox(width: 12),
        // ── Name + Symbol ──
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: context.kidunaText.label.copyWith(color: colors.cream),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                symbol,
                style: context.kidunaText.micro.copyWith(color: colors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Circular token logo. Attempts to load the image from the metadata URI's
/// image field. Falls back to a styled letter placeholder.
class _TokenLogo extends StatelessWidget {
  const _TokenLogo({
    required this.symbol,
    required this.metadataUri,
    required this.size,
  });

  final String symbol;
  final String? metadataUri;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.raised,
        border: Border.all(
          color: colors.line,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          symbol.isNotEmpty ? symbol[0] : '?',
          style: context.kidunaText.label.copyWith(
            color: colors.gold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}

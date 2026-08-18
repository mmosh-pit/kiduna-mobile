import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../models/scene_mock_data.dart';

/// Play Store style horizontal list row — large rounded icon on the left,
/// name + category + description in the middle, action button on the right.
class SceneCard extends StatefulWidget {
  const SceneCard({
    super.key,
    required this.scene,
    required this.onTap,
  });

  final SceneMockItem scene;
  final VoidCallback onTap;

  @override
  State<SceneCard> createState() => _SceneCardState();
}

class _SceneCardState extends State<SceneCard> {
  bool _hovered = false;

  Color _accent(dynamic colors) {
    switch (widget.scene.category) {
      case 'productivity': return colors.sky;
      case 'game':         return colors.gold;
      case 'wellness':     return colors.mint;
      case 'finance':      return colors.camel;
      case 'lifestyle':    return colors.quiet;
      default:             return colors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final s = widget.scene;
    final accent = _accent(colors);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _hovered ? colors.raised : Colors.transparent,
            border: Border.all(
              color: _hovered
                  ? colors.camel.withValues(alpha: 0.2)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              // ── Large icon ──
              _AppIcon(icon: s.icon, iconUrl: s.iconUrl, accent: accent),
              const SizedBox(width: 16),

              // ── Info ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      s.name,
                      style: context.kidunaText.label.copyWith(
                        color: colors.cream,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Category + rating
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          s.categoryLabel,
                          style: context.kidunaText.micro.copyWith(
                            color: colors.quiet,
                            fontSize: 11,
                          ),
                        ),
                        if (s.isAvailable) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.star_rounded,
                              size: 11, color: colors.gold),
                          const SizedBox(width: 2),
                          Text(
                            '4.5',
                            style: context.kidunaText.micro.copyWith(
                              color: colors.gold.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Description
                    Text(
                      s.description,
                      style: context.kidunaText.micro.copyWith(
                        color: colors.muted,
                        fontSize: 11,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // ── Action button ──
              _ActionButton(isAvailable: s.isAvailable, accent: accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// Large rounded-square app icon (56px) — Play Store style.
class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.icon, required this.accent, this.iconUrl});

  final IconData icon;
  final Color accent;
  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: accent.withValues(alpha: 0.08),
        border: Border.all(
          color: accent.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: iconUrl != null
            ? Image.network(
                iconUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(icon, size: 26, color: accent),
              )
            : Icon(icon, size: 26, color: accent),
      ),
    );
  }
}

/// Play Store style action button — "Install" / "Open" / "Soon".
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.isAvailable, required this.accent});

  final bool isAvailable;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    if (!isAvailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.camel.withValues(alpha: 0.25)),
        ),
        child: Text(
          'Soon',
          style: context.kidunaText.micro.copyWith(
            color: colors.camel,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: accent.withValues(alpha: 0.15),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Text(
        'Open',
        style: context.kidunaText.micro.copyWith(
          color: accent,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

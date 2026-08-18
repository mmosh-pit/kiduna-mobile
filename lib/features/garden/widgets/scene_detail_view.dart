import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../models/scene_mock_data.dart';
import 'scene_category_badge.dart';

/// Play Store style detail page — large hero icon, metadata row,
/// description, screenshots placeholder, info section, action button.
class SceneDetailView extends StatelessWidget {
  const SceneDetailView({
    super.key,
    required this.scene,
    required this.onBack,
  });

  final SceneMockItem scene;
  final VoidCallback onBack;

  Color _accent(dynamic colors) {
    switch (scene.category) {
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
    final accent = _accent(colors);

    return Column(
      children: [
        // ── Top bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 16, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: Icon(Icons.arrow_back_rounded, color: colors.cream),
                style: IconButton.styleFrom(
                  backgroundColor: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: colors.line),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  scene.name,
                  style: context.kidunaText.heading.copyWith(
                    color: colors.cream,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // ── Body ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══ Hero: Icon + Meta ═══
                _HeroSection(scene: scene, accent: accent),
                const SizedBox(height: 20),

                // ═══ Action bar ═══
                _ActionBar(scene: scene, accent: accent),
                const SizedBox(height: 20),

                // ═══ Screenshots placeholder ═══
                _ScreenshotsSection(accent: accent, imageUrls: scene.imageUrls),
                const SizedBox(height: 20),

                // ═══ About ═══
                _AboutSection(scene: scene, accent: accent),
                const SizedBox(height: 20),

                // ═══ Info table ═══
                _InfoSection(scene: scene, accent: accent),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Hero — large icon + name + category + stats row.
class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.scene, required this.accent});

  final SceneMockItem scene;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Large icon ──
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: accent.withValues(alpha: 0.08),
            border: Border.all(color: accent.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.08),
                blurRadius: 16,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: scene.iconUrl != null
                ? Image.network(
                    scene.iconUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(scene.icon, size: 36, color: accent),
                  )
                : Icon(scene.icon, size: 36, color: accent),
          ),
        ),
        const SizedBox(width: 16),

        // ── Info ──
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                scene.name,
                style: context.kidunaText.labelStrong.copyWith(
                  color: colors.cream,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              SceneCategoryBadge(category: scene.category),
              const SizedBox(height: 10),
              // Stats row
              Row(
                children: [
                  _StatPill(
                    icon: Icons.star_rounded,
                    value: scene.isAvailable ? '4.5' : '—',
                    color: colors.gold,
                  ),
                  const SizedBox(width: 10),
                  _StatPill(
                    icon: Icons.download_rounded,
                    value: scene.isAvailable ? '1K+' : '—',
                    color: colors.muted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Small stat pill (rating, downloads, size).
class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: context.kidunaText.micro.copyWith(
            color: color,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// Full-width action bar — Install/Open or Coming Soon.
class _ActionBar extends StatefulWidget {
  const _ActionBar({required this.scene, required this.accent});

  final SceneMockItem scene;
  final Color accent;

  @override
  State<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends State<_ActionBar> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    if (!widget.scene.isAvailable) {
      return Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.camel.withValues(alpha: 0.25)),
          color: colors.camel.withValues(alpha: 0.06),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule_rounded, size: 16, color: colors.camel),
              const SizedBox(width: 8),
              Text(
                'Coming Soon',
                style: context.kidunaText.label.copyWith(
                  color: colors.camel,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Launching ${widget.scene.name}...'),
            backgroundColor: widget.accent,
          ),
        );
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: widget.accent,
          boxShadow: [
            BoxShadow(
              color: widget.accent.withValues(alpha: _pressed ? 0.15 : 0.3),
              blurRadius: _pressed ? 8 : 16,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        transform: Matrix4.identity()..scale(_pressed ? 0.98 : 1.0),
        transformAlignment: Alignment.center,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow_rounded, size: 18,
                  color: colors.skyButtonInk),
              const SizedBox(width: 6),
              Text(
                'Open',
                style: context.kidunaText.labelStrong.copyWith(
                  color: colors.skyButtonInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gallery / screenshots section — shows real images if available,
/// otherwise placeholders.
class _ScreenshotsSection extends StatelessWidget {
  const _ScreenshotsSection({
    required this.accent,
    required this.imageUrls,
  });

  final Color accent;
  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final hasImages = imageUrls.isNotEmpty;
    final count = hasImages ? imageUrls.length : 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Preview',
              style: context.kidunaText.label.copyWith(
                color: colors.cream,
                fontSize: 14,
              ),
            ),
            if (hasImages) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.muted.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: context.kidunaText.micro.copyWith(
                    color: colors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: count,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (hasImages) {
                return Container(
                  width: 240,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.line),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.network(
                      imageUrls[index],
                      width: 240,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: colors.surface,
                        child: Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 28,
                            color: colors.error.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
              // Placeholder
              return Container(
                width: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.06),
                      colors.deep,
                    ],
                  ),
                  border: Border.all(color: colors.line),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_outlined, size: 28,
                          color: colors.muted.withValues(alpha: 0.3)),
                      const SizedBox(height: 6),
                      Text('Screenshot ${index + 1}',
                          style: context.kidunaText.micro
                              .copyWith(color: colors.quiet)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// About section — full description.
class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.scene, required this.accent});

  final SceneMockItem scene;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About this scene',
          style: context.kidunaText.label.copyWith(
            color: colors.cream,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.line),
          ),
          child: Text(
            scene.description,
            style: context.kidunaText.bodySm.copyWith(
              color: colors.muted,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

/// Info table — version, category, size, status in a clean grid.
class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.scene, required this.accent});

  final SceneMockItem scene;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Information',
          style: context.kidunaText.label.copyWith(
            color: colors.cream,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.line),
          ),
          child: Column(
            children: [
              _InfoRow(label: 'Version', value: '1.0.0'),
              _InfoDivider(),
              _InfoRow(label: 'Category', value: scene.categoryLabel),
              _InfoDivider(),
              _InfoRow(
                label: 'Status',
                value: scene.statusLabel,
                valueColor: scene.isAvailable ? colors.mint : colors.camel,
              ),
              _InfoDivider(),
              _InfoRow(label: 'Updated', value: 'Aug 15, 2026'),
              _InfoDivider(),
              _InfoRow(label: 'Requires', value: 'Kiduna 1.0+'),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Text(
            label,
            style: context.kidunaText.bodySm.copyWith(color: colors.muted),
          ),
          const Spacer(),
          Text(
            value,
            style: context.kidunaText.bodySm.copyWith(
              color: valueColor ?? colors.cream,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(height: 1, color: context.kiduna.line),
    );
  }
}

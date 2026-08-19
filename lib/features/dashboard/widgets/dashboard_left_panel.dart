import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

class DashboardLeftPanel extends StatelessWidget {
  const DashboardLeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return ColoredBox(
      color: colors.field,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YOUR REALM',
              style: text.eyebrow.copyWith(color: colors.gold),
            ),
            const SizedBox(height: 16),
            Text(
              'Genesis Ecosystem',
              style: text.h2.copyWith(color: colors.cream),
            ),
            const SizedBox(height: 8),
            Text(
              'The beginning of your journey in the Kinship network.',
              style: text.body.copyWith(color: colors.muted),
            ),
            const SizedBox(height: 32),
            const _StatCard(label: 'COMPUTE', value: '0.00', unit: 'KDN'),
            const SizedBox(height: 16),
            const _StatCard(label: 'CONNECTIONS', value: '0', unit: 'allies'),
            const SizedBox(height: 16),
            const _StatCard(label: 'SKILLS', value: '0', unit: 'active'),
            const SizedBox(height: 32),
            _SectionHeader(label: 'POSSIBLE ACTIONS'),
            const SizedBox(height: 12),
            const _ActionTile(
              icon: Icons.person_add_outlined,
              title: 'Invite Allies',
              subtitle: 'Grow your network',
            ),
            const SizedBox(height: 8),
            const _ActionTile(
              icon: Icons.explore_outlined,
              title: 'Explore Realms',
              subtitle: 'Discover new ecosystems',
            ),
            const SizedBox(height: 8),
            const _ActionTile(
              icon: Icons.auto_awesome_outlined,
              title: 'Create a Skill',
              subtitle: 'Teach Ki something new',
            ),
            const Spacer(),
            Center(
              child: Text(
                'More features coming soon',
                style: text.caption.copyWith(color: colors.quiet),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Row(
      children: [
        Text(label, style: text.eyebrowSmall.copyWith(color: colors.quiet)),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(color: colors.camel.withValues(alpha: 0.2), height: 1),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.6),
        border: Border.all(color: colors.camel.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: text.eyebrowSmall.copyWith(color: colors.quiet),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: text.h4.copyWith(color: colors.cream)),
                    const SizedBox(width: 6),
                    Text(
                      unit,
                      style: text.caption.copyWith(color: colors.quiet),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatefulWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _hovered
              ? colors.sky.withValues(alpha: 0.05)
              : Colors.transparent,
          border: Border.all(
            color: _hovered
                ? colors.sky.withValues(alpha: 0.2)
                : colors.camel.withValues(alpha: 0.12),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              widget.icon,
              size: 20,
              color: _hovered ? colors.sky : colors.quiet,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: text.body.copyWith(
                      color: _hovered ? colors.sky : colors.cream,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    style: text.caption.copyWith(color: colors.quiet),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: _hovered ? colors.sky : colors.quiet,
            ),
          ],
        ),
      ),
    );
  }
}

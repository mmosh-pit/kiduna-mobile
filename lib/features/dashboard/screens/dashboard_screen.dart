import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../features/field/screens/field_screen.dart';
import '../../../features/game/screens/game_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/layouts/responsive_layout.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/ki_agent.dart';
import '../controllers/ecosystem_controller.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    // Load ecosystem early so realmId is available for chat API
    Future.microtask(() {
      ref.read(ecosystemControllerProvider.notifier).loadEcosystem();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Scaffold(
      backgroundColor: colors.field,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: ResponsiveLayout(
              desktop: (_) => _ContentWide(activeTab: _activeTab),
              mobile: (_) => _ContentNarrow(activeTab: _activeTab),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomTabBar(
        activeTab: _activeTab,
        onTabChanged: (index) => setState(() => _activeTab = index),
      ),
    );
  }
}

/// Bottom navigation bar with 4 tabs.
class _BottomTabBar extends StatelessWidget {
  const _BottomTabBar({
    required this.activeTab,
    required this.onTabChanged,
  });

  final int activeTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colors.deep,
        border: Border(
          top: BorderSide(color: colors.camel.withValues(alpha: 0.12)),
        ),
      ),
      child: Row(
        children: [
          _TabItem(
            icon: Icons.people_outline,
            activeIcon: Icons.people,
            label: l10n.tabMatching,
            isActive: activeTab == 0,
            onTap: () => onTabChanged(0),
          ),
          _TabItem(
            icon: Icons.casino_outlined,
            activeIcon: Icons.casino,
            label: l10n.tabCards,
            isActive: activeTab == 1,
            onTap: () => onTabChanged(1),
          ),
          _TabItem(
            icon: Icons.emoji_events_outlined,
            activeIcon: Icons.emoji_events,
            label: l10n.tabStandings,
            isActive: activeTab == 2,
            onTap: () => onTabChanged(2),
          ),
          _TabItem(
            icon: Icons.shield_outlined,
            activeIcon: Icons.shield,
            label: l10n.tabGuilds,
            isActive: activeTab == 3,
            onTap: () => onTabChanged(3),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final color = isActive ? colors.gold : colors.quiet;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: context.kidunaText.eyebrowSmall.copyWith(
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Desktop layout — left panel (based on tab) + Ki chat right.
/// The boundary between them is draggable to resize the Ki chat.
class _ContentWide extends StatefulWidget {
  const _ContentWide({required this.activeTab});

  final int activeTab;

  @override
  State<_ContentWide> createState() => _ContentWideState();
}

class _ContentWideState extends State<_ContentWide> {
  double _kiFraction = 0.30;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final total = constraints.maxWidth;
        final kiWidth = (_kiFraction * total).clamp(280.0, total * 0.50);
        final contentWidth = total - 12 - kiWidth;

        return Row(
          children: [
            SizedBox(
              width: contentWidth,
              child: _buildLeftPanel(context, widget.activeTab),
            ),
            _ResizeBoundary(
              onDrag: (dx) {
                setState(() {
                  _kiFraction = (_kiFraction - dx / total).clamp(0.20, 0.50);
                });
              },
            ),
            SizedBox(width: kiWidth, child: const KiAgent()),
          ],
        );
      },
    );
  }
}

class _ResizeBoundary extends StatefulWidget {
  const _ResizeBoundary({required this.onDrag});

  final ValueChanged<double> onDrag;

  @override
  State<_ResizeBoundary> createState() => _ResizeBoundaryState();
}

class _ResizeBoundaryState extends State<_ResizeBoundary> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final active = _hovered;
    final lineColor = active
        ? colors.sky.withValues(alpha: 0.5)
        : colors.sky.withValues(alpha: 0.3);
    final arrowColor = active
        ? colors.sky
        : colors.sky.withValues(alpha: 0.5);

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (d) => widget.onDrag(d.delta.dx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 12,
          color: active
              ? colors.sky.withValues(alpha: 0.06)
              : Colors.transparent,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '◂',
                  style: TextStyle(
                    fontSize: 10,
                    color: arrowColor,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 2,
                  height: 34,
                  decoration: BoxDecoration(
                    color: lineColor,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: active ? 10 : 4,
                        color: colors.sky.withValues(
                          alpha: active ? 0.35 : 0.15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '▸',
                  style: TextStyle(
                    fontSize: 10,
                    color: arrowColor,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mobile layout — left panel top + Ki chat bottom.
class _ContentNarrow extends StatelessWidget {
  const _ContentNarrow({required this.activeTab});

  final int activeTab;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(flex: 5, child: _buildLeftPanel(context, activeTab)),
        const Expanded(flex: 5, child: KiAgent()),
      ],
    );
  }
}

/// Returns the left panel widget based on active tab.
Widget _buildLeftPanel(BuildContext context, int activeTab) {
  final l10n = AppLocalizations.of(context)!;

  return switch (activeTab) {
    0 => const FieldStack(),
    1 => const GameScreen(),
    _ => _ComingSoonPanel(
        title: switch (activeTab) {
          2 => l10n.tabStandings,
          3 => l10n.tabGuilds,
          _ => '',
        },
        icon: switch (activeTab) {
          2 => Icons.emoji_events,
          3 => Icons.shield,
          _ => Icons.hourglass_empty,
        },
      ),
  };
}

/// Placeholder screen for features not yet built.
class _ComingSoonPanel extends StatelessWidget {
  const _ComingSoonPanel({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: colors.field,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colors.gold.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              title,
              style: text.h4.copyWith(color: colors.gold.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 8),
            Text(l10n.comingSoon, style: text.body.copyWith(color: colors.quiet)),
          ],
        ),
      ),
    );
  }
}

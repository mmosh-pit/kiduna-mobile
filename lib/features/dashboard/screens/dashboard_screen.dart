import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../features/auth/screens/login_screen.dart';
import '../../../features/field/screens/field_screen.dart';
import '../../../features/game/screens/game_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/layouts/responsive_layout.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/ki_agent.dart';
import '../controllers/ecosystem_controller.dart';
import '../../../features/ki_chat/controllers/ki_chat_controller.dart';

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

  void _handleTabChange(int index) {
    if (_activeTab == 1 && index != 1) {
      final ki = ref.read(kiChatControllerProvider.notifier);
      if (ki.hasGameContext) {
        _showLeaveGameDialog(index);
        return;
      }
    }
    setState(() => _activeTab = index);
  }

  void _showLeaveGameDialog(int targetTab) {
    final colors = context.kiduna;
    showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        final screenWidth = MediaQuery.of(ctx).size.width;
        return Stack(
          children: [
            // Dark overlay — left side only
            Positioned(
              left: 0, top: 0, bottom: 0,
              width: screenWidth * 0.7,
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(color: Colors.black.withValues(alpha: 0.72)),
              ),
            ),
            // Popup centered in left side
            Positioned(
              left: 0, top: 0, bottom: 0,
              width: screenWidth * 0.7,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 340,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B140C),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF6B5533), width: 1.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Leave the game?',
                          style: TextStyle(fontFamily: 'GoudyHeavyface', fontSize: 22, color: colors.gold)),
                        const SizedBox(height: 8),
                        Text("You'll forfeit your seat and progress.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.cream.withValues(alpha: 0.7), fontSize: 14)),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.of(ctx).pop(false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(color: const Color(0xFF2A6B4F), borderRadius: BorderRadius.circular(10)),
                                  child: Center(child: Text('Keep Playing',
                                    style: TextStyle(color: colors.cream, fontWeight: FontWeight.w600, fontSize: 15))),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.of(ctx).pop(true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(color: const Color(0xFFB3261E), borderRadius: BorderRadius.circular(10)),
                                  child: Center(child: Text('Leave',
                                    style: TextStyle(color: colors.cream, fontWeight: FontWeight.w600, fontSize: 15))),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ).then((leave) {
      if (leave == true) {
        final ki = ref.read(kiChatControllerProvider.notifier);
        ki.clearGameContext();
        ki.clearLocalTips();
        setState(() => _activeTab = targetTab);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Scaffold(
      backgroundColor: colors.field,
      body: Column(
        children: [
          AppHeader(trailing: _HeaderActions(ref: ref)),
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
        onTabChanged: _handleTabChange,
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

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [_UserAvatarPopup(ref: ref)],
    );
  }
}

class _UserAvatarPopup extends StatelessWidget {
  const _UserAvatarPopup({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    final initial =
        (user?.name.isNotEmpty ?? false) ? user!.name.characters.first : 'U';

    return PopupMenuButton<String>(
      offset: const Offset(0, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.gold.withValues(alpha: 0.35)),
      ),
      color: colors.raised,
      elevation: 12,
      shadowColor: Colors.black54,
      onSelected: (value) async {
        if (value == 'copy_wallet') {
          final wallet = user?.wallet;
          if (wallet != null && wallet.isNotEmpty) {
            await Clipboard.setData(ClipboardData(text: wallet));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Wallet address copied',
                  style: text.body.copyWith(color: colors.cream),
                ),
                backgroundColor: colors.raised,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: colors.gold.withValues(alpha: 0.3)),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
        if (value == 'logout') {
          await ref.read(authControllerProvider.notifier).logout();
          if (!context.mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder<void>(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const LoginScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
            (_) => false,
          );
        }
      },
      itemBuilder: (context) {
        final displayName = user?.displayName ?? user?.name ?? 'User';
        final role = (user?.role ?? 'member').toUpperCase();
        final wallet = user?.wallet ?? '';

        return [
          PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colors.camel.withValues(alpha: 0.14),
                  ),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colors.gold.withValues(alpha: 0.15),
                    child: Text(
                      initial,
                      style: text.h4.copyWith(color: colors.gold, height: 1),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$displayName · $role',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.body.copyWith(
                      color: colors.cream,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (wallet.isNotEmpty)
            PopupMenuItem<String>(
              value: 'copy_wallet',
              padding: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WALLET',
                      style: text.eyebrowSmall.copyWith(
                        color: colors.quiet,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colors.camel.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 16,
                            color: colors.gold,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _truncateWallet(wallet),
                              style: text.caption.copyWith(
                                color: colors.cream,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.gold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: colors.gold.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              'COPY',
                              style: text.eyebrowSmall.copyWith(
                                color: colors.gold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout_rounded, size: 18, color: colors.error),
                const SizedBox(width: 12),
                Text('Sign Out', style: text.body.copyWith(color: colors.error)),
              ],
            ),
          ),
        ];
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.gold.withValues(alpha: 0.12),
          border: Border.all(color: colors.gold.withValues(alpha: 0.35)),
        ),
        child: Center(
          child: Text(
            initial,
            style: text.eyebrow.copyWith(
              color: colors.gold.withValues(alpha: 0.75),
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

String _truncateWallet(String wallet) {
  if (wallet.length <= 14) return wallet;
  return '${wallet.substring(0, 6)}...${wallet.substring(wallet.length - 5)}';
}
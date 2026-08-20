import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../features/auth/screens/login_screen.dart';
import '../../../shared/layouts/responsive_layout.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/ki_agent.dart';
import '../widgets/dashboard_left_panel.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.kiduna;

    return Scaffold(
      backgroundColor: colors.field,
      body: Column(
        children: [
          AppHeader(
            trailing: _HeaderActions(ref: ref),
          ),
          Expanded(
            child: ResponsiveLayout(
              desktop: (_) => const _DashboardWide(),
              mobile: (_) => const _DashboardNarrow(),
            ),
          ),
        ],
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
      children: [
        _UserAvatarPopup(ref: ref),
      ],
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
                      style: TextStyle(
                        fontFamily: 'GoudyHeavyface',
                        fontSize: 24,
                        color: colors.gold,
                        height: 1,
                      ),
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
                Text(
                  'Sign Out',
                  style: text.body.copyWith(color: colors.error),
                ),
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
            style: TextStyle(
              fontFamily: 'GoudyHeavyface',
              fontSize: 16,
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

class _DashboardWide extends StatelessWidget {
  const _DashboardWide();

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Row(
      children: [
        const Expanded(flex: 6, child: DashboardLeftPanel()),
        Container(width: 1, color: colors.camel.withValues(alpha: 0.18)),
        const Expanded(flex: 4, child: KiAgent()),
      ],
    );
  }
}

class _DashboardNarrow extends StatelessWidget {
  const _DashboardNarrow();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Expanded(flex: 5, child: DashboardLeftPanel()),
        Expanded(flex: 5, child: KiAgent()),
      ],
    );
  }
}

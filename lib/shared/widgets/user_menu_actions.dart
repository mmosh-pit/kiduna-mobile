import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions/context_extensions.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/user_profile_screen.dart';

/// Header trailing actions — the user avatar with its account popup
/// (wallet copy + sign out). Shared by the dashboard and the web
/// download page so both expose the same account controls.
class UserMenuActions extends StatelessWidget {
  const UserMenuActions({super.key, required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [_UserAvatarPopupInternal(ref: ref)],
    );
  }
}

class _UserAvatarPopupInternal extends StatelessWidget {
  const _UserAvatarPopupInternal({required this.ref});

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
        if (value == 'view_profile') {
          final username = user?.username;
          print('[UserMenu] View Profile tapped — username=$username');
          if (username != null && username.isNotEmpty) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => UserProfileScreen(handle: username),
              ),
            );
          } else {
            // Fallback: use wallet address as handle lookup
            final wallet = user?.wallet;
            print('[UserMenu] username null, trying wallet=$wallet');
            if (wallet != null && wallet.isNotEmpty) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => UserProfileScreen(handle: wallet),
                ),
              );
            }
          }
        }
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
          // View Profile
          PopupMenuItem<String>(
            value: 'view_profile',
            child: Row(
              children: [
                Icon(Icons.person_outline, size: 18, color: colors.cream),
                const SizedBox(width: 12),
                Text('View Profile',
                    style: text.body.copyWith(color: colors.cream)),
              ],
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
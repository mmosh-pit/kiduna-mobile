import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/assets.dart';
import '../../core/extensions/context_extensions.dart';
import '../../features/auth/controllers/auth_controller.dart';
import 'connect_wallet_button.dart';
import 'user_menu_actions.dart';

const Color _headerBg = Color.fromRGBO(18, 12, 7, 0.97);

/// The app header — logo on the left, account controls on the right.
///
/// When the user is signed in the account menu is shown automatically, so
/// screens don't each have to remember to add it. Pass [trailing] to render
/// something else instead, or [showUserMenu] as false to suppress it (login
/// and signup, where there is no session yet).
class AppHeader extends ConsumerWidget {
  const AppHeader({
    super.key,
    this.trailing,
    this.showUserMenu = true,
  });

  /// Overrides the default account menu when provided.
  final Widget? trailing;

  /// Set false on pre-auth screens that should stay bare.
  final bool showUserMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.kiduna;
    final isMobile = context.isMobile;

    final isAuthenticated = ref.watch(
      authControllerProvider.select((s) => s.isAuthenticated),
    );

    final Widget? end = trailing ??
        (showUserMenu && isAuthenticated ? UserMenuActions(ref: ref) : null);

    return Container(
      height: 74,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      decoration: BoxDecoration(
        color: _headerBg,
        border: Border(
          bottom: BorderSide(color: colors.camel.withValues(alpha: 0.28)),
        ),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            AppAssets.kidunaLogo,
            width: isMobile ? 118 : 138,
            height: isMobile ? 34 : 40,
          ),
          const Spacer(),
          // Wallet connection is a web-only concern; the button renders
          // nothing elsewhere.
          if (showUserMenu && isAuthenticated) const ConnectWalletButton(),
          ?end,
        ],
      ),
    );
  }
}

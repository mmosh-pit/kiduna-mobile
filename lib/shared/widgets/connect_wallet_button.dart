import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/extensions/context_extensions.dart';
import '../../features/compute/controllers/wallet_controller.dart';

/// Header control for connecting a browser wallet.
///
/// Renders nothing off web: browser extensions do not exist there, and an
/// inert button would only invite taps that cannot work.
class ConnectWalletButton extends ConsumerWidget {
  const ConnectWalletButton({super.key});

  static const _phantomInstallUrl = 'https://phantom.app/download';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kIsWeb) return const SizedBox.shrink();

    final colors = context.kiduna;
    final text = context.kidunaText;
    final wallet = ref.watch(walletControllerProvider);

    // No extension installed — point at the install page rather than
    // failing on click.
    if (!wallet.isAvailable) {
      return _Pill(
        label: 'Install Phantom',
        icon: Icons.open_in_new,
        onTap: () => launchUrl(
          Uri.parse(_phantomInstallUrl),
          mode: LaunchMode.externalApplication,
        ),
        color: colors.sky,
      );
    }

    if (wallet.isConnected) {
      return _Pill(
        label: wallet.shortAddress,
        icon: Icons.link_off,
        onTap: () => ref.read(walletControllerProvider.notifier).disconnect(),
        color: colors.gold,
      );
    }

    return _Pill(
      label: wallet.isConnecting ? 'Connecting...' : 'Connect Wallet',
      icon: Icons.account_balance_wallet_outlined,
      onTap: wallet.isConnecting
          ? null
          : () => ref.read(walletControllerProvider.notifier).connect(),
      color: colors.sky,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = context.kidunaText;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 7),
              Text(
                label,
                style: text.label.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

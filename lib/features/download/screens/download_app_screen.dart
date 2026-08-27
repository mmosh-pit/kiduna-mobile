import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../shared/widgets/app_header.dart';

/// Shown on web after login/signup — directs users to download native apps.
class DownloadAppScreen extends ConsumerWidget {
  const DownloadAppScreen({super.key});

  static const _appStoreUrl =
      'https://apps.apple.com/app/kiduna/id0000000000'; // TODO: real App Store URL
  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.example.kiduna'; // TODO: real Play Store URL
  static const _macUrl =
      'https://kiduna.ai/download/macos'; // TODO: real macOS download URL
  static const _windowsUrl =
      'https://kiduna.ai/download/windows'; // TODO: real Windows download URL
  static const _linuxUrl =
      'https://kiduna.ai/download/linux'; // TODO: real Linux download URL

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    // Watch auth state to ensure header rebuilds with user info
    ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: colors.deep,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Success icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.gold.withValues(alpha: 0.12),
                          border: Border.all(
                            color: colors.gold.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 36,
                          color: colors.gold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        "You're In!",
                        style: text.h4.copyWith(color: colors.gold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        'Your account is ready. Download the Kiduna app to start your journey.',
                        style: text.body.copyWith(
                          color: colors.muted,
                          fontSize: 15,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // App Store
                      _DownloadButton(
                        icon: Icons.apple,
                        label: 'Download on the',
                        storeName: 'App Store',
                        onTap: () => _launch(_appStoreUrl),
                      ),
                      const SizedBox(height: 14),

                      // Play Store
                      _DownloadButton(
                        icon: Icons.shop,
                        label: 'Get it on',
                        storeName: 'Google Play',
                        onTap: () => _launch(_playStoreUrl),
                      ),
                      const SizedBox(height: 14),

                      // macOS
                      _DownloadButton(
                        icon: Icons.laptop_mac,
                        label: 'Download for',
                        storeName: 'macOS',
                        onTap: () => _launch(_macUrl),
                      ),
                      const SizedBox(height: 14),

                      // Windows
                      _DownloadButton(
                        icon: Icons.desktop_windows,
                        label: 'Download for',
                        storeName: 'Windows',
                        onTap: () => _launch(_windowsUrl),
                      ),
                      const SizedBox(height: 14),

                      // Linux
                      _DownloadButton(
                        icon: Icons.computer,
                        label: 'Download for',
                        storeName: 'Linux',
                        onTap: () => _launch(_linuxUrl),
                      ),
                      const SizedBox(height: 32),

                      // Divider
                      Container(
                        height: 1,
                        color: colors.camel.withValues(alpha: 0.15),
                      ),
                      const SizedBox(height: 20),

                      // Info text
                      Text(
                        'Kiduna is best experienced on our native apps. '
                        'All your data syncs automatically across devices.',
                        style: text.caption.copyWith(
                          color: colors.quiet,
                          fontSize: 12,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({
    required this.icon,
    required this.label,
    required this.storeName,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String storeName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: colors.deep,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.camel.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 32, color: colors.cream),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: text.caption.copyWith(
                      color: colors.muted,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    storeName,
                    style: text.body.copyWith(
                      color: colors.cream,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colors.quiet,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

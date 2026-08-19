import 'package:flutter/material.dart';
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
          AppHeader(trailing: _LogoutButton(ref: ref)),
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

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return TextButton.icon(
      onPressed: () async {
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
      },
      icon: Icon(Icons.logout_rounded, size: 18, color: colors.muted),
      label: Text('Logout', style: text.caption.copyWith(color: colors.muted)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.camel.withValues(alpha: 0.18)),
        ),
      ),
    );
  }
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

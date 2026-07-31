import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../config/assets.dart';
import '../../../core/extensions/context_extensions.dart';
import '../controllers/auth_controller.dart';
import '../widgets/login_form.dart';

/// Full-screen login — dark espresso background, centred Kiduna logo and
/// [LoginForm].
///
/// Reads auth state from [authControllerProvider]; navigation is handled by
/// the GoRouter redirect guard — the screen itself never calls `context.go`.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Scaffold(
      backgroundColor: colors.field,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo ────────────────────────────────────────────
                SvgPicture.asset(AppAssets.kidunaLogo, width: 160),
                const SizedBox(height: 48),

                // ── Heading ─────────────────────────────────────────
                Text(
                  context.l10n.welcomeBack,
                  style: text.heading.copyWith(color: colors.cream),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.signInToContinue,
                  style: text.body.copyWith(color: colors.muted),
                ),
                const SizedBox(height: 32),

                // ── Form ────────────────────────────────────────────
                LoginForm(
                  onSubmit: controller.login,
                  status: authState.status,
                  error: authState.error,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

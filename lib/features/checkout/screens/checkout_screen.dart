import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../shared/widgets/app_header.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/widgets/signup_left_panel.dart';
import '../widgets/checkout_how_it_works.dart';
import '../widgets/checkout_payment_card.dart';

const _checkoutLeftPanel = SignupLeftPanel(
  tagline: 'Founding Member ✦ Pre-launch Price',
  headingPrefix: 'Buy the Compute to\n',
  headingAccent: 'Shape What\'s Next',
  description:
      'Start with \$100 USDC to purchase compute resources for bringing '
      'new worlds to life, shaped by your vision, strengthened through '
      'relationships, and guided by your dreams.',
);

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: colors.deep,
      body: Column(
        children: [
          AppHeader(
            trailing: TextButton(
              onPressed: () => _navigateToLogin(context),
              style: TextButton.styleFrom(
                foregroundColor: colors.muted,
                textStyle: const TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Log out'),
            ),
          ),
          Expanded(
            child: isMobile
                ? _buildMobileLayout(context)
                : _buildDesktopLayout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        const Expanded(flex: 11, child: _checkoutLeftPanel),
        Expanded(flex: 9, child: _buildRightPanel(context)),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 610, child: _checkoutLeftPanel),
          _buildRightPanel(context),
        ],
      ),
    );
  }

  Widget _buildRightPanel(BuildContext context) {
    final colors = context.kiduna;

    return Container(
      color: colors.deep,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 38),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 76,
                maxWidth: double.infinity,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CheckoutHowItWorks(),
                      const SizedBox(height: 18),
                      CheckoutPaymentCard(
                        onBuyUsdc: () {},
                        onConnectWallet: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

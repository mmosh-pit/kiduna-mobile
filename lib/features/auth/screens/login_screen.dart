import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../shared/widgets/app_header.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../controllers/auth_controller.dart';
import '../enums/auth_status.dart';
import '../widgets/login_form.dart';
import '../widgets/signup_left_panel.dart';
import 'signup_screen.dart';

const _loginLeftPanel = SignupLeftPanel(
  tagline: 'The Genesis Ecosystem welcomes you back.',
  headingPrefix: 'Welcome ',
  headingAccent: 'Back',
  description: 'Continue your journey with creators, builders, organizers, and intelligent agents shaping a network where everyone has a place and a part to play.',
);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  void _navigateToSignup() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SignupScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _login(String email, String password) async {
    await ref.read(authControllerProvider.notifier).login(email, password);
    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    if (authState.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final isMobile = context.isMobile;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final apiError = authState.error;

    return Scaffold(
      backgroundColor: colors.deep,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: isMobile
                ? _buildMobileLayout(isLoading, apiError)
                : _buildDesktopLayout(isLoading, apiError),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(bool isLoading, String? apiError) {
    return Row(
      children: [
        const Expanded(flex: 11, child: _loginLeftPanel),
        Expanded(flex: 9, child: _buildRightPanel(isLoading, apiError)),
      ],
    );
  }

  Widget _buildMobileLayout(bool isLoading, String? apiError) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 610, child: _loginLeftPanel),
          _buildRightPanel(isLoading, apiError),
        ],
      ),
    );
  }

  Widget _buildRightPanel(bool isLoading, String? apiError) {
    final colors = context.kiduna;

    return Container(
      color: colors.deep,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 80,
                maxWidth: double.infinity,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: LoginForm(
                    onLogin: _login,
                    onCreateAccount: _navigateToSignup,
                    isLoading: isLoading,
                    apiError: apiError,
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

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/services/auth_service.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/kiduna_message_box.dart';
import '../../../shared/widgets/kiduna_progress_bar.dart';
import '../widgets/forgot_password_step_one.dart';
import '../widgets/forgot_password_step_three.dart';
import '../widgets/forgot_password_step_two.dart';
import '../widgets/signup_left_panel.dart';
import 'login_screen.dart';

const _forgotLeftPanel = SignupLeftPanel(
  tagline: 'We\'ll help you get back on track.',
  headingPrefix: 'Reset ',
  headingAccent: 'Password',
  description: 'Enter your email to receive a verification code. Once verified, you can set a new password and continue your journey.',
);

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 1;
  String? _message;
  MessageType _messageType = MessageType.success;
  Timer? _messageTimer;
  bool _isLoading = false;
  String _otpCode = '';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _messageTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() {
      _message = null;
      _currentStep = step;
    });
  }

  void _showMessage(String text, MessageType type) {
    _messageTimer?.cancel();
    setState(() {
      _message = text;
      _messageType = type;
    });
    _messageTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _message = null);
      }
    });
  }

  void _onError(String text) {
    _showMessage(text, MessageType.error);
  }

  void _navigateToLogin() {
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

  Future<void> _requestResetCode() async {
    final email = _emailController.text.trim();
    setState(() => _isLoading = true);

    try {
      await AuthService.instance.requestPasswordReset(email: email);
      if (!mounted) return;
      _showMessage('Verification code sent to $email', MessageType.success);
      _goToStep(2);
    } on NotFoundException {
      if (!mounted) return;
      _onError('No account found with this email address.');
    } on ValidationException catch (e) {
      if (!mounted) return;
      _onError(e.message ?? 'Validation failed.');
    } on NetworkException {
      if (!mounted) return;
      _onError('No internet connection. Please check your network.');
    } on ApiTimeoutException {
      if (!mounted) return;
      _onError('Request timed out. Please try again.');
    } on ServerException {
      if (!mounted) return;
      _onError('Server error. Please try again later.');
    } catch (e, st) {
      AppLogger.error(
        'Unexpected error in requestPasswordReset',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      _onError('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyCode(String otpCode) async {
    _otpCode = otpCode;
    _goToStep(3);
  }

  Future<void> _resendCode() async {
    final email = _emailController.text.trim();
    setState(() => _isLoading = true);

    try {
      await AuthService.instance.requestPasswordReset(email: email);
      if (!mounted) return;
      _showMessage('Code resent. Check your inbox.', MessageType.success);
    } on NetworkException {
      if (!mounted) return;
      _onError('No internet connection.');
    } catch (e, st) {
      AppLogger.error(
        'Unexpected error in resendCode',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      _onError('Could not resend code. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final code = int.tryParse(_otpCode);
    final newPassword = _passwordController.text;

    if (code == null) {
      _onError('Invalid verification code.');
      _goToStep(2);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.instance.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      if (!mounted) return;

      AppLogger.info('Password reset successful', tag: 'Auth');
      _showMessage(
        'Password reset successfully! Redirecting to login...',
        MessageType.success,
      );

      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      _navigateToLogin();
    } on ValidationException catch (e) {
      if (!mounted) return;
      _onError(e.message ?? 'Invalid or expired code. Please try again.');
      _goToStep(2);
    } on NetworkException {
      if (!mounted) return;
      _onError('No internet connection. Please check your network.');
    } on ApiTimeoutException {
      if (!mounted) return;
      _onError('Request timed out. Please try again.');
    } on ServerException {
      if (!mounted) return;
      _onError('Server error. Please try again later.');
    } catch (e, st) {
      AppLogger.error(
        'Unexpected error in resetPassword',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      _onError('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return ForgotPasswordStepOne(
          key: const ValueKey(1),
          onNext: _requestResetCode,
          onBack: _navigateToLogin,
          onError: _onError,
          emailController: _emailController,
          isLoading: _isLoading,
        );
      case 2:
        return ForgotPasswordStepTwo(
          key: const ValueKey(2),
          email: _emailController.text,
          onNext: _verifyCode,
          onBack: () => _goToStep(1),
          onResend: _resendCode,
          onError: _onError,
          isLoading: _isLoading,
        );
      case 3:
        return ForgotPasswordStepThree(
          key: const ValueKey(3),
          onSubmit: _resetPassword,
          onBack: () => _goToStep(2),
          onError: _onError,
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          isLoading: _isLoading,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: colors.deep,
      body: Column(
        children: [
          const AppHeader(showUserMenu: false),
          Expanded(
            child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        const Expanded(flex: 11, child: _forgotLeftPanel),
        Expanded(flex: 9, child: _buildRightPanel()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 610, child: _forgotLeftPanel),
          _buildRightPanel(),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      KidunaProgressBar(
                        totalSteps: 3,
                        currentStep: _currentStep,
                      ),
                      const SizedBox(height: 28),
                      if (_message != null) ...[
                        KidunaMessageBox(
                          message: _message!,
                          type: _messageType,
                        ),
                        const SizedBox(height: 16),
                      ],
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildCurrentStep(),
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

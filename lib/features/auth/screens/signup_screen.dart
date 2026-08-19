import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/local/secure_storage.dart';
import '../../../data/services/auth_service.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/kiduna_message_box.dart';
import '../../../shared/widgets/kiduna_progress_bar.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../widgets/signup_left_panel.dart';
import '../widgets/signup_step_four.dart';
import '../widgets/signup_step_one.dart';
import '../widgets/signup_step_three.dart';
import '../widgets/signup_step_two.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _currentStep = 1;
  String? _message;
  MessageType _messageType = MessageType.success;
  Timer? _messageTimer;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _kinshipCodeController = TextEditingController();
  final _handshakeController = TextEditingController();

  @override
  void dispose() {
    _messageTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _kinshipCodeController.dispose();
    _handshakeController.dispose();
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

  void _navigateToDashboard() {
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

  // Step 1 → send email OTP
  Future<void> _generateOtp() async {
    final email = _emailController.text.trim();
    setState(() => _isLoading = true);

    try {
      await AuthService.instance.generateOtp(email: email);
      if (!mounted) return;
      _showMessage('Verification code sent to $email', MessageType.success);
      _goToStep(2);
    } on ConflictException catch (e) {
      if (!mounted) return;
      _onError(e.message ?? 'A conflict occurred.');
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
        'Unexpected error in generateOtp',
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

  // Step 2 → verify OTP
  Future<void> _verifyOtp(String otpCode) async {
    final email = _emailController.text.trim();
    setState(() => _isLoading = true);

    try {
      await AuthService.instance.verifyOtp(email: email, otp: otpCode);
      if (!mounted) return;
      _goToStep(3);
    } on ValidationException catch (e) {
      if (!mounted) return;
      _onError(e.message ?? 'Invalid code.');
    } on NetworkException {
      if (!mounted) return;
      _onError('No internet connection.');
    } on ApiTimeoutException {
      if (!mounted) return;
      _onError('Request timed out. Please try again.');
    } catch (e, st) {
      AppLogger.error(
        'Unexpected error in verifyOtp',
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

  // Step 2 → resend OTP
  Future<void> _resendOtp() async {
    final email = _emailController.text.trim();
    setState(() => _isLoading = true);

    try {
      await AuthService.instance.resendOtp(email: email);
      if (!mounted) return;
      _showMessage('Code resent. Check your inbox.', MessageType.success);
    } on ValidationException catch (e) {
      if (!mounted) return;
      _onError(e.message ?? 'Failed to resend code.');
    } on NetworkException {
      if (!mounted) return;
      _onError('No internet connection.');
    } catch (e, st) {
      AppLogger.error(
        'Unexpected error in resendOtp',
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

  // Step 3 → create account + wallet + kinship code
  Future<void> _createAccount() async {
    setState(() => _isLoading = true);

    try {
      final authResponse = await AuthService.instance.saveEarlyAccess(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      await SecureStorage.instance.saveToken(authResponse.token);
      await SecureStorage.instance.saveUser(authResponse.user);
      AppLogger.info('Account created successfully', tag: 'Auth');

      if (!mounted) return;
      _showMessage('Account created!', MessageType.success);
      _goToStep(4);
    } on ConflictException catch (e) {
      if (!mounted) return;
      _onError(e.message ?? 'Account already exists.');
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
        'Unexpected error in createAccount',
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

  // Step 4 → validate kinship code + complete signup
  Future<void> _completeSignup() async {
    final code = _kinshipCodeController.text.trim();
    final email = _emailController.text.trim();
    setState(() => _isLoading = true);

    try {
      final exists = await AuthService.instance.validateKinshipCode(code: code);
      if (!mounted) return;

      if (!exists) {
        _onError('Invalid Kinship Code. Please check and try again.');
        setState(() => _isLoading = false);
        return;
      }

      await AuthService.instance.updateKinshipCode(
        email: email,
        referredCode: code,
      );
      if (!mounted) return;

      AppLogger.info('Signup complete', tag: 'Auth');
      _navigateToDashboard();
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
        'Unexpected error in completeSignup',
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
        return SignupStepOne(
          key: const ValueKey(1),
          onNext: _generateOtp,
          onLogin: _navigateToLogin,
          onError: _onError,
          nameController: _nameController,
          emailController: _emailController,
          isLoading: _isLoading,
        );
      case 2:
        return SignupStepTwo(
          key: const ValueKey(2),
          email: _emailController.text,
          onNext: _verifyOtp,
          onBack: () => _goToStep(1),
          onError: _onError,
          onResend: _resendOtp,
          isLoading: _isLoading,
        );
      case 3:
        return SignupStepThree(
          key: const ValueKey(3),
          onNext: _createAccount,
          onBack: () => _goToStep(2),
          onError: _onError,
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          isLoading: _isLoading,
        );
      case 4:
        return SignupStepFour(
          key: const ValueKey(4),
          onComplete: _completeSignup,
          onBack: () => _goToStep(3),
          onError: _onError,
          kinshipCodeController: _kinshipCodeController,
          handshakeController: _handshakeController,
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
          const AppHeader(),
          Expanded(
            child: isMobile
                ? _buildMobileLayout(colors)
                : _buildDesktopLayout(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(dynamic colors) {
    return Row(
      children: [
        Expanded(flex: 11, child: const SignupLeftPanel()),
        Expanded(flex: 9, child: _buildRightPanel(colors)),
      ],
    );
  }

  Widget _buildMobileLayout(dynamic colors) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 610, child: SignupLeftPanel()),
          _buildRightPanel(colors),
        ],
      ),
    );
  }

  Widget _buildRightPanel(dynamic colors) {
    final kidunaColors = context.kiduna;

    return Container(
      color: kidunaColors.deep,
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
                        totalSteps: 4,
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

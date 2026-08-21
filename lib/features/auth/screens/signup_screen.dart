import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/local/secure_storage.dart';
import '../../../data/services/auth_service.dart';
import '../../../main.dart' show pendingInviteCode;
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/kiduna_message_box.dart';
import '../../../shared/widgets/kiduna_progress_bar.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../widgets/signup_left_panel.dart';
import '../widgets/signup_step_five.dart';
import '../widgets/signup_step_four.dart';
import '../widgets/signup_step_one.dart';
import '../widgets/signup_step_six.dart';
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
  final _mobileController = TextEditingController();
  final _inviteCodeController = TextEditingController();

  // Stored after Step 4 for use in Step 5
  String _mobileCountryCode = '';
  String _mobileNumber = '';

  // Invite preview info (shown on Step 6 after code validation)
  Map<String, dynamic>? _invitePreviewInfo;

  @override
  void initState() {
    super.initState();
    // Prefill invite code from URL (e.g., /join/RLM-A3Kx9M)
    if (pendingInviteCode != null && pendingInviteCode!.isNotEmpty) {
      _inviteCodeController.text = pendingInviteCode!;
      AppLogger.info(
        'Prefilled invite code: ${pendingInviteCode!}',
        tag: 'Signup',
      );
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _mobileController.dispose();
    _inviteCodeController.dispose();
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

  // ── Step 1 → send email OTP ─────────────────────────────────────────────
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

  // ── Step 2 → verify email OTP ───────────────────────────────────────────
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

  // ── Step 2 → resend email OTP ───────────────────────────────────────────
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

  // ── Step 3 → create account ─────────────────────────────────────────────
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

  // ── Step 4 → send SMS OTP ──────────────────────────────────────────────
  Future<void> _generateSmsOtp(String payload) async {
    // payload format: "countryCode|mobileNumber" (e.g., "91|6382987509")
    final parts = payload.split('|');
    if (parts.length != 2) {
      _onError('Invalid mobile number format.');
      return;
    }
    _mobileCountryCode = parts[0];
    _mobileNumber = parts[1];

    setState(() => _isLoading = true);

    try {
      await AuthService.instance.generateSmsOtp(
        mobile: _mobileNumber,
        countryCode: _mobileCountryCode,
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      _showMessage(
        'Code sent to +$_mobileCountryCode $_mobileNumber',
        MessageType.success,
      );
      _goToStep(5);
    } on ConflictException catch (e) {
      if (!mounted) return;
      _onError(e.message ?? 'Mobile number already registered.');
    } on ValidationException catch (e) {
      if (!mounted) return;
      _onError(e.message ?? 'Failed to send SMS code.');
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
        'Unexpected error in generateSmsOtp',
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

  // ── Step 5 → verify SMS OTP ────────────────────────────────────────────
  Future<void> _verifySmsOtp(String otpCode) async {
    setState(() => _isLoading = true);

    try {
      await AuthService.instance.verifySmsOtp(
        mobile: _mobileNumber,
        otp: otpCode,
      );
      if (!mounted) return;
      _goToStep(6);
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
        'Unexpected error in verifySmsOtp',
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

  // ── Step 5 → resend SMS OTP ────────────────────────────────────────────
  Future<void> _resendSmsOtp() async {
    setState(() => _isLoading = true);

    try {
      await AuthService.instance.resendSmsOtp(
        mobile: _mobileNumber,
        countryCode: _mobileCountryCode,
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      _showMessage('Code resent to your phone.', MessageType.success);
    } on ValidationException catch (e) {
      if (!mounted) return;
      _onError(e.message ?? 'Failed to resend code.');
    } on NetworkException {
      if (!mounted) return;
      _onError('No internet connection.');
    } catch (e, st) {
      AppLogger.error(
        'Unexpected error in resendSmsOtp',
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

  // ── Step 6 → join realm via invitation code ──────────────────────────
  Future<void> _completeSignup() async {
    final code = _inviteCodeController.text.trim();
    setState(() => _isLoading = true);

    try {
      // Preview first to validate
      final preview = await AuthService.instance.previewInvite(code: code);
      if (!mounted) return;

      if (preview['valid'] != true) {
        final reason = preview['reason'] as String? ?? 'Invalid invitation code.';
        _onError(reason);
        setState(() => _isLoading = false);
        return;
      }

      // Join the realm — backend handles:
      //   1. Add to realm_members
      //   2. Resolve inviter's kinship code
      //   3. Build lineage automatically
      final result = await AuthService.instance.joinRealmViaInvite(code: code);
      if (!mounted) return;

      if (result['success'] == true) {
        final realmName = result['realmName'] as String? ?? 'the community';
        AppLogger.info(
          'Signup complete — joined $realmName (lineage=${result['lineageBuilt']})',
          tag: 'Auth',
        );
        _navigateToDashboard();
      } else if (result['already_member'] == true) {
        AppLogger.info('Already a member — proceeding to dashboard', tag: 'Auth');
        _navigateToDashboard();
      } else {
        _onError('Failed to join. Please try again.');
      }
    } on ValidationException catch (e) {
      if (!mounted) return;
      _onError(e.message ?? 'Invalid invitation code.');
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
          onNext: _generateSmsOtp,
          onBack: () => _goToStep(3),
          onError: _onError,
          mobileController: _mobileController,
          isLoading: _isLoading,
        );
      case 5:
        return SignupStepFive(
          key: const ValueKey(5),
          formattedMobile: '+$_mobileCountryCode $_mobileNumber',
          onNext: _verifySmsOtp,
          onBack: () => _goToStep(4),
          onError: _onError,
          onResend: _resendSmsOtp,
          isLoading: _isLoading,
        );
      case 6:
        return SignupStepSix(
          key: const ValueKey(6),
          onComplete: _completeSignup,
          onBack: () => _goToStep(5),
          onError: _onError,
          inviteCodeController: _inviteCodeController,
          isLoading: _isLoading,
          previewInfo: _invitePreviewInfo,
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
                        totalSteps: 6,
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
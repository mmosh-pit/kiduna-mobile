import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../shared/animations/fade_up_animation.dart';
import '../../../shared/widgets/kiduna_message_box.dart';
import '../../../shared/widgets/kiduna_primary_button.dart';
import '../../../shared/widgets/kiduna_text_field.dart';

typedef LoginCallback = void Function(String email, String password);

class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
    required this.onLogin,
    required this.onCreateAccount,
    required this.onForgotPassword,
    this.isLoading = false,
    this.apiError,
  });

  final LoginCallback onLogin;
  final VoidCallback onCreateAccount;
  final VoidCallback onForgotPassword;
  final bool isLoading;
  final String? apiError;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _showPassword = false;
  String? _validationError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String? get _displayError => _validationError ?? widget.apiError;

  void _validate() {
    if (widget.isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      setState(() => _validationError = 'Please enter your email address.');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _validationError = 'Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _validationError = 'Please enter your password.');
      return;
    }

    setState(() => _validationError = null);
    widget.onLogin(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeUpAnimation(
          child: Text('Log in', style: text.h2.copyWith(color: colors.text)),
        ),
        const SizedBox(height: 8),
        FadeUpAnimation(
          delay: const Duration(milliseconds: 100),
          child: Text(
            'Welcome back. Enter your credentials to continue.',
            style: text.body.copyWith(
              color: colors.muted,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 28),
        if (_displayError != null) ...[
          KidunaMessageBox(message: _displayError!, type: MessageType.error),
          const SizedBox(height: 16),
        ],
        FadeUpAnimation(
          delay: const Duration(milliseconds: 200),
          child: KidunaTextField(
            label: 'Email address',
            placeholder: 'name@example.com',
            controller: _emailController,
            required: true,
            maxLength: 254,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
        ),
        const SizedBox(height: 18),
        FadeUpAnimation(
          delay: const Duration(milliseconds: 300),
          child: KidunaTextField(
            label: 'Password',
            placeholder: 'Enter your password',
            controller: _passwordController,
            focusNode: _passwordFocus,
            required: true,
            obscureText: !_showPassword,
            maxLength: 32,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _validate(),
            suffix: IconButton(
              onPressed: () {
                setState(() => _showPassword = !_showPassword);
                // The eye is an IconButton and takes focus when tapped;
                // without this the field is left unfocused and select-all
                // and copy have no target.
                _passwordFocus.requestFocus();
              },
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: colors.quiet,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        FadeUpAnimation(
          delay: const Duration(milliseconds: 350),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.isLoading ? null : widget.onForgotPassword,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: colors.sky,
                textStyle: const TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Forgot password?'),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FadeUpAnimation(
          delay: const Duration(milliseconds: 400),
          child: KidunaPrimaryButton(
            label: widget.isLoading ? 'Logging in...' : 'Log in',
            onPressed: _validate,
            isLoading: widget.isLoading,
          ),
        ),
        const SizedBox(height: 24),
        if (kIsWeb)
          FadeUpAnimation(
            delay: const Duration(milliseconds: 450),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Don\'t have an account? ',
                    style: text.body.copyWith(color: colors.muted, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: widget.isLoading ? null : widget.onCreateAccount,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: colors.sky,
                      textStyle: const TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Create account →'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

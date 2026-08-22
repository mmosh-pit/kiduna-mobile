import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../shared/animations/slide_in_animation.dart';
import '../../../shared/widgets/kiduna_primary_button.dart';
import '../../../shared/widgets/kiduna_text_field.dart';

class ForgotPasswordStepOne extends StatelessWidget {
  const ForgotPasswordStepOne({
    super.key,
    required this.onNext,
    required this.onBack,
    required this.onError,
    required this.emailController,
    this.isLoading = false,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;
  final ValueChanged<String> onError;
  final TextEditingController emailController;
  final bool isLoading;

  void _validate() {
    if (isLoading) return;

    final email = emailController.text.trim();

    if (email.isEmpty) {
      onError('Please enter your email address.');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      onError('Please enter a valid email address.');
      return;
    }

    onNext();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return SlideInAnimation(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackButton(onPressed: onBack),
          const SizedBox(height: 4),
          Text(
            'Reset your password',
            style: text.h2.copyWith(color: colors.text),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the email address associated with your account and we\'ll send you a 6-digit verification code.',
            style: text.body.copyWith(
              color: colors.muted,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          KidunaTextField(
            label: 'Email address',
            placeholder: 'name@example.com',
            controller: emailController,
            required: true,
            maxLength: 254,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _validate(),
          ),
          const SizedBox(height: 24),
          KidunaPrimaryButton(
            label: isLoading ? 'Sending code...' : 'Send reset code',
            onPressed: _validate,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return TextButton(
      onPressed: onPressed,
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
      child: const Text('← Back to Log in'),
    );
  }
}

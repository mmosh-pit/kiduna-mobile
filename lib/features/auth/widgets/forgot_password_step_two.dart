import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../shared/animations/slide_in_animation.dart';
import '../../../shared/widgets/kiduna_otp_field.dart';
import '../../../shared/widgets/kiduna_primary_button.dart';

class ForgotPasswordStepTwo extends StatefulWidget {
  const ForgotPasswordStepTwo({
    super.key,
    required this.email,
    required this.onNext,
    required this.onBack,
    required this.onResend,
    required this.onError,
    this.isLoading = false,
    this.isResending = false,
  });

  final String email;
  final ValueChanged<String> onNext;
  final VoidCallback onBack;
  final VoidCallback onResend;
  final ValueChanged<String> onError;
  final bool isLoading;

  /// Separate from [isLoading]: the resend link must not report progress
  /// for a verification happening beside it.
  final bool isResending;

  @override
  State<ForgotPasswordStepTwo> createState() => _ForgotPasswordStepTwoState();
}

class _ForgotPasswordStepTwoState extends State<ForgotPasswordStepTwo> {
  String _otpCode = '';

  void _validate() {
    if (widget.isLoading) return;

    if (_otpCode.length < 6) {
      widget.onError('Please enter the full 6-digit code.');
      return;
    }
    widget.onNext(_otpCode);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return SlideInAnimation(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackButton(onPressed: widget.onBack),
          const SizedBox(height: 4),
          Text(
            'Enter verification code',
            style: text.h2.copyWith(color: colors.text),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: text.body.copyWith(
                color: colors.muted,
                fontSize: 15,
                height: 1.6,
              ),
              children: [
                const TextSpan(text: 'We sent a 6-digit code to '),
                TextSpan(
                  text: widget.email.isEmpty ? 'your email' : widget.email,
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                  text: '. Enter it below to verify your identity.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          KidunaOtpField(
            onChanged: (code) => setState(() => _otpCode = code),
            onCompleted: (_) => _validate(),
          ),
          const SizedBox(height: 16),
          Text(
            'The code expires in 15 minutes. Check your spam folder if you don\'t see it.',
            style: text.body.copyWith(color: colors.quiet, fontSize: 11),
          ),
          const SizedBox(height: 16),
          KidunaPrimaryButton(
            label: widget.isLoading ? 'Verifying...' : 'Verify code',
            onPressed: _validate,
            isLoading: widget.isLoading,
          ),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Didn\'t get it? ',
                  style: text.body.copyWith(color: colors.muted, fontSize: 13),
                ),
                TextButton(
                  onPressed: widget.isResending ? null : widget.onResend,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: colors.sky,
                    // Explicit: the Material default is an unrelated grey,
                    // which reads as a state change rather than a busy link.
                    disabledForegroundColor: colors.sky.withValues(alpha: 0.5),
                    textStyle: const TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(widget.isResending ? 'Sending...' : 'Resend code'),
                ),
              ],
            ),
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
      child: const Text('← Back'),
    );
  }
}

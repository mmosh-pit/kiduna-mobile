import 'package:flutter/material.dart';

import '../../../config/env.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../shared/animations/slide_in_animation.dart';
import '../../../shared/widgets/kiduna_otp_field.dart';
import '../../../shared/widgets/kiduna_primary_button.dart';

class SignupStepFive extends StatefulWidget {
  const SignupStepFive({
    super.key,
    required this.formattedMobile,
    required this.onNext,
    required this.onBack,
    required this.onResend,
    required this.onError,
    this.isLoading = false,
  });

  /// Display string like "+91 6382987509"
  final String formattedMobile;
  final ValueChanged<String> onNext;
  final VoidCallback onBack;
  final VoidCallback onResend;
  final ValueChanged<String> onError;
  final bool isLoading;

  @override
  State<SignupStepFive> createState() => _SignupStepFiveState();
}

class _SignupStepFiveState extends State<SignupStepFive> {
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
          RichText(
            text: TextSpan(
              style: text.body.copyWith(
                color: colors.muted,
                fontSize: 13,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: 'Step 5 of 6',
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                  text: ' . Verify your mobile number. We sent a six-digit code to ',
                ),
                TextSpan(
                  text: widget.formattedMobile,
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!Env.isProduction) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colors.gold.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Dev mode: use code 000000',
                style: text.caption.copyWith(
                  color: colors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Enter your 6-digit code',
            style: text.caption.copyWith(
              color: colors.text,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          KidunaOtpField(
            onChanged: (code) => setState(() => _otpCode = code),
            onCompleted: (_) => _validate(),
          ),
          const SizedBox(height: 16),
          KidunaPrimaryButton(
            label: widget.isLoading ? 'Verifying...' : 'Verify and Continue',
            onPressed: _validate,
            isLoading: widget.isLoading,
          ),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Didn\'t get a code? ',
                  style: text.body.copyWith(
                    color: colors.muted,
                    fontSize: 13,
                  ),
                ),
                _LinkButton(
                  label: widget.isLoading ? 'Sending...' : 'Resend',
                  onPressed: widget.isLoading ? null : widget.onResend,
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

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

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
      child: Text(label),
    );
  }
}

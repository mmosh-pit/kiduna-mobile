import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../shared/animations/slide_in_animation.dart';
import '../../../shared/widgets/kiduna_otp_field.dart';
import '../../../shared/widgets/kiduna_primary_button.dart';

class SignupStepTwo extends StatefulWidget {
  const SignupStepTwo({
    super.key,
    required this.email,
    required this.onNext,
    required this.onBack,
    required this.onResend,
    required this.onError,
    this.isLoading = false,
  });

  final String email;
  final ValueChanged<String> onNext;
  final VoidCallback onBack;
  final VoidCallback onResend;
  final ValueChanged<String> onError;
  final bool isLoading;

  @override
  State<SignupStepTwo> createState() => _SignupStepTwoState();
}

class _SignupStepTwoState extends State<SignupStepTwo> {
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
                  text: 'Step 2 of 4',
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' — We sent a security code to '),
                TextSpan(
                  text: widget.email.isEmpty ? 'your email' : widget.email,
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
          _InstructionList(),
          const SizedBox(height: 16),
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
          Text(
            'The code expires in 15 minutes. Didn\'t get it? Check your spam folder or request a new code.',
            style: text.body.copyWith(color: colors.quiet, fontSize: 11),
          ),
          const SizedBox(height: 16),
          KidunaPrimaryButton(
            label: widget.isLoading ? 'Verifying...' : 'Verify & continue',
            onPressed: _validate,
            isLoading: widget.isLoading,
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Didn\'t get it? ',
                      style: text.body.copyWith(
                        color: colors.muted,
                        fontSize: 13,
                      ),
                    ),
                    _LinkButton(
                      label: widget.isLoading ? 'Sending...' : 'Resend code',
                      onPressed: widget.isLoading ? null : widget.onResend,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Or ',
                      style: text.body.copyWith(
                        color: colors.muted,
                        fontSize: 13,
                      ),
                    ),
                    _LinkButton(
                      label: 'try a different email address',
                      onPressed: widget.onBack,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    final items = [
      'Open your email',
      null,
      'Enter the code below to confirm it\'s you',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    '${i + 1}.',
                    style: text.bodySm.copyWith(
                      color: colors.muted,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: i == 1
                      ? RichText(
                          text: TextSpan(
                            style: text.bodySm.copyWith(
                              color: colors.muted,
                              fontSize: 14,
                              height: 1.7,
                            ),
                            children: [
                              const TextSpan(text: 'Look for a message from '),
                              TextSpan(
                                text: 'security@kiduna.ai',
                                style: TextStyle(
                                  color: colors.text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Text(
                          items[i] ?? '',
                          style: text.bodySm.copyWith(
                            color: colors.muted,
                            fontSize: 14,
                            height: 1.7,
                          ),
                        ),
                ),
              ],
            ),
          ),
      ],
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

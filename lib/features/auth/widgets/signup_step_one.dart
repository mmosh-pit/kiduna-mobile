import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../shared/animations/slide_in_animation.dart';
import '../../../shared/widgets/kiduna_primary_button.dart';
import '../../../shared/widgets/kiduna_text_field.dart';

class SignupStepOne extends StatefulWidget {
  const SignupStepOne({
    super.key,
    required this.onNext,
    required this.onLogin,
    required this.onError,
    required this.nameController,
    required this.emailController,
    this.isLoading = false,
  });

  final VoidCallback onNext;
  final VoidCallback onLogin;
  final ValueChanged<String> onError;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final bool isLoading;

  @override
  State<SignupStepOne> createState() => _SignupStepOneState();
}

class _SignupStepOneState extends State<SignupStepOne> {
  final _emailFocus = FocusNode();
  bool _consentChecked = false;

  @override
  void dispose() {
    _emailFocus.dispose();
    super.dispose();
  }

  void _validate() {
    if (widget.isLoading) return;

    final name = widget.nameController.text.trim();
    final email = widget.emailController.text.trim();

    if (name.isEmpty) {
      widget.onError('Please enter your code name.');
      return;
    }
    if (email.isEmpty) {
      widget.onError('Please enter your email address.');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      widget.onError('Please enter a valid email address.');
      return;
    }
    if (!_consentChecked) {
      widget.onError('Please accept the Privacy Policy and Terms of Service.');
      return;
    }

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return SlideInAnimation(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: text.body.copyWith(
                color: colors.muted,
                fontSize: 13,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: 'Step 1 of 4',
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                  text: ' · Enter your name and email address. We\'ll send a 6-digit code to verify your email.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          KidunaTextField(
            label: 'Your code name',
            placeholder: 'What you want to be called',
            controller: widget.nameController,
            required: true,
            maxLength: 20,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _emailFocus.requestFocus(),
          ),
          const SizedBox(height: 18),
          KidunaTextField(
            label: 'Email address',
            placeholder: 'name@example.com',
            controller: widget.emailController,
            focusNode: _emailFocus,
            required: true,
            maxLength: 254,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _validate(),
          ),
          const SizedBox(height: 12),
          _ConsentCheckbox(
            value: _consentChecked,
            onChanged: (value) {
              setState(() => _consentChecked = value);
            },
          ),
          const SizedBox(height: 20),
          KidunaPrimaryButton(
            label: widget.isLoading
                ? 'Sending code...'
                : 'Send me the 6-digit code',
            onPressed: _validate,
            isLoading: widget.isLoading,
          ),
          const SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Already have an account? ',
                  style: text.body.copyWith(color: colors.muted, fontSize: 13),
                ),
                TextButton(
                  onPressed: widget.isLoading ? null : widget.onLogin,
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
                  child: const Text('Log in →'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentCheckbox extends StatelessWidget {
  const _ConsentCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: colors.sky,
              side: BorderSide(color: colors.camel.withValues(alpha: 0.5)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: text.caption.copyWith(
                  color: colors.muted,
                  fontSize: 12,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(
                    text: 'By continuing, I agree to receive communications from Kiduna with the understanding I can unsubscribe anytime. I have reviewed the ',
                  ),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(color: colors.sky),
                  ),
                  const TextSpan(text: ' and accept the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(color: colors.sky),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

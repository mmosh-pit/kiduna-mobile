import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../legal/screens/privacy_policy_screen.dart';
import '../../legal/screens/terms_of_service_screen.dart';
import '../../../shared/animations/slide_in_animation.dart';
import '../../../shared/widgets/kiduna_primary_button.dart';
import '../../../shared/widgets/kiduna_text_field.dart';

class SignupStepOne extends StatefulWidget {
  const SignupStepOne({
    super.key,
    required this.onNext,
    required this.onLogin,
    required this.onError,
    required this.consentChecked,
    required this.onConsentChanged,
    required this.nameController,
    required this.emailController,
    this.isLoading = false,
  });

  final VoidCallback onNext;
  final VoidCallback onLogin;
  final ValueChanged<String> onError;
  /// Owned by the signup screen so it survives navigating between steps.
  final bool consentChecked;
  final ValueChanged<bool> onConsentChanged;

  final TextEditingController nameController;
  final TextEditingController emailController;
  final bool isLoading;

  @override
  State<SignupStepOne> createState() => _SignupStepOneState();
}

class _SignupStepOneState extends State<SignupStepOne> {
  final _emailFocus = FocusNode();

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
      widget.onError('Please enter your name.');
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
    if (!widget.consentChecked) {
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
                  text: 'Step 1 of 7',
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
            label: 'Your name',
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
            value: widget.consentChecked,
            onChanged: widget.onConsentChanged,
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

class _ConsentCheckbox extends StatefulWidget {
  const _ConsentCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  State<_ConsentCheckbox> createState() => _ConsentCheckboxState();
}

class _ConsentCheckboxState extends State<_ConsentCheckbox> {
  /// Held as fields rather than built inline: a recognizer created in
  /// build() is reallocated every frame and never disposed.
  late final TapGestureRecognizer _privacyTap;
  late final TapGestureRecognizer _termsTap;

  @override
  void initState() {
    super.initState();
    _privacyTap = TapGestureRecognizer()
      ..onTap = () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PrivacyPolicyScreen(),
            ),
          );
    _termsTap = TapGestureRecognizer()
      ..onTap = () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TermsOfServiceScreen(),
            ),
          );
  }

  @override
  void dispose() {
    _privacyTap.dispose();
    _termsTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: Checkbox(
              value: widget.value,
              onChanged: (v) => widget.onChanged(v ?? false),
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
                    style: TextStyle(
                      color: colors.sky,
                      decoration: TextDecoration.underline,
                      decorationColor: colors.sky,
                    ),
                    recognizer: _privacyTap,
                  ),
                  const TextSpan(text: ' and accept the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: colors.sky,
                      decoration: TextDecoration.underline,
                      decorationColor: colors.sky,
                    ),
                    recognizer: _termsTap,
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
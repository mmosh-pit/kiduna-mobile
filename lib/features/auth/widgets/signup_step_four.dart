import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../shared/animations/slide_in_animation.dart';
import '../../../shared/widgets/kiduna_primary_button.dart';
import '../../../shared/widgets/kiduna_secondary_button.dart';
import '../../../shared/widgets/kiduna_text_field.dart';

class SignupStepFour extends StatefulWidget {
  const SignupStepFour({
    super.key,
    required this.onComplete,
    required this.onBack,
    required this.onError,
    required this.kinshipCodeController,
    required this.handshakeController,
    this.isLoading = false,
  });

  final VoidCallback onComplete;
  final VoidCallback onBack;
  final ValueChanged<String> onError;
  final TextEditingController kinshipCodeController;
  final TextEditingController handshakeController;
  final bool isLoading;

  @override
  State<SignupStepFour> createState() => _SignupStepFourState();
}

class _SignupStepFourState extends State<SignupStepFour> {
  final _handshakeFocus = FocusNode();

  @override
  void dispose() {
    _handshakeFocus.dispose();
    super.dispose();
  }

  void _validate() {
    if (widget.isLoading) return;

    final code = widget.kinshipCodeController.text.trim();

    if (code.isEmpty) {
      widget.onError('Please enter a Kinship Code.');
      return;
    }

    widget.onComplete();
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
                  text: 'Step 4 of 4',
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' · Make a Connection'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Privacy, trust, and relationships are at the heart of Kiduna. Enter a unique Kinship Code and a Private Handshake to establish your first connection.',
            style: text.body.copyWith(
              color: colors.muted,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          KidunaTextField(
            label: 'Enter a Kinship Code',
            placeholder: 'XXX—XXX—XXX',
            controller: widget.kinshipCodeController,
            required: true,
            maxLength: 20,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _handshakeFocus.requestFocus(),
          ),
          const SizedBox(height: 20),
          KidunaTextField(
            label: 'Enter a Private Handshake',
            controller: widget.handshakeController,
            focusNode: _handshakeFocus,
            maxLength: 120,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _validate(),
          ),
          const SizedBox(height: 24),
          KidunaPrimaryButton(
            label: widget.isLoading
                ? 'Creating your account...'
                : 'Enter Kiduna!',
            onPressed: _validate,
            isLoading: widget.isLoading,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.line)),
            ),
            child: Column(
              children: [
                Text(
                  'Don\'t have a relationship with a current member?',
                  style: text.body.copyWith(color: colors.muted, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                KidunaSecondaryButton(
                  label: 'Join Our Online Communities to Meet One',
                  onPressed: () {},
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

import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../shared/animations/slide_in_animation.dart';
import '../../../shared/widgets/kiduna_primary_button.dart';
import '../../../shared/widgets/kiduna_text_field.dart';

class ForgotPasswordStepThree extends StatefulWidget {
  const ForgotPasswordStepThree({
    super.key,
    required this.onSubmit,
    required this.onBack,
    required this.onError,
    required this.passwordController,
    required this.confirmPasswordController,
    this.isLoading = false,
  });

  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final ValueChanged<String> onError;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isLoading;

  @override
  State<ForgotPasswordStepThree> createState() =>
      _ForgotPasswordStepThreeState();
}

class _ForgotPasswordStepThreeState extends State<ForgotPasswordStepThree> {
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _validate() {
    if (widget.isLoading) return;

    final password = widget.passwordController.text;
    final confirm = widget.confirmPasswordController.text;

    if (password.isEmpty) {
      widget.onError('Please enter a new password.');
      return;
    }
    if (password.length < 12) {
      widget.onError('Password must be at least 12 characters.');
      return;
    }
    if (confirm.isEmpty) {
      widget.onError('Please confirm your new password.');
      return;
    }
    if (password != confirm) {
      widget.onError('Passwords do not match.');
      return;
    }

    widget.onSubmit();
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
          Text('Set new password', style: text.h2.copyWith(color: colors.text)),
          const SizedBox(height: 8),
          Text(
            'Use at least 12 characters. Longer is stronger. You can use letters, numbers, symbols, or a passphrase.',
            style: text.body.copyWith(
              color: colors.muted,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          KidunaTextField(
            label: 'New password',
            placeholder: 'At least 12 characters',
            controller: widget.passwordController,
            required: true,
            focusNode: _passwordFocus,
            obscureText: !_showPassword,
            maxLength: 32,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _confirmFocus.requestFocus(),
            suffix: _ToggleVisibilityButton(
              visible: _showPassword,
              onPressed: () {
                setState(() => _showPassword = !_showPassword);
                // The eye is an IconButton and takes focus when tapped;
                // without this the field is left unfocused and select-all
                // and copy have no target.
                _passwordFocus.requestFocus();
              },
            ),
          ),
          const SizedBox(height: 18),
          KidunaTextField(
            label: 'Confirm new password',
            placeholder: 'Re-enter your new password',
            controller: widget.confirmPasswordController,
            focusNode: _confirmFocus,
            required: true,
            obscureText: !_showConfirmPassword,
            maxLength: 32,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _validate(),
            suffix: _ToggleVisibilityButton(
              visible: _showConfirmPassword,
              onPressed: () {
                setState(() => _showConfirmPassword = !_showConfirmPassword);
                _confirmFocus.requestFocus();
              },
            ),
          ),
          const SizedBox(height: 24),
          KidunaPrimaryButton(
            label: widget.isLoading
                ? 'Resetting password...'
                : 'Reset password',
            onPressed: _validate,
            isLoading: widget.isLoading,
          ),
        ],
      ),
    );
  }
}

class _ToggleVisibilityButton extends StatelessWidget {
  const _ToggleVisibilityButton({
    required this.visible,
    required this.onPressed,
  });

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
        color: colors.quiet,
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

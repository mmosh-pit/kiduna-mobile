import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../enums/auth_status.dart';

/// The login form — email, password, and submit button.
///
/// [onSubmit] is called with `(email, password)` when the form is valid.
/// [status] and [error] drive the loading spinner and error message.
class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
    required this.onSubmit,
    required this.status,
    this.error,
  });

  final void Function(String email, String password) onSubmit;
  final AuthStatus status;
  final String? error;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String? _localError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty) {
      setState(() => _localError = context.l10n.emailRequired);
      return;
    }
    if (password.isEmpty) {
      setState(() => _localError = context.l10n.passwordRequired);
      return;
    }

    setState(() => _localError = null);
    widget.onSubmit(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final isLoading = widget.status == AuthStatus.loading;
    final displayError = _localError ?? widget.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Email ────────────────────────────────────────────────────
        Text(
          context.l10n.emailLabel,
          style: text.label.copyWith(color: colors.cream),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enabled: !isLoading,
          style: text.body.copyWith(color: colors.text),
          decoration: _inputDecoration(context, hint: context.l10n.emailHint),
        ),

        const SizedBox(height: 16),

        // ── Password ─────────────────────────────────────────────────
        Text(
          context.l10n.passwordLabel,
          style: text.label.copyWith(color: colors.cream),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _password,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          enabled: !isLoading,
          onSubmitted: (_) => _submit(),
          style: text.body.copyWith(color: colors.text),
          decoration: _inputDecoration(
            context,
            hint: context.l10n.passwordHint,
            suffix: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: colors.quiet,
              ),
            ),
          ),
        ),

        // ── Error ────────────────────────────────────────────────────
        if (displayError != null) ...[
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, size: 16, color: colors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayError,
                  style: text.bodySmall.copyWith(
                    color: colors.gold,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),

        // ── Submit ───────────────────────────────────────────────────
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.sky,
              foregroundColor: colors.skyButtonInk,
              disabledBackgroundColor: colors.sky.withValues(alpha: 0.4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colors.skyButtonInk,
                    ),
                  )
                : Text(
                    context.l10n.logIn,
                    style: text.body.copyWith(
                      color: colors.skyButtonInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    Widget? suffix,
  }) {
    final colors = context.kiduna;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: colors.camel.withValues(alpha: 0.28)),
    );
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: colors.surface,
      hintText: hint,
      hintStyle: context.kidunaText.body.copyWith(color: colors.quiet),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: BorderSide(color: colors.sky)),
      disabledBorder: border.copyWith(
        borderSide: BorderSide(color: colors.camel.withValues(alpha: 0.14)),
      ),
      suffixIcon: suffix,
    );
  }
}

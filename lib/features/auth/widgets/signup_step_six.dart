import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../shared/animations/slide_in_animation.dart';
import '../../../shared/widgets/kiduna_primary_button.dart';
import '../../../shared/widgets/kiduna_secondary_button.dart';
import '../../../shared/widgets/kiduna_text_field.dart';

class SignupStepSix extends StatefulWidget {
  const SignupStepSix({
    super.key,
    required this.onComplete,
    required this.onBack,
    required this.onError,
    required this.inviteCodeController,
    this.isLoading = false,
    this.previewInfo,
  });

  final VoidCallback onComplete;
  final VoidCallback onBack;
  final ValueChanged<String> onError;
  final TextEditingController inviteCodeController;
  final bool isLoading;

  /// Preview info shown after code validation (realm name, role, etc.)
  final Map<String, dynamic>? previewInfo;

  @override
  State<SignupStepSix> createState() => _SignupStepSixState();
}

class _SignupStepSixState extends State<SignupStepSix> {
  void _validate() {
    if (widget.isLoading) return;

    final code = widget.inviteCodeController.text.trim();

    if (code.isEmpty) {
      widget.onError('Please enter an Invitation Code.');
      return;
    }

    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final preview = widget.previewInfo;

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
                  text: 'Step 6 of 6',
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' · Join a Community'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the Invitation Code you received from a current member to join their community and start your Kiduna journey.',
            style: text.body.copyWith(
              color: colors.muted,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          KidunaTextField(
            label: 'Enter an Invitation Code',
            placeholder: 'RLM-XXXXXX',
            controller: widget.inviteCodeController,
            required: true,
            maxLength: 20,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _validate(),
          ),

          // Show preview info when available
          if (preview != null && preview['valid'] == true) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colors.gold.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (preview['realm'] != null) ...[
                    Text(
                      preview['realm']['name'] as String? ?? '',
                      style: text.body.copyWith(
                        color: colors.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(preview['realm']['type'] as String? ?? 'realm').toUpperCase()} · Role: ${preview['role'] ?? 'member'}',
                      style: text.caption.copyWith(
                        color: colors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (preview['inviter'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Invited by ${preview['inviter']['name'] ?? 'a member'}',
                      style: text.caption.copyWith(
                        color: colors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          KidunaPrimaryButton(
            label: widget.isLoading ? 'Joining...' : 'Enter Kiduna!',
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
                  'Don\'t have an invitation from a current member?',
                  style: text.body.copyWith(color: colors.muted, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                KidunaSecondaryButton(
                  label: 'Join Our Online Communities to Get One',
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
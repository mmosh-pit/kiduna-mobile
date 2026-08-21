import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../shared/animations/slide_in_animation.dart';
import '../../../shared/widgets/kiduna_primary_button.dart';
import '../../../shared/widgets/kiduna_text_field.dart';

class SignupStepFour extends StatefulWidget {
  const SignupStepFour({
    super.key,
    required this.onNext,
    required this.onBack,
    required this.onError,
    required this.mobileController,
    this.isLoading = false,
  });

  final ValueChanged<String> onNext;
  final VoidCallback onBack;
  final ValueChanged<String> onError;
  final TextEditingController mobileController;
  final bool isLoading;

  @override
  State<SignupStepFour> createState() => _SignupStepFourState();
}

class _SignupStepFourState extends State<SignupStepFour> {
  String _selectedCountryCode = '+1';

  final _countryCodes = const [
    ('+1', '🇺🇸', 'US'),
    ('+44', '🇬🇧', 'UK'),
    ('+91', '🇮🇳', 'IN'),
    ('+61', '🇦🇺', 'AU'),
    ('+49', '🇩🇪', 'DE'),
    ('+33', '🇫🇷', 'FR'),
    ('+81', '🇯🇵', 'JP'),
    ('+86', '🇨🇳', 'CN'),
    ('+82', '🇰🇷', 'KR'),
    ('+55', '🇧🇷', 'BR'),
    ('+52', '🇲🇽', 'MX'),
    ('+234', '🇳🇬', 'NG'),
    ('+27', '🇿🇦', 'ZA'),
    ('+971', '🇦🇪', 'UAE'),
    ('+65', '🇸🇬', 'SG'),
  ];

  void _validate() {
    if (widget.isLoading) return;

    final mobile = widget.mobileController.text.trim();
    if (mobile.isEmpty) {
      widget.onError('Please enter your mobile number.');
      return;
    }
    if (mobile.length < 7) {
      widget.onError('Please enter a valid mobile number.');
      return;
    }

    // Pass countryCode + mobile as combined string for backend
    final countryCodeDigits = _selectedCountryCode.replaceAll('+', '');
    widget.onNext('$countryCodeDigits|$mobile');
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
                  text: 'Step 4 of 6',
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                  text:
                      '— Enter your mobile number. We\'ll send a 6-digit code by text to verify and continue.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Mobile number',
            style: text.caption.copyWith(
              color: colors.text,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          Text(
            ' *',
            style: text.caption.copyWith(
              color: colors.error,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: colors.deep.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colors.camel.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                // Country code dropdown
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: colors.camel.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCountryCode,
                      dropdownColor: colors.raised,
                      style: text.body.copyWith(
                        color: colors.text,
                        fontSize: 14,
                      ),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: colors.muted,
                        size: 20,
                      ),
                      items: _countryCodes.map((cc) {
                        return DropdownMenuItem<String>(
                          value: cc.$1,
                          child: Text(
                            '${cc.$2} ${cc.$1}',
                            style: text.body.copyWith(
                              color: colors.text,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCountryCode = value);
                        }
                      },
                    ),
                  ),
                ),
                // Mobile number input
                Expanded(
                  child: TextField(
                    controller: widget.mobileController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _validate(),
                    style: text.body.copyWith(
                      color: colors.text,
                      fontSize: 15,
                    ),
                    cursorColor: colors.sky,
                    decoration: InputDecoration(
                      hintText: 'Mobile number',
                      hintStyle: text.body.copyWith(
                        color: colors.quiet,
                        fontSize: 15,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          KidunaPrimaryButton(
            label: widget.isLoading ? 'Sending code...' : 'Send code',
            onPressed: _validate,
            isLoading: widget.isLoading,
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

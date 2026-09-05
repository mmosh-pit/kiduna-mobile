import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/validators/phone_validator.dart';
import '../../../shared/animations/slide_in_animation.dart';
import '../../../shared/widgets/kiduna_primary_button.dart';

class SignupStepFour extends StatefulWidget {
  const SignupStepFour({
    super.key,
    required this.onNext,
    required this.onBack,
    required this.onError,
    required this.countryCode,
    required this.onCountryChanged,
    required this.mobileController,
    this.isLoading = false,
  });

  final ValueChanged<String> onNext;
  final VoidCallback onBack;
  final ValueChanged<String> onError;
  /// Owned by the signup screen so the choice survives stepping back from
  /// the OTP screen — the number is kept in a controller for the same reason.
  final String countryCode;
  final ValueChanged<String> onCountryChanged;

  final TextEditingController mobileController;
  final bool isLoading;

  @override
  State<SignupStepFour> createState() => _SignupStepFourState();
}

class _SignupStepFourState extends State<SignupStepFour> {


  CountryPhoneRule get _rule =>
      findCountryRule(widget.countryCode) ?? countryPhoneRules.first;

  void _validate() {
    if (widget.isLoading) return;

    final result = validateMobileNumber(
      widget.countryCode,
      widget.mobileController.text,
    );

    if (!result.valid) {
      widget.onError(result.error ?? 'Please enter a valid mobile number.');
      return;
    }

    // Send the normalized digits, not the raw input: the user may have typed
    // spaces, a trunk zero, or the country code again.
    final countryCodeDigits = widget.countryCode.replaceAll('+', '');
    widget.onNext('$countryCodeDigits|${result.normalized}');
  }

  /// Expected format for the selected country, shown under the field so the
  /// requirement is visible before submitting rather than after.
  String get _formatHint {
    final r = _rule;
    final lengths = r.lengths.length == 1
        ? '${r.lengths.first} digits'
        : '${r.lengths.join(' or ')} digits';
    final prefixes = r.mobilePrefixes;
    if (prefixes == null || prefixes.length > 4) {
      return '${r.name} mobile numbers are $lengths';
    }
    return '${r.name} mobile numbers are $lengths, starting with '
        '${prefixes.join(', ')}';
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
                  text: 'Step 4 of 7',
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
          Row(
            children: [
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
            ],
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
                      value: widget.countryCode,
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
                      items: countryPhoneRules.map((cc) {
                        return DropdownMenuItem<String>(
                          value: cc.code,
                          child: Text(
                            '${cc.flag} ${cc.code}',
                            style: text.body.copyWith(
                              color: colors.text,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        // A number valid for the old country is unlikely to
                        // be valid for the new one.
                        widget.mobileController.clear();
                        widget.onCountryChanged(value);
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
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _validate(),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(_rule.maxLength),
                    ],
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
          const SizedBox(height: 8),
          Text(
            _formatHint,
            style: text.caption.copyWith(
              color: colors.quiet,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
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
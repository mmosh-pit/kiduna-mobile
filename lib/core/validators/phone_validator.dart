/// Per-country mobile number rules.
///
/// Mirrors `phone-validation.ts` on the backend. Duplicated deliberately:
/// the backend check is the one that matters, but repeating it here means a
/// bad number is caught before it costs an API round trip and an SMS.
///
/// Numbers vary by country in both length and leading digit — an Indian
/// mobile is ten digits starting 6–9, a UK mobile ten starting 7. A single
/// minimum-length check accepts numbers that can never receive an SMS, which
/// then surfaces as "I never got the code" rather than a form error.
class CountryPhoneRule {
  const CountryPhoneRule({
    required this.code,
    required this.flag,
    required this.label,
    required this.name,
    required this.lengths,
    this.mobilePrefixes,
  });

  /// Dial code with the leading +.
  final String code;
  final String flag;

  /// Short label for the dropdown.
  final String label;

  /// Full name, used in error messages.
  final String name;

  /// Valid national number lengths, excluding the country code.
  final List<int> lengths;

  /// Optional first-digit constraint for mobile numbers.
  final List<String>? mobilePrefixes;

  String get digitsOnly => code.replaceAll('+', '');

  /// Longest number this country accepts, for input length capping.
  int get maxLength => lengths.reduce((a, b) => a > b ? a : b);
}

const countryPhoneRules = <CountryPhoneRule>[
  CountryPhoneRule(
    code: '+1', flag: '🇺🇸', label: 'US', name: 'US/Canada',
    lengths: [10],
    mobilePrefixes: ['2', '3', '4', '5', '6', '7', '8', '9'],
  ),
  CountryPhoneRule(
    code: '+44', flag: '🇬🇧', label: 'UK', name: 'UK',
    lengths: [10], mobilePrefixes: ['7'],
  ),
  CountryPhoneRule(
    code: '+91', flag: '🇮🇳', label: 'IN', name: 'Indian',
    lengths: [10], mobilePrefixes: ['6', '7', '8', '9'],
  ),
  CountryPhoneRule(
    code: '+61', flag: '🇦🇺', label: 'AU', name: 'Australian',
    lengths: [9], mobilePrefixes: ['4'],
  ),
  CountryPhoneRule(
    code: '+49', flag: '🇩🇪', label: 'DE', name: 'German',
    lengths: [10, 11], mobilePrefixes: ['1'],
  ),
  CountryPhoneRule(
    code: '+33', flag: '🇫🇷', label: 'FR', name: 'French',
    lengths: [9], mobilePrefixes: ['6', '7'],
  ),
  CountryPhoneRule(
    code: '+81', flag: '🇯🇵', label: 'JP', name: 'Japanese',
    lengths: [10], mobilePrefixes: ['7', '8', '9'],
  ),
  CountryPhoneRule(
    code: '+86', flag: '🇨🇳', label: 'CN', name: 'Chinese',
    lengths: [11], mobilePrefixes: ['1'],
  ),
  CountryPhoneRule(
    code: '+82', flag: '🇰🇷', label: 'KR', name: 'South Korean',
    lengths: [9, 10], mobilePrefixes: ['1'],
  ),
  CountryPhoneRule(
    code: '+55', flag: '🇧🇷', label: 'BR', name: 'Brazilian',
    lengths: [10, 11],
  ),
  CountryPhoneRule(
    code: '+52', flag: '🇲🇽', label: 'MX', name: 'Mexican',
    lengths: [10],
  ),
  CountryPhoneRule(
    code: '+234', flag: '🇳🇬', label: 'NG', name: 'Nigerian',
    lengths: [10], mobilePrefixes: ['7', '8', '9'],
  ),
  CountryPhoneRule(
    code: '+27', flag: '🇿🇦', label: 'ZA', name: 'South African',
    lengths: [9], mobilePrefixes: ['6', '7', '8'],
  ),
  CountryPhoneRule(
    code: '+971', flag: '🇦🇪', label: 'UAE', name: 'UAE',
    lengths: [9], mobilePrefixes: ['5'],
  ),
  CountryPhoneRule(
    code: '+65', flag: '🇸🇬', label: 'SG', name: 'Singapore',
    lengths: [8], mobilePrefixes: ['8', '9'],
  ),
];

class PhoneValidationResult {
  const PhoneValidationResult({
    required this.valid,
    this.error,
    required this.normalized,
  });

  final bool valid;
  final String? error;

  /// Digits only, with any leading zero or duplicated country code stripped.
  final String normalized;
}

CountryPhoneRule? findCountryRule(String code) {
  final normalized = code.startsWith('+') ? code : '+$code';
  for (final r in countryPhoneRules) {
    if (r.code == normalized) return r;
  }
  return null;
}

/// Validate a national mobile number against its country's rules.
///
/// Normalises first: people paste numbers with spaces, dashes, a leading
/// zero as written domestically, or the country code repeated. Rejecting
/// those would be technically correct and needlessly unhelpful.
PhoneValidationResult validateMobileNumber(String countryCode, String mobile) {
  final code = countryCode.replaceAll('+', '').trim();
  var digits = mobile.replaceAll(RegExp(r'\D'), '');

  if (digits.isEmpty) {
    return const PhoneValidationResult(
      valid: false,
      error: 'Please enter your mobile number.',
      normalized: '',
    );
  }

  // Country code typed into the number field as well.
  if (digits.startsWith(code) && digits.length > code.length) {
    digits = digits.substring(code.length);
  }

  // Trunk prefix — written domestically, dropped for international dialling.
  if (digits.startsWith('0')) {
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
  }

  final rule = findCountryRule(code);

  // No rule for this code: fall back to a permissive range rather than
  // rejecting a real number we simply don't have data for.
  if (rule == null) {
    if (digits.length < 6 || digits.length > 14) {
      return PhoneValidationResult(
        valid: false,
        error: 'Please enter a valid mobile number.',
        normalized: digits,
      );
    }
    return PhoneValidationResult(valid: true, normalized: digits);
  }

  if (!rule.lengths.contains(digits.length)) {
    final expected = rule.lengths.length == 1
        ? '${rule.lengths.first} digits'
        : '${rule.lengths.join(' or ')} digits';
    return PhoneValidationResult(
      valid: false,
      error: '${rule.name} mobile numbers are $expected.',
      normalized: digits,
    );
  }

  final prefixes = rule.mobilePrefixes;
  if (prefixes != null && !prefixes.contains(digits[0])) {
    return PhoneValidationResult(
      valid: false,
      error: 'That does not look like a ${rule.name} mobile number.',
      normalized: digits,
    );
  }

  return PhoneValidationResult(valid: true, normalized: digits);
}

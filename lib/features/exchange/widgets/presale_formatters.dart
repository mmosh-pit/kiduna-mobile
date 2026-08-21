/// Formatting helpers shared across presale widgets (card, detail, buy sheet).

/// Abbreviates large numbers (e.g. "2000000000" → "2.0B").
String formatTokenNumber(String value) {
  final n = num.tryParse(value);
  if (n == null) return value;
  if (n >= 1e9) return '${(n / 1e9).toStringAsFixed(1)}B';
  if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
  if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(1)}K';
  return n.toStringAsFixed(0);
}

/// Full number with commas (e.g. "2000000000" → "2,000,000,000").
String formatTokenNumberFull(String value) {
  final n = num.tryParse(value);
  if (n == null) return value;
  final s = n.toStringAsFixed(0);
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Formats price, trimming trailing zeros (e.g. "0.010000000000" → "0.01").
String formatPrice(String value) {
  final n = double.tryParse(value);
  if (n == null) return value;
  if (n >= 1) return n.toStringAsFixed(2);
  final s = n.toStringAsFixed(12).replaceAll(RegExp(r'0+$'), '');
  return s.endsWith('.') ? '${s}0' : s;
}

/// Formats USDC amount (e.g. "10.000000" → "10", "5.50" → "5.50").
String formatUsdc(String value) {
  final n = double.tryParse(value);
  if (n == null) return value;
  return n == n.truncateToDouble()
      ? n.toStringAsFixed(0)
      : n.toStringAsFixed(2);
}

/// Formats ISO date to short form (e.g. "2026-09-01T00:00:00.000Z" → "Sep 1").
String formatDate(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}';
}

/// Formats ISO date with year (e.g. "Sep 1, 2026").
String formatDateFull(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

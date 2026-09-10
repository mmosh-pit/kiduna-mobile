import 'package:flutter/material.dart';

/// The six gem-themed chip denominations used in Medieval Poker.
enum ChipType {
  gold(value: 1000, label: 'Gold', color: Color(0xFFD4A84B), edgeColor: Color(0xFFB8923A), asset: 'assets/images/chips/chip_gold.png'),
  sapphire(value: 500, label: 'Sapphire', color: Color(0xFF3B6BB5), edgeColor: Color(0xFF2A5090), asset: 'assets/images/chips/chip_sapphire.png'),
  onyx(value: 100, label: 'Onyx', color: Color(0xFF2A2A2A), edgeColor: Color(0xFF111111), asset: 'assets/images/chips/chip_onyx.png'),
  emerald(value: 25, label: 'Emerald', color: Color(0xFF2D8F4E), edgeColor: Color(0xFF1D6B38), asset: 'assets/images/chips/chip_emerald.png'),
  ruby(value: 5, label: 'Ruby', color: Color(0xFFC0392B), edgeColor: Color(0xFF962D22), asset: 'assets/images/chips/chip_ruby.png'),
  opal(value: 1, label: 'Opal', color: Color(0xFFD5D0C8), edgeColor: Color(0xFFB0AAA0), asset: 'assets/images/chips/chip_opal.png');

  const ChipType({
    required this.value,
    required this.label,
    required this.color,
    required this.edgeColor,
    required this.asset,
  });

  final int value;
  final String label;
  final Color color;
  final Color edgeColor;
  final String asset;

  /// Large asset path for mode selector display.
}

/// A count of one chip denomination.
class ChipStack {
  const ChipStack(this.type, this.count);
  final ChipType type;
  final int count;
}

/// Breaks a total value into gem-denominated chip stacks (largest first).
/// Example: 2500 → [Gold×2, Sapphire×1]
List<ChipStack> breakdownChips(int total) {
  if (total <= 0) return [];
  final result = <ChipStack>[];
  var remaining = total;
  for (final type in ChipType.values) {
    if (remaining >= type.value) {
      final count = remaining ~/ type.value;
      result.add(ChipStack(type, count));
      remaining %= type.value;
    }
  }
  return result;
}

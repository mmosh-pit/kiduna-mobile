import 'package:flutter/material.dart';

/// A single section in the app's section bar.
@immutable
class SectionItem {
  const SectionItem({required this.label, this.icon});

  /// Display label shown in the section bar.
  final String label;

  /// Optional icon displayed alongside the label.
  final IconData? icon;
}

/// The nine app sections. Index 0 (Exchange) is the default.
const List<SectionItem> kSections = [
  SectionItem(label: 'Exchange'),
  SectionItem(label: 'Forum'),
  SectionItem(label: 'Governance'),
  SectionItem(label: 'Studio'),
  SectionItem(label: 'Commons'),
  SectionItem(label: 'Viewport'),
  SectionItem(label: 'Enjoy'),
  SectionItem(label: 'Act'),
  SectionItem(label: 'Store'),
];

/// Index constants for readability.
abstract class SectionIndex {
  static const int exchange = 0;
  static const int forum = 1;
  static const int governance = 2;
  static const int studio = 3;
  static const int commons = 4;
  static const int viewport = 5;
  static const int enjoy = 6;
  static const int act = 7;
  static const int store = 8;
}

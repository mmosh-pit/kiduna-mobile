/// Reads a fixture from `assets/fixtures/`.
///
/// The four fixtures are the contract's proof: `alice` is the visual acceptance
/// reference, `coverage` populates every schema field, `empty` is the
/// newly-created Ecosystem, and `edge` carries the cases that must degrade
/// rather than throw.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'field_source.dart';
import 'models.dart';

enum Fixture {
  /// All 34 of Alice's Realms — matches the live page.
  alice('alice-snapshot.json'),

  /// Every enum value and optional field populated.
  coverage('coverage-snapshot.json'),

  /// Zero Realms. The NCEV case.
  empty('empty-snapshot.json'),

  /// Single-realm cluster, missing bridge endpoints, overlong name,
  /// all-optionals-absent, and an unrecognised Realm type.
  edge('edge-snapshot.json'),

  /// Twenty clusters and sixty Realms — the scale prototype. Synthetic: it
  /// exists to ask how a Field with twenty working groupings stays
  /// intelligible, not to describe any real Ecosystem.
  many('many-snapshot.json');

  const Fixture(this.filename);

  final String filename;

  String get path => 'assets/fixtures/$filename';
}

class MockFieldSource with FieldEventSink implements FieldSource {
  MockFieldSource([this.fixture = Fixture.alice]);

  final Fixture fixture;

  @override
  Future<FieldSnapshot> load() async {
    final raw = await rootBundle.loadString(fixture.path);
    return FieldSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}

/// Parses a snapshot already in memory — used by tests, which read the
/// fixtures from disk rather than through the asset bundle.
FieldSnapshot parseSnapshot(String raw) =>
    FieldSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);

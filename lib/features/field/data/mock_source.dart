import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'field_models.dart';
import 'field_source.dart';

enum Fixture {
  alice('alice-snapshot.json'),
  coverage('coverage-snapshot.json'),
  empty('empty-snapshot.json'),
  edge('edge-snapshot.json'),
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

FieldSnapshot parseSnapshot(String raw) =>
    FieldSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);

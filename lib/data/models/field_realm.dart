import 'package:flutter/foundation.dart';

/// The Realm currently in focus in the Field — its display [name], human [type]
/// (e.g. `Ecosystem`, `Community`), and the asset path of its emblem.
@immutable
class FieldRealm {
  const FieldRealm({
    required this.name,
    required this.type,
    required this.emblemAsset,
  });

  final String name;
  final String type;
  final String emblemAsset;
}

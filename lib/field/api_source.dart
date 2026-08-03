/// The live-service implementation. Intentionally unimplemented.
///
/// This exists so the seam is visible: it has the same signature as
/// [MockFieldSource], so swapping them requires no change inside the renderer.
/// Implementing it is the receiving team's first task.
library;

import 'field_source.dart';
import 'models.dart';

class ApiFieldSource with FieldEventSink implements FieldSource {
  ApiFieldSource({required this.baseUri, this.authToken});

  final Uri baseUri;
  final String? authToken;

  @override
  Future<FieldSnapshot> load() {
    throw UnimplementedError(
      'ApiFieldSource is a stub. Implement GET {baseUri}/field/snapshot to '
      'return a payload matching contracts/field-snapshot.schema.json, then '
      'construct it with FieldSnapshot.fromJson.\n'
      '\n'
      'Before wiring this to real services, read contracts/README.md. In '
      'particular:\n'
      '  · Send meaning, not geometry. Never send post-Gravity positions.\n'
      '  · Realm IDs are stable and never recycled — identity art derives '
      'from them.\n'
      '  · Gravity is per viewer, not per Realm.\n'
      '  · Absence from realms[] is the visibility mechanism.\n'
      '  · GravityChanged is the only write. Selection is inspection, never '
      'entry.',
    );
  }
}

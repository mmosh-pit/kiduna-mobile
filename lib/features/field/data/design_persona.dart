/// The four canonical Design Lab personas — a Dart port of `design-personas.ts`
/// from the Studio design kit.
///
/// The [id] is the lowercase name used throughout the kit (and in the prototype
/// URL as `?persona=`).
enum DesignPersona {
  alice,
  bob,
  carol,
  danny;

  /// The persona's lowercase id (e.g. `alice`).
  String get id => name;

  /// Resolves a [DesignPersona] from its [id], or `null` when unknown.
  static DesignPersona? fromId(String id) {
    for (final persona in DesignPersona.values) {
      if (persona.name == id) {
        return persona;
      }
    }
    return null;
  }
}

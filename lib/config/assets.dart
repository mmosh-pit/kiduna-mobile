/// Asset paths — the single source of truth for bundled asset locations.
///
/// Never write an `assets/...` string literal at a call site; reference these
/// constants and builders so a moved or renamed asset is changed in one place.
/// Files were copied verbatim from the kiduna-studio-design-kit prototype.
abstract class AppAssets {
  const AppAssets._();

  /// The Kiduna mark (SVG), used for the Ki identity.
  static const String kidunaMark = 'assets/icons/kiduna-mark.svg';

  /// The linear Kiduna logo lockup (SVG), used in the Design Lab header.
  static const String kidunaLogo =
      'assets/icons/kiduna-logo-linear-skyblue.svg';

  static const Set<String> _knownEmblems = {
    'organization',
    'alliance',
    'community',
    'program',
    'project',
    'relationship',
    'conceptual',
  };

  /// Realm emblem for a [type]. Unknown types fall back to `conceptual.jpg`.
  static String realmEmblem(String type) {
    final key = type.toLowerCase();
    final emblem = _knownEmblems.contains(key) ? key : 'conceptual';
    return 'assets/images/realm-emblems/$emblem.jpg';
  }

  /// Ally Portrait for a [persona] (`01`/`04`/`05`) in a given [state]
  /// (`open`/`engaged`/`focused`/`dreaming`).
  static String allyPortrait(String persona, String state) =>
      'assets/images/allies/persona-$persona-$state.jpg';

  /// Organization crest by [name], e.g. `beacon`, `bridge`, `grove`.
  static String organizationCrest(String name) =>
      'assets/images/organization-crests/$name.png';
}

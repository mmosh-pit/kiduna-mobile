/// Centralised route paths.
///
/// Every navigable screen has a named path here — never hardcode path strings
/// in widgets. The `go_router` configuration is layered on top of these once
/// the package is added (see README → "Next steps").
abstract class Routes {
  const Routes._();

  static const String home = '/';
  static const String login = '/login';
  static const String settings = '/settings';

  /// Path pattern for a user profile. Use [userProfilePath] to build a concrete
  /// path from an `id`.
  static const String userProfile = '/user/:id';

  static String userProfilePath(String id) => '/user/$id';
}

import 'package:go_router/go_router.dart';

import '../features/field/screens/aev_screen.dart';
import '../features/field/screens/field_screen.dart';
import '../features/field/screens/nested_realm_screen.dart';

/// Centralised route paths.
///
/// Every navigable screen has a named path here — never hardcode path strings
/// in widgets. Use [appRouter] as the app's `routerConfig`.
abstract class Routes {
  const Routes._();

  /// The Field is the app's root (Newly Created Ecosystem View).
  static const String field = '/';

  /// The Advanced Ecosystem View (AEV) — T1 · S1 · 1.1.
  static const String aev = '/studio/aev';

  static const String login = '/login';
  static const String settings = '/settings';

  /// Nested Realm view — T1 · S1 · 1.1 scoped to a specific realm.
  static const String realm = '/studio/aev/realm/:realmId';

  static String realmPath({required String realmId}) =>
      '/studio/aev/realm/$realmId';

  /// Path pattern for a user profile. Use [userProfilePath] to build a concrete
  /// path from an `id`.
  static const String userProfile = '/user/:id';

  static String userProfilePath(String id) => '/user/$id';
}

/// The application router. All routes are declared here in one place.
final GoRouter appRouter = GoRouter(
  initialLocation: Routes.field,
  routes: <RouteBase>[
    GoRoute(
      path: Routes.field,
      builder: (context, state) => const FieldScreen(),
    ),
    GoRoute(path: Routes.aev, builder: (context, state) => const AevScreen()),
    GoRoute(
      path: Routes.realm,
      builder: (context, state) =>
          NestedRealmScreen(realmId: state.pathParameters['realmId']!),
    ),
  ],
);

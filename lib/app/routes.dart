import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/controllers/auth_controller.dart';
import '../features/auth/enums/auth_status.dart';
import '../features/auth/screens/login_screen.dart';
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

/// Creates the application router with auth-aware redirect.
///
/// Must be called from a widget that has access to a [WidgetRef] so the router
/// can watch [authControllerProvider] and react to auth state changes.
GoRouter createAppRouter(Ref ref) {
  // A Listenable that fires whenever the auth state changes — this tells
  // GoRouter to re-evaluate its redirect logic.
  final authNotifier = _AuthNotifier(ref);

  return GoRouter(
    initialLocation: Routes.field,
    refreshListenable: authNotifier,
    redirect: (context, goState) {
      final auth = ref.read(authControllerProvider);
      final onLogin = goState.matchedLocation == Routes.login;

      // Still loading (initial / restoring) — don't redirect yet.
      if (auth.status == AuthStatus.initial ||
          auth.status == AuthStatus.loading) {
        return null;
      }

      // Not authenticated → force login (unless already there).
      if (!auth.isAuthenticated) {
        return onLogin ? null : Routes.login;
      }

      // Authenticated but on the login page → go to Field.
      if (onLogin) {
        return Routes.field;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
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
}

/// Adapts the Riverpod [authControllerProvider] into a [ChangeNotifier] that
/// GoRouter can listen to via `refreshListenable`.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(this._ref) {
    _ref.listen<AuthState>(authControllerProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;
}

/// Provider that exposes the auth-aware router as a Riverpod-managed object.
///
/// [KidunaApp] watches this and passes it to `MaterialApp.router`.
final appRouterProvider = Provider<GoRouter>(createAppRouter);

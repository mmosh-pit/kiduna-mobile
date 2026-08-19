import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/local/secure_storage.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../enums/auth_status.dart';

@immutable
class AuthState {
  const AuthState({
    this.user,
    this.token,
    this.status = AuthStatus.initial,
    this.error,
  });

  final UserModel? user;
  final String? token;
  final AuthStatus status;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    UserModel? user,
    String? token,
    AuthStatus? status,
    String? error,
    bool clearError = false,
    bool clearUser = false,
    bool clearToken = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      token: clearToken ? null : (token ?? this.token),
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restoreSession();
    return const AuthState();
  }

  Future<void> _restoreSession() async {
    final storage = SecureStorage.instance;
    final storedToken = await storage.getToken();

    if (storedToken == null || storedToken.isEmpty) {
      AppLogger.debug('No stored token — unauthenticated', tag: 'Auth');
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final user = await AuthService.instance.checkAuth(storedToken);

      await storage.saveUser(user);

      state = state.copyWith(
        user: user,
        token: storedToken,
        status: AuthStatus.authenticated,
      );
      AppLogger.info('Session restored', tag: 'Auth');
    } on UnauthorizedException {
      await storage.clearAll();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        clearToken: true,
      );
      AppLogger.info('Stored token invalid — cleared', tag: 'Auth');
    } on AppException catch (e) {
      final cachedUser = await storage.getUser();
      if (cachedUser != null) {
        state = state.copyWith(
          user: cachedUser,
          token: storedToken,
          status: AuthStatus.authenticated,
        );
        AppLogger.warning('Auth check failed, using cached user', tag: 'Auth');
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          error: e.message,
        );
      }
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final result = await AuthService.instance.login(
        email: email,
        password: password,
      );

      final storage = SecureStorage.instance;
      await storage.saveToken(result.token);
      await storage.saveUser(result.user);

      state = state.copyWith(
        user: result.user,
        token: result.token,
        status: AuthStatus.authenticated,
      );
      AppLogger.info('Login complete', tag: 'Auth');
    } on UnauthorizedException {
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'Invalid email or password. Please try again.',
      );
    } on NetworkException {
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'Unable to connect. Please check your internet.',
      );
    } on ApiTimeoutException {
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'Request timed out. Please try again.',
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.message ?? 'Login failed. Please try again.',
      );
    }
  }

  Future<void> logout() async {
    await SecureStorage.instance.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
    AppLogger.info('Logged out', tag: 'Auth');
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

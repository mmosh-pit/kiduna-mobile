import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/features/auth/controllers/auth_controller.dart';
import 'package:kiduna/features/auth/enums/auth_status.dart';

void main() {
  test('initial AuthState has no user, no token, and initial status', () {
    const state = AuthState();
    expect(state.user, isNull);
    expect(state.token, isNull);
    expect(state.status, AuthStatus.initial);
    expect(state.error, isNull);
    expect(state.isAuthenticated, isFalse);
  });

  test('isAuthenticated is true only when status is authenticated', () {
    const state = AuthState(status: AuthStatus.authenticated);
    expect(state.isAuthenticated, isTrue);
  });

  test('copyWith preserves existing error when clearError is false', () {
    const state = AuthState(error: 'failed');
    final next = state.copyWith(status: AuthStatus.loading);
    expect(next.error, 'failed');
  });

  test('copyWith clears error when clearError is true', () {
    const state = AuthState(error: 'failed');
    final next = state.copyWith(status: AuthStatus.loading, clearError: true);
    expect(next.error, isNull);
  });

  test('copyWith clearUser sets user to null', () {
    const state = AuthState(status: AuthStatus.authenticated);
    final next = state.copyWith(clearUser: true);
    expect(next.user, isNull);
  });

  test('copyWith clearToken sets token to null', () {
    const state = AuthState(token: 'abc');
    final next = state.copyWith(clearToken: true);
    expect(next.token, isNull);
  });
}

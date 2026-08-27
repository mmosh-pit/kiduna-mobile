import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/data/models/user_model.dart';

/// AuthService integration tests require a running backend and Dio setup.
/// These tests validate the response parsing logic in isolation — the same
/// JSON shapes AuthService.login() and AuthService.checkAuth() process.
void main() {
  group('login response parsing', () {
    test('parses token and user from standard login response', () {
      const response = {
        'data': {
          'token': 'jwt_abc_123',
          'user': {
            'id': 'u_1',
            'email': 'alice@example.com',
            'name': 'Alice',
            'wallet': 'W123',
            'role': 'member',
          },
        },
      };

      final data = response['data']! as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      expect(token, 'jwt_abc_123');
      expect(user.name, 'Alice');
      expect(user.wallet, 'W123');
    });

    test('handles missing token gracefully', () {
      const response = {
        'data': {
          'user': {'id': 'u_1', 'wallet': 'W'},
        },
      };

      final data = response['data']! as Map<String, dynamic>;
      final token = data['token'] as String?;
      expect(token, isNull);
    });
  });

  group('is-auth response parsing', () {
    test('parses user from is-auth success response', () {
      const response = {
        'data': {
          'is_auth': true,
          'user': {
            'id': 'u_1',
            'email': 'alice@example.com',
            'name': 'Alice',
            'wallet': 'W123',
            'role': 'wizard',
          },
        },
      };

      final data = response['data']! as Map<String, dynamic>;
      final isAuth = data['is_auth'] as bool;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      expect(isAuth, isTrue);
      expect(user.role, 'wizard');
    });

    test('detects expired session (is_auth: false)', () {
      const response = {
        'data': {'is_auth': false},
      };

      final data = response['data']! as Map<String, dynamic>;
      final isAuth = data['is_auth'] as bool? ?? false;
      expect(isAuth, isFalse);
    });
  });
}

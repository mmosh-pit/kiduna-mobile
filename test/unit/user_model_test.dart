import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/data/models/user_model.dart';

void main() {
  const json = {
    'id': 'u_123',
    'email': 'alice@example.com',
    'name': 'Alice',
    'wallet': 'E3KbfsgoFCt51LeKsSgyZ6GtUbrxkooy2E48TdbGxYUm',
    'role': 'member',
  };

  test('fromJson parses all fields', () {
    final user = UserModel.fromJson(json);
    expect(user.id, 'u_123');
    expect(user.email, 'alice@example.com');
    expect(user.name, 'Alice');
    expect(user.wallet, 'E3KbfsgoFCt51LeKsSgyZ6GtUbrxkooy2E48TdbGxYUm');
    expect(user.role, 'member');
  });

  test('fromJson falls back to _id when id is missing', () {
    final user = UserModel.fromJson(const {
      '_id': 'mongo_id',
      'email': 'a@b.com',
      'wallet': 'W',
    });
    expect(user.id, 'mongo_id');
  });

  test('fromJson uses firstName as name fallback', () {
    final user = UserModel.fromJson(const {
      'id': '1',
      'firstName': 'Bob',
      'wallet': 'W',
    });
    expect(user.name, 'Bob');
  });

  test('fromJson uses profile.displayName as name fallback', () {
    final user = UserModel.fromJson(const {
      'id': '1',
      'profile': {'displayName': 'Carol'},
      'wallet': 'W',
    });
    expect(user.name, 'Carol');
  });

  test('fromJson defaults to User when no name variant exists', () {
    final user = UserModel.fromJson(const {'id': '1', 'wallet': 'W'});
    expect(user.name, 'User');
  });

  test('fromJson defaults role to member when missing', () {
    final user = UserModel.fromJson(const {'id': '1', 'wallet': 'W'});
    expect(user.role, 'member');
  });

  test('toJson produces the expected map', () {
    final user = UserModel.fromJson(json);
    final output = user.toJson();
    expect(output['id'], 'u_123');
    expect(output['email'], 'alice@example.com');
    expect(output['name'], 'Alice');
    expect(output['wallet'], json['wallet']);
    expect(output['role'], 'member');
  });

  test('round-trip: fromJson(toJson) produces equal objects', () {
    final original = UserModel.fromJson(json);
    final roundTripped = UserModel.fromJson(original.toJson());
    expect(roundTripped, equals(original));
  });

  test('equality is based on all five fields', () {
    final a = UserModel.fromJson(json);
    final b = UserModel.fromJson(json);
    expect(a, equals(b));
    expect(a.hashCode, b.hashCode);
  });

  test('toString truncates long wallets for safe logging', () {
    final user = UserModel.fromJson(json);
    final str = user.toString();
    expect(str, contains('UserModel'));
    expect(str, contains('Alice'));
    // Full wallet should NOT appear — only the first 12 chars.
    expect(str, isNot(contains(json['wallet'] as String)));
    expect(str, contains('E3KbfsgoFCt5'));
  });
}

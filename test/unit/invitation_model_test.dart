import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/data/models/invitation_request.dart';
import 'package:kiduna_mobile/data/models/invitation_response.dart';

void main() {
  group('InvitationRequest', () {
    test('toJson includes all required fields', () {
      const request = InvitationRequest(
        wallet: 'W123',
        recipientName: 'Bob',
        role: 'Member',
        expiration: '7 days',
      );
      final json = request.toJson();
      expect(json['wallet'], 'W123');
      expect(json['recipientName'], 'Bob');
      expect(json['role'], 'Member');
      expect(json['expiration'], '7 days');
      expect(json.containsKey('handshake'), isFalse);
      expect(json.containsKey('notes'), isFalse);
    });

    test('toJson includes optional fields when non-empty', () {
      const request = InvitationRequest(
        wallet: 'W123',
        recipientName: 'Bob',
        role: 'Member',
        expiration: '7 days',
        handshake: 'secret phrase',
        notes: 'My friend from work',
      );
      final json = request.toJson();
      expect(json['handshake'], 'secret phrase');
      expect(json['notes'], 'My friend from work');
    });

    test('toJson omits empty-string optional fields', () {
      const request = InvitationRequest(
        wallet: 'W123',
        recipientName: 'Bob',
        role: 'Member',
        expiration: '7 days',
        handshake: '',
        notes: '',
      );
      final json = request.toJson();
      expect(json.containsKey('handshake'), isFalse);
      expect(json.containsKey('notes'), isFalse);
    });
  });

  group('InvitationResponse', () {
    const json = {
      'id': 'code_abc123',
      'code': 'KIN-ABC123-XYZ',
      'recipientName': 'Bob',
      'invitationLink': 'https://join.kiduna.org/k/KIN-ABC123-XYZ',
      'invitationMessage': 'Bob, Alice has invited you to join Kinship Duna.',
    };

    test('fromJson parses all fields', () {
      final response = InvitationResponse.fromJson(json);
      expect(response.id, 'code_abc123');
      expect(response.code, 'KIN-ABC123-XYZ');
      expect(response.recipientName, 'Bob');
      expect(response.invitationLink, contains('KIN-ABC123-XYZ'));
      expect(response.invitationMessage, contains('Bob'));
    });

    test('equality is based on id', () {
      final a = InvitationResponse.fromJson(json);
      final b = InvitationResponse.fromJson(json);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different ids produce unequal objects', () {
      final a = InvitationResponse.fromJson(json);
      final differentId = Map<String, dynamic>.from(json)..['id'] = 'other';
      final b = InvitationResponse.fromJson(differentId);
      expect(a, isNot(equals(b)));
    });
  });
}

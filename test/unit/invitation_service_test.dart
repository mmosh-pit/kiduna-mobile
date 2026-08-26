import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/data/models/invitation_request.dart';
import 'package:kiduna/data/models/invitation_response.dart';

/// InvitationService integration tests require a running backend and Dio setup.
/// These tests validate the request/response shapes the service produces and
/// consumes — the same JSON InvitationService.generate() sends and parses.
void main() {
  group('InvitationRequest serialization', () {
    test('toJson produces the expected payload', () {
      const request = InvitationRequest(
        wallet: 'E3Kbfs',
        recipientName: 'Ravi',
        role: 'Member, Creator',
        expiration: '7 days',
        handshake: 'blue umbrella',
        notes: 'College friend',
      );

      final json = request.toJson();

      expect(json['wallet'], 'E3Kbfs');
      expect(json['recipientName'], 'Ravi');
      expect(json['role'], 'Member, Creator');
      expect(json['expiration'], '7 days');
      expect(json['handshake'], 'blue umbrella');
      expect(json['notes'], 'College friend');
    });

    test('toJson omits null handshake and notes', () {
      const request = InvitationRequest(
        wallet: 'W',
        recipientName: 'Bob',
        role: 'Guest',
        expiration: '1 hour',
      );

      final json = request.toJson();

      expect(json.containsKey('handshake'), isFalse);
      expect(json.containsKey('notes'), isFalse);
    });
  });

  group('InvitationResponse parsing', () {
    test('fromJson parses the standard backend response', () {
      const json = {
        'id': 'code_xyz',
        'code': 'KIN-XYZ789-ABC',
        'recipientName': 'Ravi',
        'invitationLink': 'https://join.kiduna.org/k/KIN-XYZ789-ABC',
        'invitationMessage':
            'Ravi, Alice has invited you to join Kinship Duna.',
      };

      final response = InvitationResponse.fromJson(json);

      expect(response.id, 'code_xyz');
      expect(response.code, 'KIN-XYZ789-ABC');
      expect(response.recipientName, 'Ravi');
      expect(response.invitationLink, contains('KIN-XYZ789-ABC'));
      expect(response.invitationMessage, startsWith('Ravi'));
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/data/models/invitation_response.dart';
import 'package:kiduna_mobile/features/field/controllers/field_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  FieldState state() => container.read(fieldControllerProvider);

  test('initial state has no invitation response', () {
    expect(state().invitationResponse, isNull);
    expect(state().invitationLoading, isFalse);
    expect(state().invitationError, isNull);
  });

  test(
    'copyWith preserves invitationError when clearInvitationError is false',
    () {
      final s = FieldState(
        kiTopic: state().kiTopic,
        invitationError: 'something went wrong',
      );
      final next = s.copyWith(invitationLoading: true);
      expect(next.invitationError, 'something went wrong');
    },
  );

  test('copyWith clears invitationError when clearInvitationError is true', () {
    final s = FieldState(
      kiTopic: state().kiTopic,
      invitationError: 'something went wrong',
    );
    final next = s.copyWith(clearInvitationError: true);
    expect(next.invitationError, isNull);
  });

  test('copyWith clears invitationResponse when clearInvitation is true', () {
    const response = InvitationResponse(
      id: '1',
      code: 'KIN-TEST01-ABC',
      recipientName: 'Bob',
      invitationLink: 'https://join.kiduna.org/k/KIN-TEST01-ABC',
      invitationMessage: 'Bob, welcome.',
    );
    final s = FieldState(
      kiTopic: state().kiTopic,
      invitationResponse: response,
    );
    final next = s.copyWith(clearInvitation: true);
    expect(next.invitationResponse, isNull);
  });

  test('clearInvitation resets all invitation fields', () {
    // Manually set invitation state for the test.
    final s = FieldState(
      kiTopic: state().kiTopic,
      invitationResponse: const InvitationResponse(
        id: '1',
        code: 'KIN-TEST01-ABC',
        recipientName: 'Bob',
        invitationLink: 'https://example.com',
        invitationMessage: 'Hello',
      ),
      invitationLoading: true,
      invitationError: 'error',
    );
    final next = s.copyWith(
      clearInvitation: true,
      clearInvitationError: true,
      invitationLoading: false,
    );
    expect(next.invitationResponse, isNull);
    expect(next.invitationLoading, isFalse);
    expect(next.invitationError, isNull);
  });
}

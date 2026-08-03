import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/data/models/ally_agent_model.dart';
import 'package:kiduna_mobile/features/field/controllers/ally_controller.dart';

void main() {
  test('initial AllyState has no ally, no error, and is not loading', () {
    const state = AllyState();
    expect(state.ally, isNull);
    expect(state.error, isNull);
    expect(state.isLoading, isFalse);
  });

  test('copyWith preserves existing error when clearError is false', () {
    const state = AllyState(error: 'failed');
    final next = state.copyWith(isLoading: true);
    expect(next.error, 'failed');
    expect(next.isLoading, isTrue);
  });

  test('copyWith clears error when clearError is true', () {
    const state = AllyState(error: 'failed');
    final next = state.copyWith(isLoading: true, clearError: true);
    expect(next.error, isNull);
    expect(next.isLoading, isTrue);
  });

  test('copyWith clearAlly sets ally to null', () {
    final state = AllyState(
      ally: AllyAgentModel.fromJson(const {
        'id': 'agent_1',
        'name': 'Ki',
        'isAlly': true,
      }),
    );
    final next = state.copyWith(clearAlly: true);
    expect(next.ally, isNull);
  });

  test('copyWith preserves ally when not cleared', () {
    final ally = AllyAgentModel.fromJson(const {
      'id': 'agent_1',
      'name': 'Ki',
      'isAlly': true,
    });
    final state = AllyState(ally: ally);
    final next = state.copyWith(isLoading: false);
    expect(next.ally, equals(ally));
  });

  test('copyWith sets ally when provided', () {
    const state = AllyState();
    final ally = AllyAgentModel.fromJson(const {
      'id': 'agent_1',
      'name': 'Ki',
      'isAlly': true,
    });
    final next = state.copyWith(ally: ally);
    expect(next.ally, equals(ally));
  });

  test('loading state pattern: loading with clearError', () {
    const state = AllyState(error: 'old error');
    final loading = state.copyWith(isLoading: true, clearError: true);
    expect(loading.isLoading, isTrue);
    expect(loading.error, isNull);
  });

  test('error state pattern: not loading with error message', () {
    const loading = AllyState(isLoading: true);
    final errored = loading.copyWith(
      isLoading: false,
      error: 'No internet connection.',
    );
    expect(errored.isLoading, isFalse);
    expect(errored.error, 'No internet connection.');
    expect(errored.ally, isNull);
  });

  test('success state pattern: not loading with ally data', () {
    const loading = AllyState(isLoading: true);
    final ally = AllyAgentModel.fromJson(const {
      'id': 'agent_TU1ybVxi',
      'name': 'Ki',
      'handle': 'ki',
      'isAlly': true,
      'status': 'ACTIVE',
    });
    final success = loading.copyWith(isLoading: false, ally: ally);
    expect(success.isLoading, isFalse);
    expect(success.error, isNull);
    expect(success.ally, equals(ally));
    expect(success.ally?.id, 'agent_TU1ybVxi');
  });
}

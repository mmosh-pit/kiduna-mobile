import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/realm_model.dart';
import '../../../data/services/realm_service.dart';

@immutable
class EcosystemState {
  const EcosystemState({
    this.isLoading = false,
    this.error,
    this.ecosystem,
  });

  final bool isLoading;
  final String? error;
  final RealmModel? ecosystem;

  EcosystemState copyWith({
    bool? isLoading,
    String? error,
    RealmModel? ecosystem,
    bool clearError = false,
    bool clearEcosystem = false,
  }) {
    return EcosystemState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      ecosystem: clearEcosystem ? null : (ecosystem ?? this.ecosystem),
    );
  }
}

class EcosystemController extends Notifier<EcosystemState> {
  @override
  EcosystemState build() {
    return const EcosystemState(isLoading: true);
  }

  Future<void> loadEcosystem() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final ecosystem = await RealmService.instance.fetchEcosystem();

      if (ecosystem == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      state = state.copyWith(isLoading: false, ecosystem: ecosystem);
    } on UnauthorizedException {
      state = state.copyWith(
        isLoading: false,
        error: 'Session expired. Please log in again.',
      );
    } on NetworkException {
      state = state.copyWith(
        isLoading: false,
        error: 'No internet connection.',
      );
    } on ApiTimeoutException {
      state = state.copyWith(
        isLoading: false,
        error: 'Request timed out. Try again.',
      );
    } on AppException catch (e) {
      AppLogger.error('Ecosystem load failed', tag: 'Ecosystem', error: e);
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? 'Failed to load ecosystem.',
      );
    }
  }
}

final ecosystemControllerProvider =
    NotifierProvider<EcosystemController, EcosystemState>(
  EcosystemController.new,
);

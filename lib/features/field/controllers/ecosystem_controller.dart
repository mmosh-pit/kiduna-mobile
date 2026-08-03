import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/duna_model.dart';
import '../../../data/services/duna_service.dart';

/// UI state for the ecosystem (genesis duna + organizations + user dunas).
@immutable
class EcosystemState {
  const EcosystemState({
    this.genesis,
    this.organizations = const [],
    this.dunas = const [],
    this.isLoading = false,
    this.error,
  });

  final DunaModel? genesis;

  /// Organizations registered under the genesis DUNA.
  final List<DunaModel> organizations;

  final List<DunaModel> dunas;
  final bool isLoading;
  final String? error;

  /// All dunas in display order: genesis first, then organizations, then user dunas.
  List<DunaModel> get all =>
      [if (genesis != null) genesis!, ...organizations, ...dunas];

  EcosystemState copyWith({
    DunaModel? genesis,
    List<DunaModel>? organizations,
    List<DunaModel>? dunas,
    bool? isLoading,
    String? error,
  }) {
    return EcosystemState(
      genesis: genesis ?? this.genesis,
      organizations: organizations ?? this.organizations,
      dunas: dunas ?? this.dunas,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Manages the ecosystem state — fetches dunas from the studio API.
class EcosystemController extends Notifier<EcosystemState> {
  @override
  EcosystemState build() {
    // Trigger the initial load as soon as the provider is first read.
    Future.microtask(() => load());
    return const EcosystemState(isLoading: true);
  }

  /// Fetch dunas from the API.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await DunaService.instance.fetchDunas();
      state = EcosystemState(
        genesis: response.genesis,
        organizations: response.organizations,
        dunas: response.dunas,
      );
    } on AppException catch (e) {
      AppLogger.warning(
        'Ecosystem load failed: $e',
        tag: 'EcosystemController',
      );
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      AppLogger.error(
        'Ecosystem load unexpected error',
        tag: 'EcosystemController',
        error: e,
      );
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  /// Retry after a failure.
  Future<void> retry() => load();
}

/// Global provider for the ecosystem (dunas) state.
final ecosystemControllerProvider =
    NotifierProvider<EcosystemController, EcosystemState>(
  EcosystemController.new,
);
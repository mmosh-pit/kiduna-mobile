import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/realm_model.dart';
import '../../../data/services/realm_service.dart';

/// UI state for the ecosystem (genesis Realm + child Realms).
@immutable
class EcosystemState {
  const EcosystemState({
    this.genesis,
    this.organizations = const [],
    this.realms = const [],
    this.isLoading = false,
    this.error,
  });

  /// The genesis Ecosystem Realm visible to everyone.
  final RealmModel? genesis;

  /// Organizations registered under the genesis Ecosystem.
  final List<RealmModel> organizations;

  /// The caller's own Realms.
  final List<RealmModel> realms;
  final bool isLoading;
  final String? error;

  /// All Realms in display order: genesis first, then organizations, then others.
  List<RealmModel> get all => [
    if (genesis != null) genesis!,
    ...organizations,
    ...realms,
  ];

  EcosystemState copyWith({
    RealmModel? genesis,
    List<RealmModel>? organizations,
    List<RealmModel>? realms,
    bool? isLoading,
    String? error,
  }) {
    return EcosystemState(
      genesis: genesis ?? this.genesis,
      organizations: organizations ?? this.organizations,
      realms: realms ?? this.realms,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Manages the ecosystem state — fetches Realms from the backend API.
class EcosystemController extends Notifier<EcosystemState> {
  @override
  EcosystemState build() {
    // Trigger the initial load as soon as the provider is first read.
    Future.microtask(load);
    return const EcosystemState(isLoading: true);
  }

  /// Fetch the genesis Ecosystem and the caller's Realms from the API.
  ///
  /// The ecosystem fetch is public (no auth) and must succeed independently
  /// of the realms fetch (which requires auth and may 401 if the user hasn't
  /// fully authenticated yet).
  Future<void> load() async {
    state = state.copyWith(isLoading: true);

    // 1. Fetch genesis ecosystem (public, no auth) — always works.
    RealmModel? ecosystem;
    try {
      ecosystem = await RealmService.instance.fetchEcosystem();
    } catch (e) {
      AppLogger.warning(
        'Ecosystem fetch failed: $e',
        tag: 'EcosystemController',
      );
    }

    // 2. Fetch caller's Realms (auth required) — may fail with 401.
    List<RealmModel> allRealms = [];
    try {
      allRealms = await RealmService.instance.fetchRealms();
    } catch (e) {
      AppLogger.warning(
        'Realms fetch failed (may need auth): $e',
        tag: 'EcosystemController',
      );
    }

    // Separate organizations from other Realms
    final organizations = allRealms
        .where((r) => r.type == 'organization')
        .toList();
    final otherRealms = allRealms
        .where((r) => r.type != 'organization' && r.type != 'ecosystem')
        .toList();

    state = EcosystemState(
      genesis: ecosystem,
      organizations: organizations,
      realms: otherRealms,
    );
  }

  /// Retry after a failure.
  Future<void> retry() => load();
}

/// Global provider for the ecosystem (Realms) state.
final ecosystemControllerProvider =
    NotifierProvider<EcosystemController, EcosystemState>(
      EcosystemController.new,
    );

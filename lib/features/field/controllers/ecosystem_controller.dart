import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/logger.dart';
import '../../../data/models/gravity_model.dart';
import '../../../data/models/realm_model.dart';
import '../../../data/services/gravity_service.dart';
import '../../../data/services/realm_service.dart';
import '../../auth/controllers/auth_controller.dart';

/// UI state for the ecosystem (genesis Realm + child Realms).
@immutable
class EcosystemState {
  const EcosystemState({
    this.genesis,
    this.organizations = const [],
    this.realms = const [],
    this.isLoading = false,
    this.error,
    this.knownNames = const {},
    this.gravityRealms = const [],
    this.levelSummary,
  });

  /// The genesis Ecosystem Realm visible to everyone.
  final RealmModel? genesis;

  /// Organizations registered under the genesis Ecosystem.
  final List<RealmModel> organizations;

  /// The caller's own Realms.
  final List<RealmModel> realms;
  final bool isLoading;
  final String? error;

  /// Accumulated realm id → name map across navigations.
  final Map<String, String> knownNames;

  /// Gravity-scored realms from the graph API, sorted by score descending.
  final List<RealmGravity> gravityRealms;

  /// Gravity level counts (vital/central/relevant/available/quiet).
  final LevelSummary? levelSummary;

  /// All Realms in display order: genesis first, then organizations, then others.
  List<RealmModel> get all => [?genesis, ...organizations, ...realms];

  EcosystemState copyWith({
    RealmModel? genesis,
    List<RealmModel>? organizations,
    List<RealmModel>? realms,
    bool? isLoading,
    String? error,
    Map<String, String>? knownNames,
    List<RealmGravity>? gravityRealms,
    LevelSummary? levelSummary,
    bool clearError = false,
    bool clearLevelSummary = false,
  }) {
    return EcosystemState(
      genesis: genesis ?? this.genesis,
      organizations: organizations ?? this.organizations,
      realms: realms ?? this.realms,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      knownNames: knownNames ?? this.knownNames,
      gravityRealms: gravityRealms ?? this.gravityRealms,
      levelSummary: clearLevelSummary
          ? null
          : (levelSummary ?? this.levelSummary),
    );
  }
}

/// Manages the ecosystem state — fetches Realms from the gravity API (graph)
/// with a fallback to the table API when gravity is unavailable.
class EcosystemController extends Notifier<EcosystemState> {
  @override
  EcosystemState build() {
    Future.microtask(load);
    return const EcosystemState(isLoading: true);
  }

  /// Fetch the genesis Ecosystem and realm list.
  ///
  /// Primary source: gravity API (graph-based, scored).
  /// Fallback: table API (flat list, no scoring).
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

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

    // 2. Try gravity API first (graph-based, scored list).
    final wallet = ref.read(authControllerProvider).user?.wallet;
    if (wallet != null && wallet.isNotEmpty) {
      final loaded = await _loadFromGravity(wallet, ecosystem: ecosystem);
      if (loaded) return;
    }

    // 3. Fallback: table API (flat list).
    await _loadFromTable(ecosystem: ecosystem);
  }

  /// Fetch children of a specific realm by its id.
  ///
  /// Primary source: gravity API with currentRealmId filter.
  /// Fallback: table API.
  Future<void> loadChildren(String parentId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final wallet = ref.read(authControllerProvider).user?.wallet;
    if (wallet != null && wallet.isNotEmpty) {
      final loaded = await _loadFromGravity(wallet, currentRealmId: parentId);
      if (loaded) return;
    }

    // Fallback: table API.
    await _loadChildrenFromTable(parentId);
  }

  /// Load realms from the gravity API and populate state.
  /// Returns true if successful, false if failed (caller should fall back).
  Future<bool> _loadFromGravity(
    String wallet, {
    RealmModel? ecosystem,
    String? currentRealmId,
  }) async {
    try {
      final response = await GravityService.instance.fetchGravity(
        wallet,
        currentRealmId: currentRealmId,
      );

      if (!ref.mounted) return true;

      final realmModels = response.realms.map(_realmModelFromGravity).toList();

      final organizations = realmModels
          .where((r) => r.type == 'organization')
          .toList();
      final otherRealms = realmModels
          .where((r) => r.type != 'organization' && r.type != 'ecosystem')
          .toList();

      final names = <String, String>{
        ...state.knownNames,
        if (ecosystem != null) ecosystem.id: ecosystem.name,
        for (final r in realmModels) r.id: r.name,
      };

      state = EcosystemState(
        genesis: ecosystem ?? state.genesis,
        organizations: organizations,
        realms: otherRealms,
        gravityRealms: response.realms,
        levelSummary: response.levelSummary,
        knownNames: names,
      );

      AppLogger.info(
        'Loaded ${response.realms.length} realms from gravity API',
        tag: 'EcosystemController',
      );
      return true;
    } catch (e, st) {
      AppLogger.error(
        'Gravity API failed',
        tag: 'EcosystemController',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Fallback: load from the table API (existing behavior).
  Future<void> _loadFromTable({RealmModel? ecosystem}) async {
    List<RealmModel> allRealms = [];
    String? fetchError;
    try {
      allRealms = await RealmService.instance.fetchRealms(
        parentId: ecosystem?.id,
      );
    } catch (e) {
      AppLogger.warning(
        'Realms fetch failed (may need auth): $e',
        tag: 'EcosystemController',
      );
      if (ecosystem == null) {
        fetchError = 'Unable to load realms. Please try again.';
      }
    }

    final organizations = allRealms
        .where((r) => r.type == 'organization')
        .toList();
    final otherRealms = allRealms
        .where((r) => r.type != 'organization' && r.type != 'ecosystem')
        .toList();

    final names = <String, String>{
      ...state.knownNames,
      if (ecosystem != null) ecosystem.id: ecosystem.name,
      for (final r in allRealms) r.id: r.name,
    };

    state = EcosystemState(
      genesis: ecosystem,
      organizations: organizations,
      realms: otherRealms,
      error: fetchError,
      knownNames: names,
    );
  }

  /// Fallback: load children from the table API.
  Future<void> _loadChildrenFromTable(String parentId) async {
    List<RealmModel> allRealms = [];
    String? fetchError;
    try {
      allRealms = await RealmService.instance.fetchRealms(parentId: parentId);
    } catch (e) {
      AppLogger.warning(
        'Children fetch failed: $e',
        tag: 'EcosystemController',
      );
      fetchError = 'Unable to load realms. Please try again.';
    }

    final organizations = allRealms
        .where((r) => r.type == 'organization')
        .toList();
    final otherRealms = allRealms
        .where((r) => r.type != 'organization' && r.type != 'ecosystem')
        .toList();

    final names = <String, String>{
      ...state.knownNames,
      for (final r in allRealms) r.id: r.name,
    };

    state = state.copyWith(
      organizations: organizations,
      realms: otherRealms,
      isLoading: false,
      error: fetchError,
      knownNames: names,
    );
  }

  /// Retry after a failure.
  Future<void> retry() => load();

  /// Convert a gravity realm entry to a RealmModel for the constellation UI.
  static RealmModel _realmModelFromGravity(RealmGravity g) {
    return RealmModel(
      id: g.id,
      name: g.name,
      handle: '',
      type: g.type,
      visibility: 'public',
      wallet: '',
      walletEnabled: false,
      threshold: 1,
      status: 'active',
      createdAt: DateTime.now(),
      gravityLevel: g.level,
      gravityScore: g.score,
    );
  }
}

/// Global provider for the ecosystem (Realms) state.
final ecosystemControllerProvider =
    NotifierProvider<EcosystemController, EcosystemState>(
      EcosystemController.new,
    );

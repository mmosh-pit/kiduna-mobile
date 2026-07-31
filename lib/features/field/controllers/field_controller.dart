import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/assets.dart';
import '../../../core/enums/capacity_target.dart';
import '../../../data/models/field_realm.dart';
import '../../../data/models/ki_topic.dart';
import '../data/design_persona.dart';
import '../data/field_composition.dart';
import '../data/field_fixtures.dart';
import '../data/realm_atlas.dart';

/// UI state for the Field.
@immutable
class FieldState {
  FieldState({
    required this.kiTopic,
    FieldRealm? currentRealm,
    this.isLoading = false,
    this.error,
    this.currentRealmId = 'kinship-duna',
    this.inspectOpen = false,
    this.actionsVisible = true,
    this.fieldFocus = 100,
    this.kiFraction = 0.30,
    this.openActions = const [],
    this.realmCapacities = const [],
    this.allyCapacities = const [],
    this.realmPortraitOpen = false,
    this.allyPortraitOpen = false,
    this.preservedMessage,
    this.selectedPlacement,
    this.realmGravity = const {},
    this.realmPath = const ['kinship-duna'],
  }) : currentRealm = currentRealm ?? FieldFixtures.kinshipDuna;

  final KiTopic kiTopic;
  final FieldRealm currentRealm;
  final bool isLoading;
  final String? error;
  final bool inspectOpen;
  final bool actionsVisible;
  final double fieldFocus;
  final String currentRealmId;

  /// Ki's share of the width on desktop (0.25-0.34).
  final double kiFraction;

  /// Ids of open working panels (`invite`, `realm`, `shape`, `ally`).
  final List<String> openActions;
  final List<String> realmCapacities;
  final List<String> allyCapacities;
  final bool realmPortraitOpen;
  final bool allyPortraitOpen;
  final String? preservedMessage;

  /// The currently selected realm in the constellation (null = nothing selected).
  final FieldPlacement? selectedPlacement;

  /// Per-realm gravity overrides (realm-id → 1..5).
  final Map<String, int> realmGravity;

  /// Breadcrumb of realm ids from the Ecosystem root to the current realm.
  final List<String> realmPath;

  String? get selectedRealmId => selectedPlacement?.realm.id;

  FieldState copyWith({
    KiTopic? kiTopic,
    FieldRealm? currentRealm,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? currentRealmId,
    bool? inspectOpen,
    bool? actionsVisible,
    double? fieldFocus,
    double? kiFraction,
    List<String>? openActions,
    List<String>? realmCapacities,
    List<String>? allyCapacities,
    bool? realmPortraitOpen,
    bool? allyPortraitOpen,
    String? preservedMessage,
    bool clearPreserved = false,
    FieldPlacement? selectedPlacement,
    bool clearSelection = false,
    Map<String, int>? realmGravity,
    List<String>? realmPath,
  }) {
    return FieldState(
      kiTopic: kiTopic ?? this.kiTopic,
      currentRealm: currentRealm ?? this.currentRealm,
      isLoading: isLoading ?? this.isLoading,
      currentRealmId: currentRealmId ?? this.currentRealmId,
      error: clearError ? null : (error ?? this.error),
      inspectOpen: inspectOpen ?? this.inspectOpen,
      actionsVisible: actionsVisible ?? this.actionsVisible,
      fieldFocus: fieldFocus ?? this.fieldFocus,
      kiFraction: kiFraction ?? this.kiFraction,
      openActions: openActions ?? this.openActions,
      realmCapacities: realmCapacities ?? this.realmCapacities,
      allyCapacities: allyCapacities ?? this.allyCapacities,
      realmPortraitOpen: realmPortraitOpen ?? this.realmPortraitOpen,
      allyPortraitOpen: allyPortraitOpen ?? this.allyPortraitOpen,
      preservedMessage: clearPreserved
          ? null
          : (preservedMessage ?? this.preservedMessage),
      selectedPlacement: clearSelection
          ? null
          : (selectedPlacement ?? this.selectedPlacement),
      realmGravity: realmGravity ?? this.realmGravity,
      realmPath: realmPath ?? this.realmPath,
    );
  }
}

/// Drives the Field's UI state. All interaction lives here, not in widgets.
class FieldController extends Notifier<FieldState> {
  @override
  FieldState build() => FieldState(kiTopic: FieldFixtures.defaultKi);

  void toggleInspect() =>
      state = state.copyWith(inspectOpen: !state.inspectOpen);

  void closeActions() => state = state.copyWith(actionsVisible: false);

  void setFieldFocus(double value) => state = state.copyWith(fieldFocus: value);

  void setKiFraction(double value) =>
      state = state.copyWith(kiFraction: value.clamp(0.25, 0.34));

  void askAbout(KiTopic topic) => state = state.copyWith(kiTopic: topic);

  void preserveMessage(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return;
    }
    state = state.copyWith(
      preservedMessage: trimmed,
      kiTopic: FieldFixtures.messagePreserved,
    );
  }

  /// Opens the working panel for [action] and lets Ki speak to it.
  void chooseAction(FieldAction action) {
    if (!state.openActions.contains(action.id)) {
      state = state.copyWith(openActions: [...state.openActions, action.id]);
    }
    askAbout(action.topic);
  }

  void openActionById(String id) {
    if (!state.openActions.contains(id)) {
      state = state.copyWith(openActions: [...state.openActions, id]);
    }
  }

  void closeAction(String id) => state = state.copyWith(
    openActions: state.openActions.where((item) => item != id).toList(),
  );

  void openCapacity(CapacityTarget target, String id) {
    final list = target == CapacityTarget.ally
        ? state.allyCapacities
        : state.realmCapacities;
    if (list.contains(id)) {
      return;
    }
    final next = [...list, id];
    state = target == CapacityTarget.ally
        ? state.copyWith(allyCapacities: next)
        : state.copyWith(realmCapacities: next);
  }

  void closeCapacity(CapacityTarget target, String id) {
    final list = target == CapacityTarget.ally
        ? state.allyCapacities
        : state.realmCapacities;
    final next = list.where((item) => item != id).toList();
    state = target == CapacityTarget.ally
        ? state.copyWith(allyCapacities: next)
        : state.copyWith(realmCapacities: next);
  }

  void setRealmPortraitOpen(bool open) =>
      state = state.copyWith(realmPortraitOpen: open);

  void setAllyPortraitOpen(bool open) =>
      state = state.copyWith(allyPortraitOpen: open);

  /// Selects a realm in the constellation and tells Ki about it.
  void selectAtlasRealm(FieldPlacement placement) {
    final realm = placement.realm;
    state = state.copyWith(
      selectedPlacement: placement,
      kiTopic: KiTopic(
        title: realm.name,
        body: placement.reason,
        invitation:
            'Inspect ${realm.name}, adjust its Gravity if useful, or '
            'enter it to make its Possible Actions current.',
      ),
    );
  }

  void clearSelection() => state = state.copyWith(clearSelection: true);

  void navigateToBreadcrumb(int index) {
    if (index < 0 || index >= state.realmPath.length) {
      return;
    }
    final targetId = state.realmPath[index];
    final realm = realmAtlas[targetId];
    if (realm == null) {
      return;
    }
    final emblem =
        realm.type == AtlasRealmType.institution ||
            realm.type == AtlasRealmType.ecosystem
        ? 'conceptual'
        : realm.type.emblemKey;
    state = state.copyWith(
      currentRealm: FieldRealm(
        name: realm.name,
        type: realm.type.label,
        emblemAsset: AppAssets.realmEmblem(emblem),
      ),
      currentRealmId: targetId,
      clearSelection: true,
      actionsVisible: true,
      inspectOpen: false,
      realmPath: state.realmPath.sublist(0, index + 1),
      kiTopic: KiTopic(
        title: 'Inside ${realm.name}',
        body:
            'Alice is now inside ${realm.name}, a ${realm.type.label}. '
            '${realm.purpose}',
        invitation:
            'Possible Actions shows what can be done here. Inspect any '
            'nested Realm or use the breadcrumb to go back.',
      ),
    );
  }

  /// Sets the gravity level (1–5) for a realm.
  void setGravity(String realmId, int level) {
    final clamped = level.clamp(1, 5);
    state = state.copyWith(
      realmGravity: {...state.realmGravity, realmId: clamped},
    );
  }

  int gravityFor(String realmId) => state.realmGravity[realmId] ?? 3;

  /// Enters the selected realm: it becomes the new current realm, the
  /// constellation re-renders to show its children, and Ki updates.
  void enterAtlasRealm(AtlasRealm realm) {
    final emblem =
        realm.type == AtlasRealmType.institution ||
            realm.type == AtlasRealmType.ecosystem
        ? 'conceptual'
        : realm.type.emblemKey;
    final hasChildren = visibleChildren(
      realm.id,
      DesignPersona.alice,
    ).isNotEmpty;
    final invitation = hasChildren
        ? 'Possible Actions shows what can be done here. Inspect any '
              'nested Realm or use the breadcrumb to go back.'
        : 'No nested Realms are visible here. Use Navigation to return, '
              'or ask Ki what could be formed here.';
    state = state.copyWith(
      currentRealm: FieldRealm(
        name: realm.name,
        type: realm.type.label,
        emblemAsset: AppAssets.realmEmblem(emblem),
      ),
      currentRealmId: realm.id,
      clearSelection: true,
      actionsVisible: true,
      inspectOpen: false,
      realmPath: [...state.realmPath, realm.id],
      kiTopic: KiTopic(
        title: 'Inside ${realm.name}',
        body:
            'Alice is now inside ${realm.name}, a ${realm.type.label}. '
            '${realm.purpose}',
        invitation: invitation,
      ),
    );
  }

  /// Creates a Realm, enters it, and closes the Form panel.
  void createRealm({required String name, required String type}) {
    state = state.copyWith(
      currentRealm: FieldRealm(
        name: name,
        type: type,
        emblemAsset: AppAssets.realmEmblem(type),
      ),
      openActions: state.openActions.where((item) => item != 'realm').toList(),
    );
    askAbout(
      KiTopic(
        title: '$name created',
        body:
            'Ki has created $name as a $type and brought Alice inside it. '
            'Kinship Duna remains its containing Ecosystem and return path.',
        invitation:
            "Ki can help shape the new Realm's purpose, boundaries, "
            'capacities, and people through dialogue.',
      ),
    );
  }

  void savePresentation({required String name, required String type}) {
    state = state.copyWith(
      currentRealm: FieldRealm(
        name: name,
        type: type,
        emblemAsset: AppAssets.realmEmblem(type),
      ),
      openActions: state.openActions
          .where((item) => item != 'present')
          .toList(),
    );
    askAbout(
      KiTopic(
        title: '$name presentation updated',
        body:
            'The Realm now presents as $name, a $type. Its stable Realm '
            'identity and authority have not changed.',
        invitation:
            'Ki can help refine the purpose or prepare a different Portrait '
            'without publishing anything.',
      ),
    );
  }
}

final fieldControllerProvider = NotifierProvider<FieldController, FieldState>(
  FieldController.new,
);

/// Walks parent pointers from [realmId] up to the Ecosystem root to produce
/// the breadcrumb path. Pure function on static atlas data — no provider
/// needed.
List<String> breadcrumbPathFor(String realmId) {
  final path = <String>[];
  String? current = realmId;
  while (current != null && realmAtlas.containsKey(current)) {
    path.insert(0, current);
    current = realmAtlas[current]?.parent;
  }
  return path;
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/assets.dart';
import '../../../core/enums/capacity_target.dart';
import '../../../data/models/field_realm.dart';
import '../../../data/models/ki_topic.dart';
import '../data/field_fixtures.dart';

/// UI state for the Field.
@immutable
class FieldState {
  FieldState({
    required this.kiTopic,
    FieldRealm? currentRealm,
    this.isLoading = false,
    this.error,
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
  }) : currentRealm = currentRealm ?? FieldFixtures.kinshipDuna;

  final KiTopic kiTopic;
  final FieldRealm currentRealm;
  final bool isLoading;
  final String? error;
  final bool inspectOpen;
  final bool actionsVisible;
  final double fieldFocus;

  /// Ki's share of the width on desktop (0.25-0.34).
  final double kiFraction;

  /// Ids of open working panels (`invite`, `realm`, `shape`, `ally`).
  final List<String> openActions;
  final List<String> realmCapacities;
  final List<String> allyCapacities;
  final bool realmPortraitOpen;
  final bool allyPortraitOpen;
  final String? preservedMessage;

  FieldState copyWith({
    KiTopic? kiTopic,
    FieldRealm? currentRealm,
    bool? isLoading,
    String? error,
    bool clearError = false,
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
  }) {
    return FieldState(
      kiTopic: kiTopic ?? this.kiTopic,
      currentRealm: currentRealm ?? this.currentRealm,
      isLoading: isLoading ?? this.isLoading,
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

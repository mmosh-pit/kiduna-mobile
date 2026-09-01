import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/assets.dart';
import '../../../config/env.dart';
import '../../../core/enums/capacity_target.dart';
import '../../../core/enums/skill_trigger_type.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/available_tool_model.dart';
import '../../../data/models/field_realm.dart';
import '../../../data/models/invitation_request.dart';
import '../../../data/models/invitation_response.dart';
import '../../../data/models/ki_topic.dart';
import '../../../data/models/realm_model.dart';
import '../../../data/models/saved_tool_model.dart';
import '../../../data/models/skill_model.dart';
import '../../../data/services/approval_service.dart';
import '../../../data/services/gravity_service.dart';
import '../../../data/services/invitation_service.dart';
import '../../../data/services/realm_service.dart';
import '../../../data/services/skill_service.dart';
import '../../../data/services/tool_connection_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/design_persona.dart';
import '../data/field_composition.dart';
import '../data/field_fixtures.dart';
import '../data/realm_atlas.dart';
import 'ally_controller.dart';
import 'ecosystem_controller.dart';

/// UI state for the Field.
@immutable
class FieldState {
  const FieldState({
    required this.kiTopic,
    this.currentRealm = const FieldRealm(
      name: '',
      type: 'Ecosystem',
      emblemAsset: '',
    ),
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
    this.invitationResponse,
    this.invitationLoading = false,
    this.invitationError,
    this.skills = const [],
    this.availableTools = const [],
    this.toolsLoaded = false,
    this.skillFormOpen = false,
    this.approvalsOpen = false,
    this.pendingApprovalCount = 0,
    this.uploadedSkillData,
    this.uploadedToolRegistry,
    this.skillUploadLoading = false,
    this.editingSkill,
    this.savedTools = const [],
    this.skillsLoading = false,
    this.connectingTool,
    this.toolVerifyError,
    this.toolVerifying = false,
    this.enteredRealmId,
    this.enteredRealmName,
    this.refreshToken = 0,
  });

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

  /// The last successfully generated invitation (null until first prepare).
  final InvitationResponse? invitationResponse;

  /// Whether an invitation generation API call is in flight.
  final bool invitationLoading;

  /// Error message from the last failed invitation attempt.
  final String? invitationError;

  /// Skills available in the current Realm.
  final List<SkillModel> skills;

  /// Tools discovered from MCP servers via `GET /api/tools/available`.
  final List<AvailableToolModel> availableTools;

  /// Whether [availableTools] has been fetched at least once.
  final bool toolsLoaded;

  /// Whether the skill creation form panel is open.
  final bool skillFormOpen;
  final bool approvalsOpen;
  final int pendingApprovalCount;
  final Map<String, dynamic>? uploadedSkillData;
  final Map<String, dynamic>? uploadedToolRegistry;
  final bool skillUploadLoading;

  /// Skill being edited — null means creating new.
  final SkillModel? editingSkill;

  /// Tool accounts connected to the user's wallet.
  final List<SavedToolModel> savedTools;

  /// Whether skills are being fetched from backend.
  final bool skillsLoading;

  /// Tool name currently being connected (shows credential form).
  final String? connectingTool;

  /// Error from last tool verification attempt.
  final String? toolVerifyError;

  /// Whether a tool verification is in progress.
  final bool toolVerifying;

  /// The Realm the user is currently "inside" on the Atlas (Enter button).
  /// null means viewing the root ecosystem.
  final String? enteredRealmId;
  final String? enteredRealmName;

  final int refreshToken;

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
    InvitationResponse? invitationResponse,
    bool? invitationLoading,
    String? invitationError,
    bool clearInvitation = false,
    bool clearInvitationError = false,
    List<SkillModel>? skills,
    List<AvailableToolModel>? availableTools,
    bool? toolsLoaded,
    bool? skillFormOpen,
    bool? approvalsOpen,
    int? pendingApprovalCount,
    Map<String, dynamic>? uploadedSkillData,
    Map<String, dynamic>? uploadedToolRegistry,
    bool? skillUploadLoading,
    bool clearUploadedSkill = false,
    SkillModel? editingSkill,
    bool clearEditingSkill = false,
    List<SavedToolModel>? savedTools,
    bool? skillsLoading,
    String? connectingTool,
    bool clearConnectingTool = false,
    String? toolVerifyError,
    bool clearToolVerifyError = false,
    bool? toolVerifying,
    String? enteredRealmId,
    bool clearEnteredRealm = false,
    String? enteredRealmName,
    int? refreshToken,
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
      invitationResponse: clearInvitation
          ? null
          : (invitationResponse ?? this.invitationResponse),
      invitationLoading: invitationLoading ?? this.invitationLoading,
      invitationError: clearInvitationError
          ? null
          : (invitationError ?? this.invitationError),
      skills: skills ?? this.skills,
      availableTools: availableTools ?? this.availableTools,
      toolsLoaded: toolsLoaded ?? this.toolsLoaded,
      skillFormOpen: skillFormOpen ?? this.skillFormOpen,
      approvalsOpen: approvalsOpen ?? this.approvalsOpen,
      pendingApprovalCount: pendingApprovalCount ?? this.pendingApprovalCount,
      uploadedSkillData: clearUploadedSkill
          ? null
          : (uploadedSkillData ?? this.uploadedSkillData),
      uploadedToolRegistry: clearUploadedSkill
          ? null
          : (uploadedToolRegistry ?? this.uploadedToolRegistry),
      skillUploadLoading: skillUploadLoading ?? this.skillUploadLoading,
      editingSkill: clearEditingSkill
          ? null
          : (editingSkill ?? this.editingSkill),
      savedTools: savedTools ?? this.savedTools,
      skillsLoading: skillsLoading ?? this.skillsLoading,
      connectingTool: clearConnectingTool
          ? null
          : (connectingTool ?? this.connectingTool),
      toolVerifyError: clearToolVerifyError
          ? null
          : (toolVerifyError ?? this.toolVerifyError),
      toolVerifying: toolVerifying ?? this.toolVerifying,
      enteredRealmId: clearEnteredRealm
          ? null
          : (enteredRealmId ?? this.enteredRealmId),
      enteredRealmName: clearEnteredRealm
          ? null
          : (enteredRealmName ?? this.enteredRealmName),
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}

/// Drives the Field's UI state. All interaction lives here, not in widgets.
class FieldController extends Notifier<FieldState> {
  @override
  FieldState build() {
    // Listen for the ecosystem state and update the realm identity accordingly.
    // When genesis exists → show it. When loading completes with no genesis →
    // show a "No Ecosystem" placeholder instead of the static fixture.
    ref.listen<EcosystemState>(ecosystemControllerProvider, (prev, next) {
      if (state.currentRealmId != 'kinship-duna') return;

      final genesis = next.genesis;
      if (genesis != null) {
        state = state.copyWith(
          currentRealm: FieldRealm(
            name: genesis.name,
            type: 'Ecosystem',
            emblemAsset: AppAssets.realmEmblem('organization'),
          ),
          currentRealmId: genesis.id,
        );
      } else if (!next.isLoading) {
        // Loading finished but no genesis exists — show placeholder.
        state = state.copyWith(
          currentRealm: const FieldRealm(
            name: 'No Ecosystem',
            type: 'Ecosystem',
            emblemAsset: '',
          ),
        );
      }
    });

    // Check the current ecosystem state immediately on build (handles the case
    // where the ecosystem was already loaded before this controller built).
    final ecosystem = ref.read(ecosystemControllerProvider);
    final initialRealm = ecosystem.genesis != null
        ? FieldRealm(
            name: ecosystem.genesis!.name,
            type: 'Ecosystem',
            emblemAsset: AppAssets.realmEmblem('organization'),
          )
        : const FieldRealm(
            name: 'No Ecosystem',
            type: 'Ecosystem',
            emblemAsset: '',
          );

    // Fetch pending approval count and gravity when auth state changes.
    ref.listen(authControllerProvider, (prev, next) {
      final wallet = next.user?.wallet;
      if (next.user != null &&
          wallet != null &&
          (prev?.user == null || prev?.user?.wallet != wallet)) {
        fetchPendingApprovalCount();
        _loadGravityFromApi(wallet);
      }
    });

    // Fetch pending approval count in the background.
    Future.microtask(fetchPendingApprovalCount);

    // Load gravity from API if wallet is already available.
    final authWallet = ref.read(authControllerProvider).user?.wallet;
    if (authWallet != null && authWallet.isNotEmpty) {
      Future.microtask(() => _loadGravityFromApi(authWallet));
    }

    return FieldState(
      kiTopic: FieldFixtures.defaultKi,
      currentRealm: initialRealm,
    );
  }

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

  void enterRealm(String realmId, String realmName) {
    state = state.copyWith(
      enteredRealmId: realmId,
      enteredRealmName: realmName,
    );
  }

  void exitEnteredRealm() {
    state = state.copyWith(clearEnteredRealm: true);
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
    final atlasRealm = realmAtlas[targetId];

    final String name;
    final String typeLabel;
    final String emblem;
    final String purpose;

    if (atlasRealm != null) {
      name = atlasRealm.name;
      typeLabel = atlasRealm.type.label;
      emblem =
          atlasRealm.type == AtlasRealmType.institution ||
              atlasRealm.type == AtlasRealmType.ecosystem
          ? 'conceptual'
          : atlasRealm.type.emblemKey;
      purpose = atlasRealm.purpose;
    } else {
      final ecoState = ref.read(ecosystemControllerProvider);
      final known = ecoState.knownNames[targetId];
      name = known ?? targetId;
      typeLabel = 'Realm';
      emblem = 'conceptual';
      purpose = '';
    }

    final isRoot = targetId == 'kinship-duna';
    state = state.copyWith(
      currentRealm: FieldRealm(
        name: name,
        type: typeLabel,
        emblemAsset: AppAssets.realmEmblem(emblem),
      ),
      currentRealmId: targetId,
      enteredRealmId: isRoot ? null : targetId,
      clearEnteredRealm: isRoot,
      clearSelection: true,
      actionsVisible: true,
      inspectOpen: false,
      realmPath: state.realmPath.sublist(0, index + 1),
      kiTopic: KiTopic(
        title: 'Inside $name',
        body: 'Alice is now inside $name, a $typeLabel. $purpose',
        invitation:
            'Possible Actions shows what can be done here. Inspect any '
            'nested Realm or use the breadcrumb to go back.',
      ),
    );
  }

  /// Sets the gravity level (1–5) for a realm and persists the override
  /// to the backend API.
  void setGravity(String realmId, int level) {
    final clamped = level.clamp(1, 5);
    state = state.copyWith(
      realmGravity: {...state.realmGravity, realmId: clamped},
    );

    final wallet = ref.read(authControllerProvider).user?.wallet;
    if (wallet != null && wallet.isNotEmpty) {
      const levelNames = {
        1: 'quiet',
        2: 'available',
        3: 'relevant',
        4: 'central',
        5: 'vital',
      };
      final levelName = levelNames[clamped] ?? 'relevant';
      GravityService.instance
          .setLevelOverride(wallet: wallet, realmId: realmId, level: levelName)
          .catchError((Object e) {
            AppLogger.warning(
              'Failed to persist gravity override',
              tag: 'FieldController',
            );
          });
    }
  }

  int gravityFor(String realmId) => state.realmGravity[realmId] ?? 3;

  /// Loads gravity scores from the backend API and populates [realmGravity].
  Future<void> _loadGravityFromApi(String wallet) async {
    try {
      final response = await GravityService.instance.fetchGravity(wallet);
      if (!ref.mounted) return;

      const levelToInt = {
        'vital': 5,
        'central': 4,
        'relevant': 3,
        'available': 2,
        'quiet': 1,
      };
      final map = <String, int>{};
      for (final realm in response.realms) {
        map[realm.id] = levelToInt[realm.level] ?? 3;
      }

      state = state.copyWith(realmGravity: {...state.realmGravity, ...map});
      AppLogger.info(
        'Gravity loaded: ${response.realms.length} realms',
        tag: 'FieldController',
      );
    } catch (e) {
      AppLogger.warning(
        'Gravity API load failed, using local defaults',
        tag: 'FieldController',
      );
    }
  }

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
      enteredRealmId: realm.id,
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
  ///
  /// When [type] is "Organization", the realm is persisted via
  /// `POST /api/v1/dunas/organizations` under the Genesis DUNA. The genesis
  /// organizations count is incremented server-side, and the ecosystem state
  /// is refreshed so the inspect panel reflects the new count.
  ///
  /// For other types, the realm is created locally (UI-only) as before.
  Future<void> createRealm({
    required String name,
    required String type,
    String? purpose,
  }) async {
    // Non-API types remain local (UI-only).
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

  /// Called by [RealmPanel] after a successful Organization creation.
  void onOrganizationCreated(String name) {
    // Refresh ecosystem state so the genesis organizations count updates.
    unawaited(ref.read(ecosystemControllerProvider.notifier).load());

    state = state.copyWith(
      currentRealm: FieldRealm(
        name: name,
        type: 'Organization',
        emblemAsset: AppAssets.realmEmblem('Organization'),
      ),
      openActions: state.openActions.where((item) => item != 'realm').toList(),
    );
    askAbout(
      KiTopic(
        title: '$name created',
        body:
            'Ki has created $name as an Organization under the Genesis '
            'ecosystem and brought Alice inside it.',
        invitation:
            "Ki can help shape the new Organization's purpose, boundaries, "
            'capacities, and people through dialogue.',
      ),
    );
  }

  /// Called by [RealmPanel] after a successful Realm creation (any type).
  /// Updates the field state and shows a Ki confirmation message.
  /// The API call itself lives in the panel so errors display in-form.
  void onRealmCreated(RealmModel realm) {
    final pda = realm.vaultPda;
    final walletInfo = pda != null
        ? 'Team Wallet ${pda.substring(0, 4)}…${pda.substring(pda.length - 4)} ready.'
        : '';

    state = state.copyWith(
      openActions: state.openActions.where((item) => item != 'realm').toList(),
      refreshToken: state.refreshToken + 1,
    );

    final parentId = realm.parentId ?? state.enteredRealmId;
    final eco = ref.read(ecosystemControllerProvider.notifier);
    if (parentId != null && parentId != 'kinship-duna') {
      unawaited(eco.loadChildren(parentId));
    } else {
      unawaited(eco.load());
    }

    final statusNote = realm.type == 'institution'
        ? ' Status: ${realm.status}.'
        : '';

    askAbout(
      KiTopic(
        title: '${realm.name} created',
        body:
            'Ki has created the ${realm.typeLabel} "${realm.name}" with handle '
            '@${realm.handle}.$statusNote $walletInfo',
        invitation:
            'Ki can help add members, shape purpose and boundaries, or '
            'configure the ${realm.typeLabel}.',
      ),
    );
  }

  /// Check if a handle is available for any Realm type (unified endpoint).
  Future<bool> checkHandleAvailability(String handle) async {
    return RealmService.instance.checkHandleAvailability(handle);
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

  // ── Skills ───────────────────────────────────────────────────────────

  /// Open the skill creation form as a separate working panel.
  void openApprovals() {
    state = state.copyWith(approvalsOpen: true);
  }

  void closeApprovals() {
    state = state.copyWith(approvalsOpen: false);
    // Refresh count after panel closes (approvals may have been resolved).
    fetchPendingApprovalCount();
  }

  /// Fetch the number of pending approvals for the current user.
  Future<void> fetchPendingApprovalCount() async {
    final auth = ref.read(authControllerProvider);
    final wallet = auth.user?.wallet ?? '';
    AppLogger.info(
      'fetchPendingApprovalCount: wallet=${wallet.isEmpty ? "EMPTY" : wallet.substring(0, 10)}...',
      tag: 'FieldController',
    );
    if (wallet.isEmpty) return;

    try {
      final approvals = await ApprovalService.instance.fetchPending(
        wallet: wallet,
      );
      if (!ref.mounted) return;
      AppLogger.info(
        'Pending approvals: ${approvals.length}',
        tag: 'FieldController',
      );
      state = state.copyWith(pendingApprovalCount: approvals.length);
    } catch (e) {
      AppLogger.warning(
        'fetchPendingApprovalCount failed: $e',
        tag: 'FieldController',
      );
    }
  }

  void openSkillForm() {
    state = state.copyWith(skillFormOpen: true, clearEditingSkill: true);
    fetchAvailableTools();
  }

  /// Open skill form with pre-filled data from uploaded MD.
  void openSkillUpload() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md'],
        withData: true,
      );
      if (result.isEmpty) return;

      final bytes = await result.first.readAsBytes();
      if (bytes.isEmpty) return;

      final content = String.fromCharCodes(bytes);
      if (content.trim().isEmpty) return;

      // Show loading on the upload button.
      state = state.copyWith(skillUploadLoading: true);

      // Parse the MD file via backend.
      final parsed = await SkillService.instance.uploadSkillMd(content);
      if (parsed == null || !ref.mounted) {
        state = state.copyWith(skillUploadLoading: false);
        return;
      }

      // Check if the detected tool is available.
      final tool = (parsed['tool'] as String? ?? '').toLowerCase();
      Map<String, dynamic>? registryInfo;
      if (tool.isNotEmpty) {
        registryInfo = await SkillService.instance.searchRegistry(tool);
      }

      if (!ref.mounted) return;

      // Open form with parsed data.
      state = state.copyWith(
        skillFormOpen: true,
        clearEditingSkill: true,
        uploadedSkillData: parsed,
        uploadedToolRegistry: registryInfo,
        skillUploadLoading: false,
      );
    } catch (e) {
      AppLogger.warning('Skill upload failed: $e', tag: 'FieldController');
      if (ref.mounted) {
        state = state.copyWith(skillUploadLoading: false);
      }
    }
  }

  /// Close the skill creation form panel.
  void closeSkillForm() {
    state = state.copyWith(
      skillFormOpen: false,
      clearEditingSkill: true,
      clearUploadedSkill: true,
    );
  }

  /// Fetch available tools from MCP servers.
  ///
  /// Only fetches once — subsequent calls return immediately unless
  /// [force] is true. Results are stored in [FieldState.availableTools].
  Future<void> fetchAvailableTools({bool force = false}) async {
    if (state.toolsLoaded && !force) {
      return;
    }
    try {
      final tools = await SkillService.instance.fetchTools();
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(availableTools: tools, toolsLoaded: true);
      AppLogger.info(
        'Available tools loaded: ${tools.length}',
        tag: 'FieldController',
      );
    } on AppException catch (e) {
      AppLogger.warning(
        'Failed to fetch tools: ${e.message}',
        tag: 'FieldController',
      );
      // Mark as loaded even on failure — prevents infinite retry loops.
      // User can force-refresh via fetchAvailableTools(force: true).
      if (ref.mounted) {
        state = state.copyWith(toolsLoaded: true);
      }
    }
  }

  /// Fetch skills from the backend and replace local state.
  Future<void> fetchSkills() async {
    state = state.copyWith(skillsLoading: true);
    try {
      final skills = await SkillService.instance.list();
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(skills: skills, skillsLoading: false);
    } on AppException catch (e) {
      AppLogger.warning(
        'Failed to fetch skills: ${e.message}',
        tag: 'FieldController',
      );
      if (ref.mounted) {
        state = state.copyWith(skillsLoading: false);
      }
    }
  }

  /// Create a skill — adds it locally first, then syncs via `POST /api/skills`.
  ///
  /// The skill appears in the list immediately. If the backend responds, the
  /// local entry is replaced with the server version (real id, file path, etc.).
  void createSkill({
    required String name,
    required SkillTriggerType triggerType,
    required String whenText,
    required String thenText,
    List<String> tools = const [],
    bool requiresApproval = false,
  }) {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final localId = 'local-$slug-${state.skills.length}';
    final skill = SkillModel(
      id: localId,
      name: name,
      triggerType: triggerType,
      whenText: whenText,
      thenText: thenText,
      tools: tools,
      requiresApproval: requiresApproval,
      realmId: state.currentRealmId != 'kinship-duna'
          ? state.currentRealmId
          : null,
      skillFilePath: '$slug.md',
    );

    state = state.copyWith(
      skills: [...state.skills, skill],
      skillFormOpen: false,
    );
    askAbout(
      KiTopic(
        title: '$name created',
        body:
            'Ki has created the Skill "$name". It activates on '
            '${triggerType.name} and is now available in the Realm.',
        invitation:
            'The Skill is ready. Edit it to refine its behavior, or '
            'create another one.',
      ),
    );

    _syncSkillToBackend(skill, localId);
  }

  Future<void> _syncSkillToBackend(SkillModel skill, String localId) async {
    final auth = ref.read(authControllerProvider);
    final wallet = auth.user?.wallet;
    if (wallet == null || wallet.isEmpty) {
      return;
    }

    try {
      final created = await SkillService.instance.create(skill, wallet: wallet);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        skills: [
          for (final s in state.skills)
            if (s.id == localId) created else s,
        ],
      );
      AppLogger.info('Skill synced: ${created.id}', tag: 'FieldController');

      // Attach the skill to the Ki agent so the scheduler activates it.
      await _attachSkillToAlly(created.id);

      // Generate AI SKILL.md content in the background.
      // Use original skill data (has correct when/then text) with
      // the backend-assigned ID from created.
      _generateSkillContent(
        SkillModel(
          id: created.id,
          name: skill.name,
          triggerType: skill.triggerType,
          whenText: skill.whenText,
          thenText: skill.thenText,
          tools: skill.tools,
        ),
      );
    } on AppException catch (e) {
      AppLogger.warning(
        'Skill sync failed: ${e.message}',
        tag: 'FieldController',
      );
    }
  }

  /// Generate AI SKILL.md content and update the skill.
  Future<void> _generateSkillContent(SkillModel skill) async {
    try {
      final content = await SkillService.instance.generateContent(
        name: skill.name,
        triggerType: skill.triggerType.name,
        whenText: skill.whenText,
        thenText: skill.thenText,
        tools: skill.tools,
      );

      if (content == null || content.isEmpty || !ref.mounted) {
        return;
      }

      // Update skill with generated content.
      final updated = await SkillService.instance.update(
        skill.id,
        skillContent: content,
      );

      if (!ref.mounted) {
        return;
      }

      state = state.copyWith(
        skills: [
          for (final s in state.skills)
            if (s.id == skill.id) updated else s,
        ],
      );
      AppLogger.info(
        'SKILL.md generated for ${skill.id}',
        tag: 'FieldController',
      );
    } on AppException catch (e) {
      AppLogger.warning(
        'SKILL.md generation failed: ${e.message}',
        tag: 'FieldController',
      );
    }
  }

  /// Attach a skill to the Ki agent (Ally) via `PATCH /api/agents/{id}`.
  ///
  /// Reads the ally's current skill_ids — since [AllyAgentModel] doesn't
  /// track skill_ids, we pass an empty list and let the backend append.
  /// The backend's PATCH handler merges skill_ids correctly.
  Future<void> _attachSkillToAlly(String skillId) async {
    final ally = ref.read(allyControllerProvider).ally;
    if (ally == null) {
      AppLogger.warning(
        'Cannot attach skill: ally not loaded',
        tag: 'FieldController',
      );
      return;
    }

    try {
      await SkillService.instance.attachSkillToAgent(
        agentId: ally.id,
        newSkillId: skillId,
      );
      AppLogger.info(
        'Skill $skillId attached to ally ${ally.id}',
        tag: 'FieldController',
      );
    } on AppException catch (e) {
      AppLogger.warning(
        'Failed to attach skill to ally: ${e.message}',
        tag: 'FieldController',
      );
    }
  }

  /// Update an existing skill — replaces locally, then syncs to backend.
  void updateSkill({
    required String skillId,
    required String name,
    required SkillTriggerType triggerType,
    required String whenText,
    required String thenText,
    List<String> tools = const [],
    bool requiresApproval = false,
  }) {
    // Optimistic local update.
    state = state.copyWith(
      skills: [
        for (final s in state.skills)
          if (s.id == skillId)
            SkillModel(
              id: s.id,
              name: name,
              triggerType: triggerType,
              whenText: whenText,
              thenText: thenText,
              tools: tools,
              skillContent: s.skillContent,
              skillFilePath: s.skillFilePath,
              requiresApproval: requiresApproval,
              status: s.status,
              createdAt: s.createdAt,
              updatedAt: DateTime.now(),
            )
          else
            s,
      ],
      skillFormOpen: false,
      clearEditingSkill: true,
    );

    askAbout(
      KiTopic(
        title: '$name updated',
        body: 'Ki has updated the Skill "$name".',
        invitation:
            'The changes are saved. Continue editing or create '
            'another Skill.',
      ),
    );

    if (!skillId.startsWith('local-')) {
      _syncSkillUpdate(
        skillId,
        name,
        whenText,
        thenText,
        tools,
        requiresApproval,
      );
    }
  }

  Future<void> _syncSkillUpdate(
    String skillId,
    String name,
    String whenText,
    String thenText,
    List<String> tools,
    bool requiresApproval,
  ) async {
    final wallet = ref.read(authControllerProvider).user?.wallet;
    try {
      final updated = await SkillService.instance.update(
        skillId,
        name: name,
        whenText: whenText,
        thenText: thenText,
        tools: tools,
        requiresApproval: requiresApproval,
        wallet: wallet,
      );
      if (!ref.mounted) {
        return;
      }
      // Replace local with server version.
      state = state.copyWith(
        skills: [
          for (final s in state.skills)
            if (s.id == skillId) updated else s,
        ],
      );
      AppLogger.info('Skill update synced: $skillId', tag: 'FieldController');
    } on AppException catch (e) {
      AppLogger.warning(
        'Skill update sync failed: ${e.message}',
        tag: 'FieldController',
      );
    }
  }

  /// Remove a skill locally and delete it from the backend.
  void removeSkill(String skillId) {
    state = state.copyWith(
      skills: state.skills.where((s) => s.id != skillId).toList(),
    );

    // Skip backend call for local-only skills that never synced.
    if (!skillId.startsWith('local-')) {
      _deleteSkillFromBackend(skillId);
    }
  }

  Future<void> _deleteSkillFromBackend(String skillId) async {
    try {
      await SkillService.instance.delete(skillId);
      AppLogger.info('Skill deleted: $skillId', tag: 'FieldController');
    } on AppException catch (e) {
      AppLogger.warning(
        'Skill delete failed: ${e.message}',
        tag: 'FieldController',
      );
    }
  }

  /// Pause an active skill.
  void pauseSkill(String skillId) {
    _updateSkillStatus(skillId, 'paused');
  }

  /// Resume a paused skill.
  void resumeSkill(String skillId) {
    _updateSkillStatus(skillId, 'active');
  }

  void _updateSkillStatus(String skillId, String status) {
    // Optimistic local update.
    state = state.copyWith(
      skills: [
        for (final s in state.skills)
          if (s.id == skillId)
            SkillModel(
              id: s.id,
              name: s.name,
              triggerType: s.triggerType,
              whenText: s.whenText,
              thenText: s.thenText,
              tools: s.tools,
              skillContent: s.skillContent,
              skillFilePath: s.skillFilePath,
              requiresApproval: s.requiresApproval,
              status: status,
              createdAt: s.createdAt,
              updatedAt: s.updatedAt,
            )
          else
            s,
      ],
    );

    if (!skillId.startsWith('local-')) {
      _syncSkillStatus(skillId, status);
    }
  }

  Future<void> _syncSkillStatus(String skillId, String status) async {
    try {
      await SkillService.instance.updateStatus(
        skillId: skillId,
        status: status,
      );
    } on AppException catch (e) {
      AppLogger.warning(
        'Skill status update failed: ${e.message}',
        tag: 'FieldController',
      );
    }
  }

  /// Open the skill form pre-filled for editing an existing skill.
  void editSkill(String skillId) {
    final skill = state.skills.where((s) => s.id == skillId).firstOrNull;
    if (skill == null) {
      return;
    }
    state = state.copyWith(skillFormOpen: true, editingSkill: skill);
    fetchAvailableTools();
  }

  // ── Tool connections ────────────────────────────────────────────────

  /// Fetch saved tool accounts for the current wallet.
  Future<void> fetchSavedTools() async {
    final wallet = ref.read(authControllerProvider).user?.wallet;
    if (wallet == null || wallet.isEmpty) {
      return;
    }
    try {
      final tools = await ToolConnectionService.instance.listSaved(wallet);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(savedTools: tools);
    } on AppException catch (e) {
      AppLogger.warning(
        'Failed to fetch saved tools: ${e.message}',
        tag: 'FieldController',
      );
    }
  }

  /// Open Google OAuth in a popup window. No credential form needed —
  /// backend handles the entire flow via `/api/oauth/google/init`.
  ///
  /// After the popup completes, [fetchSavedTools] refreshes the list.
  /// On web, WidgetsBindingObserver detects tab focus return.
  /// On desktop, we poll every 5s for up to 120s to detect the new connection.
  Future<void> connectGoogleOAuth() async {
    final wallet = ref.read(authControllerProvider).user?.wallet;
    if (wallet == null || wallet.isEmpty) {
      AppLogger.warning(
        'Cannot start Google OAuth: wallet not available',
        tag: 'FieldController',
      );
      return;
    }

    // Count connected Google tools before OAuth
    final beforeCount = state.savedTools
        .where((t) => t.toolName == 'google' && t.isActive)
        .length;

    final baseUrl = Env.apiBaseUrl;
    final oauthUrl = Uri.parse(
      '$baseUrl/api/oauth/google/init?wallet=$wallet&popup=true',
    );

    try {
      final launched = await launchUrl(oauthUrl, webOnlyWindowName: '_blank');
      if (!launched) {
        AppLogger.warning(
          'Could not open Google OAuth URL',
          tag: 'FieldController',
        );
        return;
      }

      AppLogger.info('Google OAuth popup opened', tag: 'FieldController');

      // Poll for connection changes — works on all platforms (web + desktop).
      // Stops after detecting a new connection or after 120s timeout.
      _startOAuthPoll(beforeCount);
    } catch (e) {
      AppLogger.warning(
        'Google OAuth launch failed: $e',
        tag: 'FieldController',
      );
    }
  }

  Timer? _oauthPollTimer;

  void _startOAuthPoll(int beforeCount) {
    _oauthPollTimer?.cancel();
    var attempts = 0;
    const maxAttempts = 24; // 24 × 5s = 120s

    _oauthPollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      attempts++;
      if (attempts > maxAttempts) {
        timer.cancel();
        _oauthPollTimer = null;
        AppLogger.info(
          'OAuth poll timed out after ${maxAttempts * 5}s',
          tag: 'FieldController',
        );
        return;
      }

      try {
        await fetchSavedTools();
        final afterCount = state.savedTools
            .where((t) => t.toolName == 'google' && t.isActive)
            .length;

        if (afterCount > beforeCount) {
          timer.cancel();
          _oauthPollTimer = null;
          AppLogger.info(
            'Google OAuth connection detected after ${attempts * 5}s',
            tag: 'FieldController',
          );
        }
      } catch (_) {}
    });
  }

  /// Open the credential form for a specific tool.
  void startConnectingTool(String toolName) {
    state = state.copyWith(
      connectingTool: toolName,
      clearToolVerifyError: true,
      toolVerifying: false,
    );
  }

  /// Cancel the credential form.
  void cancelConnectingTool() {
    state = state.copyWith(
      clearConnectingTool: true,
      clearToolVerifyError: true,
      toolVerifying: false,
    );
  }

  /// Verify and save tool credentials — two-step: verify then save.
  Future<void> connectTool({
    required String toolName,
    required Map<String, String> credentials,
  }) async {
    final wallet = ref.read(authControllerProvider).user?.wallet;
    if (wallet == null || wallet.isEmpty) {
      state = state.copyWith(toolVerifyError: 'Wallet not available');
      return;
    }

    state = state.copyWith(toolVerifying: true, clearToolVerifyError: true);

    try {
      // Step 1: Verify credentials with backend.
      final result = await ToolConnectionService.instance.verify(
        toolName: toolName,
        credentials: credentials,
      );

      if (!ref.mounted) {
        return;
      }

      if (!result.success) {
        state = state.copyWith(
          toolVerifying: false,
          toolVerifyError: result.error ?? 'Verification failed',
        );
        return;
      }

      // Step 2: Save to the wallet's global pool.
      // Merge verify result identity into credentials so backend can
      // store external_handle and external_user_id properly.
      final enrichedCredentials = {
        ...credentials,
        if (result.externalHandle != null)
          'external_handle': result.externalHandle!,
        if (result.externalUserId != null)
          'external_user_id': result.externalUserId!,
      };

      // Check for duplicate — skip save if this account is already connected.
      final alreadyConnected = state.savedTools.any(
        (t) =>
            t.toolName == toolName &&
            t.isActive &&
            result.externalHandle != null &&
            t.externalHandle == result.externalHandle,
      );
      if (alreadyConnected) {
        state = state.copyWith(
          toolVerifying: false,
          toolVerifyError: '${result.externalHandle} is already connected',
        );
        return;
      }

      final saved = await ToolConnectionService.instance.save(
        wallet: wallet,
        toolName: toolName,
        credentials: enrichedCredentials,
        realmId: state.currentRealmId != 'kinship-duna'
            ? state.currentRealmId
            : null,
      );

      if (!ref.mounted) {
        return;
      }

      if (!saved) {
        state = state.copyWith(
          toolVerifying: false,
          toolVerifyError: 'Failed to save connection',
        );
        return;
      }

      // Refresh the saved tools list.
      final tools = await ToolConnectionService.instance.listSaved(wallet);

      if (!ref.mounted) {
        return;
      }

      state = state.copyWith(
        savedTools: tools,
        toolVerifying: false,
        clearConnectingTool: true,
        clearToolVerifyError: true,
      );

      final handle = result.externalHandle ?? toolName;
      askAbout(
        KiTopic(
          title: '$toolName connected',
          body:
              'Connected as $handle. This tool is now available for '
              'skills and agents in this Ecosystem.',
          invitation: 'You can disconnect at any time from this panel.',
        ),
      );

      AppLogger.info(
        'Tool $toolName connected: $handle',
        tag: 'FieldController',
      );
    } on AppException catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          toolVerifying: false,
          toolVerifyError: e.message,
        );
      }
    }
  }

  /// Disconnect a tool account.
  Future<void> disconnectTool(String toolId) async {
    final wallet = ref.read(authControllerProvider).user?.wallet;
    if (wallet == null || wallet.isEmpty) {
      return;
    }

    // Optimistic removal.
    final removed = state.savedTools.where((t) => t.id == toolId).firstOrNull;
    state = state.copyWith(
      savedTools: state.savedTools.where((t) => t.id != toolId).toList(),
    );

    try {
      final success = await ToolConnectionService.instance.remove(
        wallet: wallet,
        id: toolId,
      );
      if (!success && ref.mounted && removed != null) {
        // Rollback on failure.
        state = state.copyWith(savedTools: [...state.savedTools, removed]);
      }
    } on AppException catch (e) {
      AppLogger.warning(
        'Disconnect failed: ${e.message}',
        tag: 'FieldController',
      );
      // Rollback.
      if (ref.mounted && removed != null) {
        state = state.copyWith(savedTools: [...state.savedTools, removed]);
      }
    }
  }

  // ── Invitation API ───────────────────────────────────────────────────

  /// Generate an invitation code via the backend API.
  ///
  /// Reads the logged-in user's wallet from [authControllerProvider], sends
  /// the form fields to `POST /api/v1/codes`, and stores the response so the
  /// review panel can display the real code, link, and message.
  Future<void> prepareInvitation({
    required String role,
    required String expiration,
    required int maxUses,
    String? recipientName,
    String? label,
    double kidunaPerPerson = 0,
  }) async {
    final realmId = state.enteredRealmId ?? state.currentRealmId;
    print('[prepareInvitation] realmId=$realmId');
    if (realmId.isEmpty) {
      state = state.copyWith(invitationError: 'No realm selected.');
      return;
    }

    state = state.copyWith(invitationLoading: true, clearInvitationError: true);

    try {
      final request = InvitationRequest(
        realmId: realmId,
        role: role,
        expiration: expiration,
        maxUses: maxUses,
        recipientName: recipientName,
        label: label,
        kidunaPerPerson: kidunaPerPerson,
      );

      final response = await InvitationService.instance.generate(request);

      state = state.copyWith(
        invitationResponse: response,
        invitationLoading: false,
        kiTopic: KiTopic(
          title: 'Invitation prepared',
          body:
              'Your invitation is ready! ${response.summary}.',
          invitation:
              'Copy the invite link or code and share it. '
              'Recipients will see your profile and can join directly.',
        ),
      );

      AppLogger.info(
        'Invitation prepared: ${response.code}',
        tag: 'FieldController',
      );
    } on UnauthorizedException {
      state = state.copyWith(
        invitationLoading: false,
        invitationError: 'Session expired. Please log in again.',
      );
    } on NetworkException {
      state = state.copyWith(
        invitationLoading: false,
        invitationError: 'Unable to connect. Please check your internet.',
      );
    } on AppException catch (e) {
      state = state.copyWith(
        invitationLoading: false,
        invitationError: e.message ?? 'Failed to create invitation.',
      );
    }
  }

  /// Reset invitation state (e.g. when the invite panel closes).
  void clearInvitation() => state = state.copyWith(
    clearInvitation: true,
    clearInvitationError: true,
    invitationLoading: false,
  );
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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/instruct_model.dart';
import '../../../data/services/instruct_service.dart';
import '../../auth/controllers/auth_controller.dart';
import 'ally_controller.dart';
import 'field_controller.dart';

/// Global presence (instruct listing + detail) state provider.
final presenceControllerProvider =
    NotifierProvider<PresenceController, PresenceState>(
  PresenceController.new,
);

class PresenceState {
  const PresenceState({
    this.isLoading = false,
    this.isGenerating = false,
    this.isValidating = false,
    this.instructs = const [],
    this.activeInstruct,
    this.detailOpen = false,
    this.isCreateMode = false,
    this.error,
  });

  final bool isLoading;
  final bool isGenerating;
  final bool isValidating;
  final List<InstructModel> instructs;
  final InstructModel? activeInstruct;
  final bool detailOpen;
  final bool isCreateMode;
  final String? error;

  PresenceState copyWith({
    bool? isLoading,
    bool? isGenerating,
    bool? isValidating,
    List<InstructModel>? instructs,
    InstructModel? activeInstruct,
    bool? detailOpen,
    bool? isCreateMode,
    String? error,
    bool clearError = false,
    bool clearActiveInstruct = false,
  }) {
    return PresenceState(
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      isValidating: isValidating ?? this.isValidating,
      instructs: instructs ?? this.instructs,
      activeInstruct:
          clearActiveInstruct ? null : (activeInstruct ?? this.activeInstruct),
      detailOpen: detailOpen ?? this.detailOpen,
      isCreateMode: isCreateMode ?? this.isCreateMode,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PresenceController extends Notifier<PresenceState> {
  InstructService get _service => InstructService.instance;

  @override
  PresenceState build() => const PresenceState();

  String get _wallet =>
      ref.read(authControllerProvider).user?.wallet ?? '';

  String? get _kiAgentId =>
      ref.read(allyControllerProvider).ally?.id;

  /// Load all instructs for current wallet.
  Future<void> loadInstructs() async {
    if (_wallet.isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final instructs = await _service.listInstructs(_wallet);
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, instructs: instructs);
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? 'Failed to load instructs.',
      );
    }
  }

  /// Open detail panel for existing instruct.
  void openDetail(String instructId) {
    final instruct =
        state.instructs.where((i) => i.id == instructId).firstOrNull;
    state = state.copyWith(
      detailOpen: true,
      isCreateMode: false,
      activeInstruct: instruct,
    );
  }

  /// Open detail panel in create mode.
  void openCreate() {
    state = state.copyWith(
      detailOpen: true,
      isCreateMode: true,
      clearActiveInstruct: true,
    );
  }

  /// Close detail panel.
  void closeDetail() {
    state = state.copyWith(
      detailOpen: false,
      isCreateMode: false,
    );
  }

  /// Create a new instruct and link to Ki agent.
  Future<void> createInstruct({
    required String name,
    String content = '',
    String? goal,
    String? connectedKbId,
    String? connectedKbName,
  }) async {
    if (_wallet.isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final realmId = ref.read(fieldControllerProvider).currentRealmId;
      final instruct = await _service.createInstruct(
        name: name,
        wallet: _wallet,
        content: content,
        goal: goal,
        realmId: realmId != 'kinship-duna' ? realmId : null,
        connectedKbId: connectedKbId,
        connectedKbName: connectedKbName,
      );
      if (!ref.mounted) return;

      // Link to Ki agent.
      final kiId = _kiAgentId;
      if (kiId != null) {
        await ref
            .read(allyControllerProvider.notifier)
            .updatePromptId(instruct.id);
      }

      state = state.copyWith(
        isLoading: false,
        instructs: [...state.instructs, instruct],
        activeInstruct: instruct,
        isCreateMode: false,
      );

      AppLogger.info(
        'Created instruct ${instruct.id} linked to Ki',
        tag: 'PresenceCtrl',
      );
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? 'Failed to create instruct.',
      );
    }
  }

  /// Update existing instruct.
  Future<void> updateInstruct(
    String instructId, {
    String? name,
    String? content,
    String? goal,
    String? connectedKbId,
    String? connectedKbName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final updated = await _service.updateInstruct(
        instructId,
        name: name,
        content: content,
        goal: goal,
        connectedKbId: connectedKbId,
        connectedKbName: connectedKbName,
      );
      if (!ref.mounted) return;

      final updatedList = state.instructs.map((i) {
        return i.id == instructId ? updated : i;
      }).toList();

      state = state.copyWith(
        isLoading: false,
        instructs: updatedList,
        activeInstruct: updated,
      );
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? 'Failed to update instruct.',
      );
    }
  }

  /// Delete an instruct.
  Future<void> deleteInstruct(String instructId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.deleteInstruct(instructId);
      if (!ref.mounted) return;

      final updatedList =
          state.instructs.where((i) => i.id != instructId).toList();

      final shouldClose = state.activeInstruct?.id == instructId;

      state = state.copyWith(
        isLoading: false,
        instructs: updatedList,
        detailOpen: shouldClose ? false : null,
        clearActiveInstruct: shouldClose,
      );

      AppLogger.info('Deleted instruct $instructId', tag: 'PresenceCtrl');
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? 'Failed to delete instruct.',
      );
    }
  }

  /// Generate system prompt content from goal via AI.
  Future<String?> generateFromGoal({
    required String goal,
    String? knowledgeBaseName,
  }) async {
    state = state.copyWith(isGenerating: true, clearError: true);

    try {
      final content = await _service.generateFromGoal(
        goal: goal,
        knowledgeBaseName: knowledgeBaseName,
      );
      if (!ref.mounted) return null;

      state = state.copyWith(isGenerating: false);
      return content;
    } on AppException catch (e) {
      if (!ref.mounted) return null;
      state = state.copyWith(
        isGenerating: false,
        error: e.message ?? 'AI generation failed.',
      );
      return null;
    }
  }

  /// Validate goal clarity via AI before generation.
  Future<({bool valid, String message})> validateGoal({
    required String goal,
    String? name,
  }) async {
    state = state.copyWith(isValidating: true, clearError: true);

    try {
      final result = await _service.validateGoal(goal: goal, name: name);
      if (!ref.mounted) {
        return (valid: false, message: '');
      }

      state = state.copyWith(isValidating: false);
      return result;
    } on AppException catch (e) {
      if (!ref.mounted) {
        return (valid: false, message: '');
      }
      state = state.copyWith(isValidating: false);
      AppLogger.warning(
        'Goal validation failed: ${e.message}',
        tag: 'PresenceCtrl',
      );
      return (valid: true, message: e.message ?? '');
    } catch (e) {
      if (!ref.mounted) {
        return (valid: false, message: '');
      }
      state = state.copyWith(isValidating: false);
      AppLogger.warning(
        'Goal validation error: $e',
        tag: 'PresenceCtrl',
      );
      return (valid: true, message: '');
    }
  }
}
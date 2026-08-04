import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/prompt_model.dart';
import '../../../data/services/prompt_service.dart';
import '../../auth/controllers/auth_controller.dart';
import 'ally_controller.dart';

/// Global presence (prompt listing + detail) state provider.
final presenceControllerProvider =
    NotifierProvider<PresenceController, PresenceState>(
  PresenceController.new,
);

class PresenceState {
  const PresenceState({
    this.isLoading = false,
    this.isGenerating = false,
    this.isValidating = false,
    this.prompts = const [],
    this.activePrompt,
    this.detailOpen = false,
    this.isCreateMode = false,
    this.error,
  });

  final bool isLoading;
  final bool isGenerating;
  final bool isValidating;
  final List<PromptModel> prompts;
  final PromptModel? activePrompt;
  final bool detailOpen;
  final bool isCreateMode;
  final String? error;

  PresenceState copyWith({
    bool? isLoading,
    bool? isGenerating,
    bool? isValidating,
    List<PromptModel>? prompts,
    PromptModel? activePrompt,
    bool? detailOpen,
    bool? isCreateMode,
    String? error,
    bool clearError = false,
    bool clearActivePrompt = false,
  }) {
    return PresenceState(
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      isValidating: isValidating ?? this.isValidating,
      prompts: prompts ?? this.prompts,
      activePrompt:
          clearActivePrompt ? null : (activePrompt ?? this.activePrompt),
      detailOpen: detailOpen ?? this.detailOpen,
      isCreateMode: isCreateMode ?? this.isCreateMode,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PresenceController extends Notifier<PresenceState> {
  PromptService get _service => PromptService.instance;

  @override
  PresenceState build() => const PresenceState();

  String get _wallet =>
      ref.read(authControllerProvider).user?.wallet ?? '';

  String? get _kiAgentId =>
      ref.read(allyControllerProvider).ally?.id;

  /// Load all prompts for current wallet.
  Future<void> loadPrompts() async {
    if (_wallet.isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final prompts = await _service.listPrompts(_wallet);
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, prompts: prompts);
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? 'Failed to load prompts.',
      );
    }
  }

  /// Open detail panel for existing prompt.
  void openDetail(String promptId) {
    final prompt = state.prompts.where((p) => p.id == promptId).firstOrNull;
    state = state.copyWith(
      detailOpen: true,
      isCreateMode: false,
      activePrompt: prompt,
    );
  }

  /// Open detail panel in create mode.
  void openCreate() {
    state = state.copyWith(
      detailOpen: true,
      isCreateMode: true,
      clearActivePrompt: true,
    );
  }

  /// Close detail panel.
  void closeDetail() {
    state = state.copyWith(
      detailOpen: false,
      isCreateMode: false,
    );
  }

  /// Create a new prompt and link to Ki agent.
  Future<void> createPrompt({
    required String name,
    String content = '',
    String? goal,
    String? connectedKbId,
    String? connectedKbName,
  }) async {
    if (_wallet.isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final prompt = await _service.createPrompt(
        name: name,
        wallet: _wallet,
        content: content,
        goal: goal,
        connectedKbId: connectedKbId,
        connectedKbName: connectedKbName,
      );
      if (!ref.mounted) return;

      // Link to Ki agent.
      final kiId = _kiAgentId;
      if (kiId != null) {
        await ref
            .read(allyControllerProvider.notifier)
            .updatePromptId(prompt.id);
      }

      state = state.copyWith(
        isLoading: false,
        prompts: [...state.prompts, prompt],
        activePrompt: prompt,
        isCreateMode: false,
      );

      AppLogger.info(
        'Created prompt ${prompt.id} linked to Ki',
        tag: 'PresenceCtrl',
      );
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? 'Failed to create prompt.',
      );
    }
  }

  /// Update existing prompt.
  Future<void> updatePrompt(
    String promptId, {
    String? name,
    String? content,
    String? goal,
    String? connectedKbId,
    String? connectedKbName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final updated = await _service.updatePrompt(
        promptId,
        name: name,
        content: content,
        goal: goal,
        connectedKbId: connectedKbId,
        connectedKbName: connectedKbName,
      );
      if (!ref.mounted) return;

      final updatedList = state.prompts.map((p) {
        return p.id == promptId ? updated : p;
      }).toList();

      state = state.copyWith(
        isLoading: false,
        prompts: updatedList,
        activePrompt: updated,
      );
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? 'Failed to update prompt.',
      );
    }
  }

  /// Delete a prompt.
  Future<void> deletePrompt(String promptId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.deletePrompt(promptId);
      if (!ref.mounted) return;

      final updatedList =
          state.prompts.where((p) => p.id != promptId).toList();

      // If detail panel was open for this prompt, close it.
      final shouldClose = state.activePrompt?.id == promptId;

      state = state.copyWith(
        isLoading: false,
        prompts: updatedList,
        detailOpen: shouldClose ? false : null,
        clearActivePrompt: shouldClose,
      );

      AppLogger.info('Deleted prompt $promptId', tag: 'PresenceCtrl');
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? 'Failed to delete prompt.',
      );
    }
  }

  /// Generate system prompt content from goal via AI.
  Future<String?> generateFromGoal({
    required String goal,
    String? name,
    String? knowledgeBaseName,
  }) async {
    state = state.copyWith(isGenerating: true, clearError: true);

    try {
      final content = await _service.generateFromGoal(
        goal: goal,
        name: name,
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
  /// Returns `(valid, message)` — message contains GPT feedback.
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
      // On API error, allow generation (same as backend fallback).
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
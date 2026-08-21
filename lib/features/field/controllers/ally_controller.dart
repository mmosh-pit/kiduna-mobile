import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/ally_agent_model.dart';
import '../../../data/services/ally_service.dart';

/// State for the system ally agent.
@immutable
class AllyState {
  const AllyState({
    this.isLoading = false,
    this.isSavingPresence = false,
    this.error,
    this.ally,
  });

  final bool isLoading;
  final bool isSavingPresence;
  final String? error;
  final AllyAgentModel? ally;

  AllyState copyWith({
    bool? isLoading,
    bool? isSavingPresence,
    String? error,
    AllyAgentModel? ally,
    bool clearError = false,
    bool clearAlly = false,
  }) {
    return AllyState(
      isLoading: isLoading ?? this.isLoading,
      isSavingPresence: isSavingPresence ?? this.isSavingPresence,
      error: clearError ? null : (error ?? this.error),
      ally: clearAlly ? null : (ally ?? this.ally),
    );
  }
}

/// Fetches and holds the system ally agent (Ki).
///
/// On [build] the controller fetches the ally immediately. The ally's [id]
/// is the `presenceId` required by the chat streaming endpoint.
class AllyController extends Notifier<AllyState> {
  @override
  AllyState build() {
    Future.microtask(_fetchAlly);
    return const AllyState(isLoading: true);
  }

  Future<void> _fetchAlly() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final ally = await AllyService.instance.fetchAlly();
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, ally: ally);
      AppLogger.info('Ally available: ${ally.id}', tag: 'AllyController');
    } on NotFoundException {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load your ally. Please try again.',
      );
      AppLogger.warning('Ally not found on server', tag: 'AllyController');
    } on UnauthorizedException {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Session expired. Please log in again.',
      );
    } on NetworkException {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'No internet connection.',
      );
    } on ApiTimeoutException {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Request timed out. Please try again.',
      );
    } on AppException catch (e) {
      AppLogger.error('Unexpected ally error', tag: 'AllyController', error: e);
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  /// Retry fetching the ally after a failure.
  Future<void> retry() async {
    await _fetchAlly();
  }

  /// Update the local ally's knowledgeBaseIds after a link/unlink.
  void updateKnowledgeBaseIds(List<String> kbIds) {
    final ally = state.ally;
    if (ally == null) return;
    state = state.copyWith(ally: ally.copyWith(knowledgeBaseIds: kbIds));
  }

  /// Save system prompt and attach it to the agent.
  ///
  /// Two-step flow: creates/updates a Prompt record, then attaches it
  /// to the ally agent via `promptId` — same pattern as knowledge bases.
  Future<void> updateSystemPrompt(String systemPrompt) async {
    final ally = state.ally;
    if (ally == null) return;

    state = state.copyWith(isSavingPresence: true, clearError: true);

    try {
      final promptId = await AllyService.instance.saveAndAttachPrompt(
        agentId: ally.id,
        agentName: ally.name,
        wallet: ally.wallet,
        systemPrompt: systemPrompt,
        existingPromptId: ally.promptId.isNotEmpty ? ally.promptId : null,
      );
      if (!ref.mounted) return;
      state = state.copyWith(
        isSavingPresence: false,
        ally: ally.copyWith(systemPrompt: systemPrompt, promptId: promptId),
      );
      AppLogger.info('System prompt saved and attached', tag: 'AllyController');
    } on UnauthorizedException {
      if (!ref.mounted) return;
      state = state.copyWith(
        isSavingPresence: false,
        error: 'Session expired. Please log in again.',
      );
    } on NetworkException {
      if (!ref.mounted) return;
      state = state.copyWith(
        isSavingPresence: false,
        error: 'No internet connection.',
      );
    } on AppException catch (e) {
      AppLogger.error(
        'Failed to save system prompt',
        tag: 'AllyController',
        error: e,
      );
      if (!ref.mounted) return;
      state = state.copyWith(
        isSavingPresence: false,
        error: 'Unable to save presence. Please try again.',
      );
    }
  }

  /// Link an existing prompt to the Ki agent by ID only.
  Future<void> updatePromptId(String promptId) async {
    final ally = state.ally;
    if (ally == null) return;

    try {
      await AllyService.instance.patchAgent(ally.id, {'promptId': promptId});
      if (!ref.mounted) return;
      state = state.copyWith(
        ally: ally.copyWith(promptId: promptId),
      );
      AppLogger.info(
        'Prompt $promptId linked to Ki',
        tag: 'AllyController',
      );
    } on AppException catch (e) {
      AppLogger.error('Failed to link prompt', tag: 'AllyController', error: e);
    }
  }
}

/// Global ally state provider.
final allyControllerProvider = NotifierProvider<AllyController, AllyState>(
  AllyController.new,
);

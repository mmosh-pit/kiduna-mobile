import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/knowledge_base_model.dart';
import '../../../data/services/knowledge_service.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import 'ally_controller.dart';

/// State for knowledge base management.
@immutable
class KnowledgeState {
  const KnowledgeState({
    this.isLoading = false,
    this.isUploading = false,
    this.isImportingDrive = false,
    this.error,
    this.knowledgeBases = const [],
    this.activeKb,
    this.driveImportTotal = 0,
    this.driveImportDone = 0,
    this.selectedPrivacy = KbPrivacy.private,
    this.kbDetailOpen = false,
    this.isCreateMode = false,
  });

  final bool isLoading;
  final bool isUploading;
  final bool isImportingDrive;
  final String? error;
  final List<KnowledgeBaseModel> knowledgeBases;
  final KnowledgeBaseModel? activeKb;
  final int driveImportTotal;
  final int driveImportDone;
  final KbPrivacy selectedPrivacy;
  final bool kbDetailOpen;
  final bool isCreateMode;

  KnowledgeState copyWith({
    bool? isLoading,
    bool? isUploading,
    bool? isImportingDrive,
    String? error,
    List<KnowledgeBaseModel>? knowledgeBases,
    KnowledgeBaseModel? activeKb,
    int? driveImportTotal,
    int? driveImportDone,
    KbPrivacy? selectedPrivacy,
    bool? kbDetailOpen,
    bool? isCreateMode,
    bool clearError = false,
    bool clearActiveKb = false,
  }) {
    return KnowledgeState(
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      isImportingDrive: isImportingDrive ?? this.isImportingDrive,
      error: clearError ? null : (error ?? this.error),
      knowledgeBases: knowledgeBases ?? this.knowledgeBases,
      activeKb: clearActiveKb ? null : (activeKb ?? this.activeKb),
      driveImportTotal: driveImportTotal ?? this.driveImportTotal,
      driveImportDone: driveImportDone ?? this.driveImportDone,
      selectedPrivacy: selectedPrivacy ?? this.selectedPrivacy,
      kbDetailOpen: kbDetailOpen ?? this.kbDetailOpen,
      isCreateMode: isCreateMode ?? this.isCreateMode,
    );
  }
}

/// Manages knowledge bases — CRUD, file uploads, Drive imports, and
/// agent linkage.
///
/// Reads the agent from [allyControllerProvider] and the user wallet
/// from [authControllerProvider].
/// Maximum file size in bytes (5 MB — matches Studio + backend).
const _kMaxFileSize = 5 * 1024 * 1024;

class KnowledgeController extends Notifier<KnowledgeState> {
  KnowledgeService get _service => KnowledgeService.instance;

  @override
  KnowledgeState build() {
    return const KnowledgeState();
  }

  String? get _agentId => ref.read(allyControllerProvider).ally?.id;

  String? get _allyName => ref.read(allyControllerProvider).ally?.name;

  String? get _wallet => ref.read(authControllerProvider).user?.wallet;

  List<String> get _currentKbIds =>
      ref.read(allyControllerProvider).ally?.knowledgeBaseIds ?? const [];

  /// Returns the active KB, auto-creating and linking one if none exists.
  ///
  /// Called by [uploadFiles] and [importFromGdrive] so the user never
  /// has to manually create a KB before adding content.
  Future<KnowledgeBaseModel?> _ensureActiveKb() async {
    if (state.activeKb != null) return state.activeKb;

    if (state.knowledgeBases.isNotEmpty) {
      await selectKnowledgeBase(state.knowledgeBases.first.id);
      return state.activeKb;
    }

    final existingIds = _currentKbIds;
    if (existingIds.isNotEmpty) {
      await selectKnowledgeBase(existingIds.first);
      return state.activeKb;
    }

    final wallet = _wallet;
    final agentId = _agentId;
    if (wallet == null || agentId == null) return null;

    final name = '${_allyName ?? "Ki"} Wisdom';

    final kb = await _service.createKnowledgeBase(
      name: name,
      wallet: wallet,
      privacy: state.selectedPrivacy.name,
    );
    if (!ref.mounted) return null;

    final updatedKbIds = [..._currentKbIds, kb.id];
    await _service.updateAgentKbIds(agentId, updatedKbIds);
    if (!ref.mounted) return null;

    ref
        .read(allyControllerProvider.notifier)
        .updateKnowledgeBaseIds(updatedKbIds);

    state = state.copyWith(
      knowledgeBases: [...state.knowledgeBases, kb],
      activeKb: kb,
      isCreateMode: false,
    );
    AppLogger.info(
      'Auto-created and linked KB ${kb.id} to agent $agentId',
      tag: 'KnowledgeCtrl',
    );
    return kb;
  }

  /// Load knowledge bases linked to the Ki (ally) agent.
  ///
  /// Reads `knowledgeBaseIds` from the ally and fetches each KB by ID.
  /// KBs belong to the agent, not the user's wallet.
  Future<void> loadKnowledgeBases() async {
    final kbIds = _currentKbIds;
    if (kbIds.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        knowledgeBases: const [],
        clearError: true,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final kbs = <KnowledgeBaseModel>[];
      for (final kbId in kbIds) {
        try {
          final kb = await _service.fetchKnowledgeBase(kbId);
          if (!ref.mounted) return;
          kbs.add(kb);
        } on NotFoundException {
          AppLogger.warning(
            'KB $kbId linked to agent but not found — skipping',
            tag: 'KnowledgeCtrl',
          );
        }
      }

      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, knowledgeBases: kbs);
      AppLogger.info(
        'Loaded ${kbs.length} knowledge bases for agent',
        tag: 'KnowledgeCtrl',
      );

      if (kbs.isNotEmpty && state.activeKb == null) {
        await selectKnowledgeBase(kbs.first.id);
      }
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
    } on AppException catch (e) {
      if (!ref.mounted) return;
      AppLogger.error('Load KBs failed', tag: 'KnowledgeCtrl', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  /// Create a new knowledge base and link it to the Ki agent.
  ///
  /// Order: create KB first, then update agent's knowledgeBaseIds.
  /// This is a POST — never retry on failure.
  Future<void> createAndLinkKb({
    required String name,
    KbPrivacy privacy = KbPrivacy.private,
  }) async {
    final wallet = _wallet;
    final agentId = _agentId;
    if (wallet == null || agentId == null) {
      state = state.copyWith(error: 'Not connected. Please try again.');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final kb = await _service.createKnowledgeBase(
        name: name,
        wallet: wallet,
        privacy: privacy.name,
      );
      if (!ref.mounted) return;

      final updatedKbIds = [..._currentKbIds, kb.id];
      await _service.updateAgentKbIds(agentId, updatedKbIds);
      if (!ref.mounted) return;

      ref
          .read(allyControllerProvider.notifier)
          .updateKnowledgeBaseIds(updatedKbIds);

      state = state.copyWith(
        isLoading: false,
        knowledgeBases: [...state.knowledgeBases, kb],
        activeKb: kb,
        isCreateMode: false,
      );
      AppLogger.info(
        'Created and linked KB ${kb.id} to agent $agentId',
        tag: 'KnowledgeCtrl',
      );
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
    } on AppException catch (e) {
      if (!ref.mounted) return;
      AppLogger.error('Create+link KB failed', tag: 'KnowledgeCtrl', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to create knowledge base. Please try again.',
      );
    }
  }

  /// Select a knowledge base and fetch its full detail (items + stats).
  Future<void> selectKnowledgeBase(String kbId) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final kb = await _service.fetchKnowledgeBase(kbId);
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        activeKb: kb,
        selectedPrivacy: KbPrivacy.fromString(kb.privacy),
      );
    } on NotFoundException {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Knowledge base not found.',
      );
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
    } on AppException catch (e) {
      if (!ref.mounted) return;
      AppLogger.error('Select KB failed', tag: 'KnowledgeCtrl', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  /// Open KB detail panel for an existing KB.
  void openKbDetail(String kbId) {
    state = state.copyWith(
      kbDetailOpen: true,
      isCreateMode: false,
    );
    selectKnowledgeBase(kbId);
  }

  /// Open KB detail panel in create mode (empty form).
  void openCreateKbForm() {
    state = state.copyWith(
      kbDetailOpen: true,
      isCreateMode: true,
      clearActiveKb: true,
    );
  }

  /// Close the KB detail panel.
  void closeKbDetail() {
    state = state.copyWith(
      kbDetailOpen: false,
      isCreateMode: false,
    );
  }

  /// Set the selected privacy for the next KB creation.
  void setPrivacy(KbPrivacy privacy) {
    state = state.copyWith(selectedPrivacy: privacy);
  }

  /// Change the privacy of the active knowledge base via PATCH.
  Future<void> updateKbPrivacy(KbPrivacy privacy) async {
    final activeKb = state.activeKb;
    if (activeKb == null) return;

    state = state.copyWith(clearError: true);

    try {
      await _service.updateKnowledgeBase(
        activeKb.id,
        privacy: privacy.name,
      );
      if (!ref.mounted) return;

      // Re-fetch full KB so items are preserved.
      await selectKnowledgeBase(activeKb.id);

      final refreshedKb = state.activeKb;
      if (refreshedKb != null) {
        final updatedList = state.knowledgeBases.map((kb) {
          return kb.id == activeKb.id ? refreshedKb : kb;
        }).toList();
        state = state.copyWith(
          knowledgeBases: updatedList,
          selectedPrivacy: KbPrivacy.fromString(refreshedKb.privacy),
        );
      }
    } on AppException catch (e) {
      if (!ref.mounted) return;
      AppLogger.error(
        'Update KB privacy failed',
        tag: 'KnowledgeCtrl',
        error: e,
      );
      state = state.copyWith(
        error: 'Unable to update visibility. Please try again.',
      );
    }
  }

  /// Update a knowledge base's metadata (name, privacy).
  Future<void> updateKnowledgeBase(
    String kbId, {
    String? name,
    String? privacy,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.updateKnowledgeBase(
        kbId,
        name: name,
        privacy: privacy,
      );
      if (!ref.mounted) return;

      // Re-fetch the full KB (with items + stats) so nothing is lost.
      await selectKnowledgeBase(kbId);

      // Also refresh the list-level entry (name/privacy may have changed).
      final refreshedKb = state.activeKb;
      if (refreshedKb != null) {
        final updatedList = state.knowledgeBases.map((kb) {
          return kb.id == kbId ? refreshedKb : kb;
        }).toList();
        state = state.copyWith(
          isLoading: false,
          knowledgeBases: updatedList,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } on AppException catch (e) {
      if (!ref.mounted) return;
      AppLogger.error('Update KB failed', tag: 'KnowledgeCtrl', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to update. Please try again.',
      );
    }
  }

  /// Unlink a knowledge base from the agent, then delete it.
  ///
  /// Order: unlink first (remove from agent's knowledgeBaseIds),
  /// then delete the KB. If unlink succeeds but delete fails,
  /// the KB is orphaned but no longer used by the agent.
  Future<void> unlinkAndDeleteKb(String kbId) async {
    final agentId = _agentId;
    if (agentId == null) {
      state = state.copyWith(error: 'Not connected. Please try again.');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final updatedKbIds = _currentKbIds.where((id) => id != kbId).toList();
      await _service.updateAgentKbIds(agentId, updatedKbIds);
      if (!ref.mounted) return;

      ref
          .read(allyControllerProvider.notifier)
          .updateKnowledgeBaseIds(updatedKbIds);

      await _service.deleteKnowledgeBase(kbId);
      if (!ref.mounted) return;

      final updatedList = state.knowledgeBases
          .where((kb) => kb.id != kbId)
          .toList();

      state = state.copyWith(
        isLoading: false,
        knowledgeBases: updatedList,
        clearActiveKb: state.activeKb?.id == kbId,
      );
      AppLogger.info(
        'Unlinked and deleted KB $kbId from agent $agentId',
        tag: 'KnowledgeCtrl',
      );
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
    } on ServerException catch (e) {
      if (!ref.mounted) return;
      AppLogger.error(
        'Unlink+delete KB failed (server)',
        tag: 'KnowledgeCtrl',
        error: e,
      );
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? 'Unable to delete. Please try again.',
      );
    } on AppException catch (e) {
      if (!ref.mounted) return;
      AppLogger.error(
        'Unlink+delete KB failed',
        tag: 'KnowledgeCtrl',
        error: e,
      );
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to delete. Please try again.',
      );
    }
  }

  /// Upload files to the active knowledge base.
  ///
  /// This is a POST — never retry on failure. After upload, the
  /// active KB is refreshed to show new items.
  Future<void> uploadFiles(List<({String name, List<int> bytes})> files) async {
    state = state.copyWith(isUploading: true, clearError: true);

    // ── Size check — reject files over 5 MB ──
    final oversized = files
        .where((f) => f.bytes.length > _kMaxFileSize)
        .map((f) => f.name)
        .toList();
    if (oversized.isNotEmpty) {
      state = state.copyWith(
        isUploading: false,
        error: '${oversized.join(", ")} exceeds the 5 MB size limit.',
      );
      return;
    }

    // ── Duplicate check — skip files already in the KB ──
    final existingNames = state.activeKb?.items
            .map((i) => i.name.toLowerCase())
            .toSet() ??
        <String>{};
    final duplicates = files
        .where((f) => existingNames.contains(f.name.toLowerCase()))
        .map((f) => f.name)
        .toList();
    if (duplicates.isNotEmpty) {
      state = state.copyWith(
        isUploading: false,
        error: '${duplicates.join(", ")} already exists in this knowledge base.',
      );
      return;
    }

    // ── Filter to valid files only ──
    final validFiles = files
        .where((f) => f.bytes.length <= _kMaxFileSize)
        .toList();
    if (validFiles.isEmpty) {
      state = state.copyWith(isUploading: false);
      return;
    }

    try {
      final kb = await _ensureActiveKb();
      if (!ref.mounted) return;
      if (kb == null) {
        state = state.copyWith(
          isUploading: false,
          error: 'Not connected. Please try again.',
        );
        return;
      }

      await _service.uploadFiles(kb.id, validFiles);
      if (!ref.mounted) return;

      state = state.copyWith(isUploading: false);
      AppLogger.info(
        'Uploaded ${validFiles.length} files to KB ${kb.id}',
        tag: 'KnowledgeCtrl',
      );

      await selectKnowledgeBase(kb.id);
    } on ValidationException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isUploading: false, error: e.message);
    } on NetworkException {
      if (!ref.mounted) return;
      state = state.copyWith(
        isUploading: false,
        error: 'No internet connection.',
      );
    } on AppException catch (e) {
      if (!ref.mounted) return;
      AppLogger.error('Upload files failed', tag: 'KnowledgeCtrl', error: e);
      state = state.copyWith(
        isUploading: false,
        error: e.message != null && e.message!.isNotEmpty
            ? e.message!
            : 'Upload failed. Please try again.',
      );
    }
  }

  /// Delete a single item from the active knowledge base.
  Future<void> deleteItem(String itemId) async {
    final activeKb = state.activeKb;
    if (activeKb == null) return;

    state = state.copyWith(clearError: true);

    try {
      await _service.deleteItem(activeKb.id, itemId);
      if (!ref.mounted) return;

      final updatedItems = activeKb.items
          .where((item) => item.id != itemId)
          .toList();
      final updatedKb = activeKb.copyWith(items: updatedItems);
      final updatedList = state.knowledgeBases.map((kb) {
        return kb.id == activeKb.id ? updatedKb : kb;
      }).toList();

      state = state.copyWith(activeKb: updatedKb, knowledgeBases: updatedList);
    } on AppException catch (e) {
      if (!ref.mounted) return;
      AppLogger.error('Delete item failed', tag: 'KnowledgeCtrl', error: e);
      state = state.copyWith(error: 'Unable to delete item. Please try again.');
    }
  }

  /// Trigger ingestion of all pending items in the active KB.
  ///
  /// This is a POST — never retry on failure.
  Future<void> ingestPending() async {
    final activeKb = state.activeKb;
    if (activeKb == null) return;

    state = state.copyWith(clearError: true);

    try {
      await _service.ingestPending(activeKb.id);
      if (!ref.mounted) return;

      // Refresh the active KB to get updated ingest statuses.
      await selectKnowledgeBase(activeKb.id);
    } on AppException catch (e) {
      if (!ref.mounted) return;
      AppLogger.error('Ingest pending failed', tag: 'KnowledgeCtrl', error: e);
      state = state.copyWith(error: 'Ingestion failed. Please try again.');
    }
  }

  /// Import files from Google Drive sequentially (one at a time).
  ///
  /// Follows the kinship-shared pattern: each file is sent to the
  /// backend proxy which downloads it server-side and feeds it into
  /// the upload pipeline. This is a POST — never retry on failure.
  /// Import a single file or folder from Google Drive via backend proxy.
  ///
  /// When [isFolder] is true, the backend lists folder contents and
  /// imports each file. The wallet is passed so the backend can look up
  /// the stored Google OAuth token internally.
  Future<void> importFromGdriveSingle({
    required String fileId,
    required String fileName,
    required String wallet,
    bool isFolder = false,
  }) async {
    state = state.copyWith(
      isImportingDrive: true,
      clearError: true,
      driveImportTotal: 1,
      driveImportDone: 0,
    );

    try {
      final kb = await _ensureActiveKb();
      if (!ref.mounted) return;
      if (kb == null) {
        state = state.copyWith(
          isImportingDrive: false,
          error: 'Not connected. Please try again.',
        );
        return;
      }

      await _service.importFromGdrive(
        kb.id,
        fileId: fileId,
        fileName: fileName,
        wallet: wallet,
        isFolder: isFolder,
      );

      if (!ref.mounted) return;

      state = state.copyWith(
        isImportingDrive: false,
        driveImportDone: 1,
      );

      AppLogger.info(
        'Drive ${isFolder ? 'folder' : 'file'} imported to KB ${kb.id}',
        tag: 'KnowledgeCtrl',
      );

      await selectKnowledgeBase(kb.id);
    } on AppException catch (e) {
      if (!ref.mounted) return;
      AppLogger.error(
        'Drive import failed for "$fileName"',
        tag: 'KnowledgeCtrl',
        error: e,
      );
      state = state.copyWith(
        isImportingDrive: false,
        error: e.message != null && e.message!.isNotEmpty
            ? e.message!
            : 'Import failed. Please try again.',
      );
    }
  }

  /// Import multiple files from Google Drive via backend proxy (bulk).
  Future<void> importFromGdrive({
    required List<({String fileId, String fileName, String? mimeType})> files,
    required String accessToken,
  }) async {
    state = state.copyWith(
      isImportingDrive: true,
      clearError: true,
      driveImportTotal: files.length,
      driveImportDone: 0,
    );

    try {
      final kb = await _ensureActiveKb();
      if (!ref.mounted) return;
      if (kb == null) {
        state = state.copyWith(
          isImportingDrive: false,
          error: 'Not connected. Please try again.',
        );
        return;
      }

      var importedCount = 0;

      for (final file in files) {
        try {
          await _service.importFromGdrive(
            kb.id,
            fileId: file.fileId,
            fileName: file.fileName,
            wallet: accessToken,
            mimeType: file.mimeType,
          );
          if (!ref.mounted) return;

          importedCount++;
          state = state.copyWith(driveImportDone: importedCount);
        } on AppException catch (e) {
          if (!ref.mounted) return;
          AppLogger.error(
            'Drive import failed for "${file.fileName}"',
            tag: 'KnowledgeCtrl',
            error: e,
          );
          state = state.copyWith(
            isImportingDrive: false,
            error:
                'Import failed for "${file.fileName}". '
                '$importedCount of ${files.length} imported.',
            driveImportDone: importedCount,
          );
          return;
        }
      }

      if (!ref.mounted) return;

      state = state.copyWith(
        isImportingDrive: false,
        driveImportDone: importedCount,
      );

      AppLogger.info(
        'Imported $importedCount Drive files to KB ${kb.id}',
        tag: 'KnowledgeCtrl',
      );

      await selectKnowledgeBase(kb.id);
    } on UnauthorizedException {
      if (!ref.mounted) return;
      state = state.copyWith(
        isImportingDrive: false,
        error: 'Session expired. Please log in again.',
      );
    } on NetworkException {
      if (!ref.mounted) return;
      state = state.copyWith(
        isImportingDrive: false,
        error: 'No internet connection.',
      );
    } on AppException catch (e) {
      if (!ref.mounted) return;
      AppLogger.error(
        'Drive import setup failed',
        tag: 'KnowledgeCtrl',
        error: e,
      );
      state = state.copyWith(
        isImportingDrive: false,
        error: 'Unable to prepare import. Please try again.',
      );
    }
  }

  /// Ingest raw text content into the active knowledge base.
  ///
  /// This is a POST — never retry on failure.
  Future<void> ingestText({
    required String title,
    required String content,
    String? sourceUrl,
  }) async {
    state = state.copyWith(isUploading: true, clearError: true);

    try {
      final kb = await _ensureActiveKb();
      if (!ref.mounted) return;
      if (kb == null) {
        state = state.copyWith(
          isUploading: false,
          error: 'Not connected. Please try again.',
        );
        return;
      }

      await _service.ingestText(
        kb.id,
        title: title,
        content: content,
        sourceUrl: sourceUrl,
      );
      if (!ref.mounted) return;

      state = state.copyWith(isUploading: false);
      AppLogger.info(
        'Ingested text "$title" into KB ${kb.id}',
        tag: 'KnowledgeCtrl',
      );

      await selectKnowledgeBase(kb.id);
    } on AppException catch (e) {
      if (!ref.mounted) return;
      AppLogger.error('Ingest text failed', tag: 'KnowledgeCtrl', error: e);
      state = state.copyWith(
        isUploading: false,
        error: 'Unable to add text. Please try again.',
      );
    }
  }
}

/// Global knowledge base state provider.
final knowledgeControllerProvider =
    NotifierProvider<KnowledgeController, KnowledgeState>(
      KnowledgeController.new,
    );

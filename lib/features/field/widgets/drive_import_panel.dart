import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/services/gdrive_service.dart';
import '../../../l10n/app_localizations.dart';
import '../controllers/knowledge_controller.dart';
import 'capacity_header.dart';

/// Google Drive import section — sign in, paste a folder/file URL, import.
///
/// Follows the kinship-shared pattern:
/// 1. Authenticate with Google (drive.readonly scope)
/// 2. User pastes a Drive folder or file URL
/// 3. Files are imported one-by-one through the backend proxy
class DriveImportPanel extends ConsumerStatefulWidget {
  const DriveImportPanel({super.key});

  @override
  ConsumerState<DriveImportPanel> createState() => _DriveImportPanelState();
}

class _DriveImportPanelState extends ConsumerState<DriveImportPanel> {
  final TextEditingController _urlCtrl = TextEditingController();
  bool _isSignedIn = false;
  bool _isSigningIn = false;
  bool _isResolving = false;
  String? _error;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _trySilentSignIn();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _trySilentSignIn() async {
    final token = await GdriveService.instance.signInSilently();
    if (!mounted) return;
    if (token != null) {
      setState(() {
        _isSignedIn = true;
        _userEmail = GdriveService.instance.userEmail;
      });
    }
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isSigningIn = true;
      _error = null;
    });

    final token = await GdriveService.instance.signIn();
    if (!mounted) return;

    if (token != null) {
      setState(() {
        _isSignedIn = true;
        _isSigningIn = false;
        _userEmail = GdriveService.instance.userEmail;
      });
    } else {
      setState(() {
        _isSigningIn = false;
        _error = context.l10n.driveSignInFailed;
      });
    }
  }

  Future<void> _handleDisconnect() async {
    await GdriveService.instance.signOut();
    if (!mounted) return;
    setState(() {
      _isSignedIn = false;
      _userEmail = null;
    });
  }

  Future<void> _handleImport() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;

    final l10n = context.l10n;
    final urlType = GdriveService.classifyUrl(url);

    if (urlType == DriveUrlType.unknown) {
      setState(() => _error = l10n.driveInvalidUrl);
      return;
    }

    final accessToken = await GdriveService.instance.getAccessToken();
    if (!mounted) return;

    if (accessToken == null) {
      setState(() => _error = l10n.driveSignInRequired);
      return;
    }

    setState(() {
      _isResolving = true;
      _error = null;
    });

    try {
      if (urlType == DriveUrlType.folder) {
        await _importFolder(url, accessToken, l10n);
      } else {
        await _importSingleFile(url, accessToken, l10n);
      }
    } finally {
      if (mounted) {
        setState(() => _isResolving = false);
      }
    }
  }

  Future<void> _importFolder(
    String url,
    String accessToken,
    AppLocalizations l10n,
  ) async {
    final folderId = GdriveService.extractFolderId(url);
    if (folderId == null) {
      setState(() => _error = l10n.driveInvalidUrl);
      return;
    }

    final files = await GdriveService.instance.listFolderFiles(
      folderId: folderId,
      accessToken: accessToken,
    );
    if (!mounted) return;

    if (files.isEmpty) {
      setState(() => _error = l10n.driveNoSupportedFiles);
      return;
    }

    final validFiles = <DriveFile>[];
    final oversized = <String>[];

    for (final f in files) {
      if (!f.isIngestible) continue;
      if (f.isOversized) {
        oversized.add(f.name);
        continue;
      }
      validFiles.add(f);
    }

    if (oversized.isNotEmpty) {
      setState(() => _error = l10n.driveFilesTooLarge(oversized.length));
    }

    if (validFiles.isEmpty) {
      if (oversized.isEmpty) {
        setState(() => _error = l10n.driveNoSupportedFiles);
      }
      return;
    }

    _urlCtrl.clear();
    unawaited(
      ref
          .read(knowledgeControllerProvider.notifier)
          .importFromGdrive(
            files: validFiles
                .map(
                  (f) => (
                    fileId: f.id,
                    fileName: f.name,
                    mimeType: f.mimeType as String?,
                  ),
                )
                .toList(),
            accessToken: accessToken,
          ),
    );
  }

  Future<void> _importSingleFile(
    String url,
    String accessToken,
    AppLocalizations l10n,
  ) async {
    final fileId = GdriveService.extractFileId(url);
    if (fileId == null) {
      setState(() => _error = l10n.driveInvalidUrl);
      return;
    }

    final file = await GdriveService.instance.getFileMetadata(
      fileId: fileId,
      accessToken: accessToken,
    );
    if (!mounted) return;

    if (file == null) {
      setState(() => _error = l10n.driveFileNotFound);
      return;
    }

    if (!file.isIngestible) {
      setState(() => _error = l10n.driveUnsupportedType);
      return;
    }

    if (file.isOversized) {
      setState(() => _error = l10n.driveFileTooLarge);
      return;
    }

    _urlCtrl.clear();
    unawaited(
      ref
          .read(knowledgeControllerProvider.notifier)
          .importFromGdrive(
            files: [
              (
                fileId: file.id,
                fileName: file.name,
                mimeType: file.mimeType as String?,
              ),
            ],
            accessToken: accessToken,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.kiduna;
    final text = context.kidunaText;
    final kbState = ref.watch(knowledgeControllerProvider);
    final isImporting = kbState.isImportingDrive;
    final isDisabled = isImporting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DriveSectionHeader(
          isSignedIn: _isSignedIn,
          userEmail: _userEmail,
          onDisconnect: _handleDisconnect,
        ),
        const SizedBox(height: 7),

        if (!_isSignedIn)
          _ConnectDriveButton(
            isLoading: _isSigningIn,
            onPressed: _isSigningIn ? null : _handleSignIn,
          ),

        if (_isSignedIn) ...[
          _DriveUrlInput(
            controller: _urlCtrl,
            isLoading: _isResolving || isImporting,
            isDisabled: isDisabled,
            onSubmit: _handleImport,
          ),
          const SizedBox(height: 7),
        ],

        if (isImporting) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              l10n.driveImportProgress(
                kbState.driveImportDone,
                kbState.driveImportTotal,
              ),
              style: text.micro.copyWith(color: colors.sky),
            ),
          ),
        ],

        if (_error != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _error!,
              style: text.micro.copyWith(color: colors.camel),
            ),
          ),
        ],
      ],
    );
  }
}

class _DriveSectionHeader extends StatelessWidget {
  const _DriveSectionHeader({
    required this.isSignedIn,
    required this.userEmail,
    required this.onDisconnect,
  });

  final bool isSignedIn;
  final String? userEmail;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.googleDrive,
            style: text.label.copyWith(
              color: colors.cream,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (isSignedIn && userEmail != null) ...[
          Text(userEmail!, style: text.micro.copyWith(color: colors.quiet)),
          const SizedBox(width: 6),
          CapacityActionButton(label: l10n.disconnect, onPressed: onDisconnect),
        ],
      ],
    );
  }
}

class _ConnectDriveButton extends StatelessWidget {
  const _ConnectDriveButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = context.l10n;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.sky.withValues(alpha: 0.025),
          border: Border.all(color: colors.sky.withValues(alpha: 0.18)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: colors.sky,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              isLoading ? l10n.driveConnecting : l10n.connectGoogleDrive,
              style: text.caption.copyWith(
                color: colors.cream,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriveUrlInput extends StatelessWidget {
  const _DriveUrlInput({
    required this.controller,
    required this.isLoading,
    required this.isDisabled,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: !isDisabled,
            style: text.caption.copyWith(color: colors.text),
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color.fromRGBO(6, 3, 4, 0.66),
              hintText: l10n.drivePasteLinkHint,
              hintStyle: text.caption.copyWith(color: colors.quiet),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 7,
              ),
              constraints: const BoxConstraints(minHeight: 35),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(
                  color: colors.camel.withValues(alpha: 0.24),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(
                  color: colors.camel.withValues(alpha: 0.24),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        CapacityActionButton(
          label: isLoading ? l10n.importingFromDrive : l10n.driveImportAction,
          onPressed: isDisabled || isLoading ? null : onSubmit,
        ),
      ],
    );
  }
}

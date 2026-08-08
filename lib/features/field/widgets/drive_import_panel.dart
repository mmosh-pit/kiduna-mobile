import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/services/gdrive_picker_service.dart';
import '../../../data/services/gdrive_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/knowledge_controller.dart';

/// Google Drive import section.
///
/// Two modes:
///   1. **Picker** (primary) — Google account select → Drive file browser
///   2. **URL paste** (fallback) — paste file/folder link
class DriveImportPanel extends ConsumerStatefulWidget {
  const DriveImportPanel({super.key});

  @override
  ConsumerState<DriveImportPanel> createState() => _DriveImportPanelState();
}

class _DriveImportPanelState extends ConsumerState<DriveImportPanel> {
  final TextEditingController _urlCtrl = TextEditingController();
  bool _isPickerLoading = false;
  bool _isUrlImporting = false;
  bool _showUrlFallback = false;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  /// Primary flow — Google Picker (account select → browse → select files).
  Future<void> _handlePickerFlow() async {
    setState(() {
      _isPickerLoading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final files = await GdrivePickerService.instance.signInAndPick();
      if (!mounted) return;

      if (files.isEmpty) {
        setState(() => _isPickerLoading = false);
        return;
      }

      final ctrl = ref.read(knowledgeControllerProvider.notifier);
      final wallet = ref.read(authControllerProvider).user?.wallet ?? '';
      var imported = 0;

      for (final file in files) {
        try {
          if (file.isFolder) {
            await ctrl.importFromGdriveSingle(
              fileId: file.id,
              fileName: file.name,
              wallet: wallet,
              isFolder: true,
            );
          } else {
            await ctrl.importFromGdriveSingle(
              fileId: file.id,
              fileName: file.name,
              wallet: wallet,
            );
          }
          imported++;
        } catch (e) {
          AppLogger.warning(
            'Failed to import ${file.name}: $e',
            tag: 'DriveImportPanel',
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _isPickerLoading = false;
        _successMessage = 'Imported $imported of ${files.length} files';
      });
    } catch (e) {
      if (!mounted) return;
      AppLogger.warning(
        'Picker flow failed: $e',
        tag: 'DriveImportPanel',
      );
      setState(() {
        _isPickerLoading = false;
        _error = 'Google Drive access failed. Try pasting a URL instead.';
        _showUrlFallback = true;
      });
    }
  }

  /// Fallback flow — paste Drive URL.
  Future<void> _handleUrlImport() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Paste a Drive file or folder URL first.');
      return;
    }

    final urlType = GdriveService.classifyUrl(url);
    if (urlType == DriveUrlType.unknown) {
      setState(() => _error = 'Invalid Google Drive URL.');
      return;
    }

    final fileId = urlType == DriveUrlType.folder
        ? GdriveService.extractFolderId(url)
        : GdriveService.extractFileId(url);
    if (fileId == null) {
      setState(() => _error = 'Could not extract ID from URL.');
      return;
    }

    setState(() {
      _isUrlImporting = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final ctrl = ref.read(knowledgeControllerProvider.notifier);
      final wallet = ref.read(authControllerProvider).user?.wallet ?? '';

      await ctrl.importFromGdriveSingle(
        fileId: fileId,
        fileName: urlType == DriveUrlType.folder ? 'Drive folder' : 'Drive file',
        wallet: wallet,
        isFolder: urlType == DriveUrlType.folder,
      );

      if (!mounted) return;
      setState(() {
        _isUrlImporting = false;
        _successMessage = 'Import complete';
        _urlCtrl.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUrlImporting = false;
        _error = 'Import failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Text(
          'Google Drive',
          style: text.label.copyWith(
            color: colors.cream,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),

        // Show "Use different account" when already signed in
        if (GdrivePickerService.instance.hasToken) ...[
          GestureDetector(
            onTap: () {
              GdrivePickerService.instance.clearToken();
              _handlePickerFlow();
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Text(
                'Use different account',
                style: text.micro.copyWith(
                  color: colors.sky,
                  decoration: TextDecoration.underline,
                  decorationColor: colors.sky,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],

        // Primary: Browse Google Drive button
        GestureDetector(
          onTap: _isPickerLoading ? null : _handlePickerFlow,
          child: MouseRegion(
            cursor: _isPickerLoading
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _isPickerLoading
                    ? colors.sky.withValues(alpha: 0.5)
                    : colors.sky.withValues(alpha: 0.08),
                border: Border.all(color: colors.sky.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isPickerLoading)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.sky,
                        ),
                      ),
                    ),
                  Text(
                    _isPickerLoading ? 'Opening Drive…' : 'Browse Google Drive',
                    style: text.label.copyWith(
                      color: colors.sky,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // URL fallback toggle
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => _showUrlFallback = !_showUrlFallback),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Text(
              _showUrlFallback ? 'Hide URL input' : 'Or paste a Drive URL',
              style: text.micro.copyWith(
                color: colors.quiet,
                decoration: TextDecoration.underline,
                decorationColor: colors.quiet,
              ),
            ),
          ),
        ),

        // URL fallback section
        if (_showUrlFallback) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _urlCtrl,
            style: text.caption.copyWith(color: colors.text, height: 1.4),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color.fromRGBO(6, 3, 4, 0.66),
              hintText: 'https://drive.google.com/drive/folders/...',
              hintStyle: text.caption.copyWith(color: colors.quiet),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 9,
              ),
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
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: colors.sky),
              ),
            ),
            onSubmitted: (_) => _handleUrlImport(),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _isUrlImporting ? null : _handleUrlImport,
            child: MouseRegion(
              cursor: _isUrlImporting
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.click,
              child: Container(
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.sky,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Import from URL',
                  style: text.label.copyWith(
                    color: colors.skyButtonInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],

        // Error
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(_error!, style: text.micro.copyWith(color: colors.gold)),
        ],

        // Success (hide if KB-level error is showing)
        if (_successMessage != null &&
            ref.read(knowledgeControllerProvider).error == null) ...[
          const SizedBox(height: 6),
          Text(
            _successMessage!,
            style: text.micro.copyWith(color: const Color(0xFF34D399)),
          ),
        ],
      ],
    );
  }
}
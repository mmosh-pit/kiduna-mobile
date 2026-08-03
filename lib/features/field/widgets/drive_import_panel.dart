import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/services/gdrive_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/field_controller.dart';
import '../controllers/knowledge_controller.dart';

/// Google Drive import section — simplified backend-proxy approach.
///
/// No access_token in Flutter. Backend handles all Drive API calls
/// internally using stored OAuth tokens from Empower with Connections.
///
/// Flow: check savedTools for google → show status → URL input → Import
/// → backend downloads files → done.
class DriveImportPanel extends ConsumerStatefulWidget {
  const DriveImportPanel({super.key});

  @override
  ConsumerState<DriveImportPanel> createState() => _DriveImportPanelState();
}

class _DriveImportPanelState extends ConsumerState<DriveImportPanel> {
  final TextEditingController _urlCtrl = TextEditingController();
  bool _isImporting = false;
  String? _error;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    // Ensure savedTools is loaded — needed to check Google connection.
    Future.microtask(
      ref.read(fieldControllerProvider.notifier).fetchSavedTools,
    );
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  /// Check if Google is connected via Empower with Connections.
  /// Reads from savedTools in FieldController state — no API call needed.
  _GoogleStatus _getGoogleStatus() {
    final savedTools = ref.watch(fieldControllerProvider).savedTools;
    final googleTools = savedTools.where(
      (t) => t.toolName == 'google' && t.isActive,
    );
    if (googleTools.isEmpty) {
      return const _GoogleStatus(connected: false);
    }
    return _GoogleStatus(
      connected: true,
      email: googleTools.first.externalHandle,
    );
  }

  Future<void> _handleImport() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;

    final urlType = GdriveService.classifyUrl(url);
    if (urlType == DriveUrlType.unknown) {
      setState(() => _error = 'Invalid Google Drive URL. Paste a file or folder link.');
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
      _isImporting = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final ctrl = ref.read(knowledgeControllerProvider.notifier);
      final wallet = ref.read(authControllerProvider).user?.wallet ?? '';
      final fileName = urlType == DriveUrlType.folder
          ? 'Drive folder'
          : 'Drive file';

      await ctrl.importFromGdriveSingle(
        fileId: fileId,
        fileName: fileName,
        wallet: wallet,
        isFolder: urlType == DriveUrlType.folder,
      );

      if (!mounted) return;
      setState(() {
        _isImporting = false;
        _successMessage = 'Import complete';
        _urlCtrl.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isImporting = false;
        _error = 'Import failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final status = _getGoogleStatus();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          children: [
            Text(
              'Google Drive',
              style: text.label.copyWith(
                color: colors.cream,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (status.connected) ...[
              const SizedBox(width: 8),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 7),

        if (!status.connected) ...[
          // Not connected — show Connect button.
          _ConnectButton(
            onPressed: () => ref
                .read(fieldControllerProvider.notifier)
                .connectGoogleOAuth(),
          ),
          const SizedBox(height: 4),
          Text(
            'Connect Google in Empower with Connections to import from Drive.',
            style: text.micro.copyWith(color: colors.quiet),
          ),
        ],

        if (status.connected) ...[
          // Connected — show email + Switch + Disconnect.
          Row(
            children: [
              Expanded(
                child: Text(
                  'Connected as ${status.email ?? 'Google account'}',
                  style: text.micro.copyWith(color: const Color(0xFF34D399)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => ref
                    .read(fieldControllerProvider.notifier)
                    .connectGoogleOAuth(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    'Switch',
                    style: text.micro.copyWith(
                      color: colors.sky,
                      decoration: TextDecoration.underline,
                      decorationColor: colors.sky,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  final tool = ref
                      .read(fieldControllerProvider)
                      .savedTools
                      .where((t) => t.toolName == 'google' && t.isActive)
                      .firstOrNull;
                  if (tool != null) {
                    ref
                        .read(fieldControllerProvider.notifier)
                        .disconnectTool(tool.id);
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    'Disconnect',
                    style: text.micro.copyWith(
                      color: const Color(0xFFE25C5C),
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFFE25C5C),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // URL input.
          TextField(
            controller: _urlCtrl,
            style: text.caption.copyWith(color: colors.text, height: 1.4),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color.fromRGBO(6, 3, 4, 0.66),
              hintText: 'Paste a Drive file or folder URL',
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
            onSubmitted: (_) => _handleImport(),
          ),
          const SizedBox(height: 8),

          // Import button.
          GestureDetector(
            onTap: _isImporting ? null : _handleImport,
            child: MouseRegion(
              cursor: _isImporting
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.click,
              child: Container(
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isImporting
                      ? colors.sky.withValues(alpha: 0.5)
                      : colors.sky,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _isImporting ? 'Importing…' : 'Import from Drive',
                  style: text.label.copyWith(
                    color: colors.skyButtonInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

          // Error.
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: text.micro.copyWith(color: colors.gold),
            ),
          ],

          // Success.
          if (_successMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              _successMessage!,
              style: text.micro.copyWith(color: const Color(0xFF34D399)),
            ),
          ],
        ],
      ],
    );
  }
}

class _GoogleStatus {
  const _GoogleStatus({required this.connected, this.email});

  final bool connected;
  final String? email;
}

class _ConnectButton extends StatelessWidget {
  const _ConnectButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return GestureDetector(
      onTap: onPressed,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.sky.withValues(alpha: 0.08),
            border: Border.all(color: colors.sky.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Connect Google Drive',
            style: text.label.copyWith(
              color: colors.sky,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
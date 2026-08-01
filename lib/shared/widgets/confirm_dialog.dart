import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';

/// Shows a confirmation dialog styled with Kiduna design tokens.
///
/// Returns `true` if confirmed, `false` or `null` if cancelled.
///
/// ```dart
/// final confirmed = await ConfirmDialog.show(
///   context: context,
///   title: 'Remove Skill',
///   message: 'This will permanently delete "Email responder". Continue?',
///   confirmLabel: 'Remove',
///   isDestructive: true,
/// );
/// if (confirmed == true) { ... }
/// ```
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  /// Show the dialog and return the result.
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: const Color(0x99000000),
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    final confirmColor = isDestructive
        ? const Color(0xFFE25C5C)
        : colors.sky;
    final confirmTextColor = isDestructive
        ? const Color(0xFFFFF5F5)
        : colors.skyButtonInk;

    return Dialog(
      backgroundColor: const Color(0xFF101111),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.camel.withValues(alpha: 0.18)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: text.label.copyWith(
                  color: colors.cream,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: text.caption.copyWith(
                  color: colors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colors.camel.withValues(alpha: 0.2),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          cancelLabel,
                          style: text.caption.copyWith(color: colors.quiet),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Confirm
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(true),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: confirmColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          confirmLabel,
                          style: text.caption.copyWith(
                            color: confirmTextColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
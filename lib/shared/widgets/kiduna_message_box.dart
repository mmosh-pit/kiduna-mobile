import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';

enum MessageType { error, success }

class KidunaMessageBox extends StatelessWidget {
  const KidunaMessageBox({
    super.key,
    required this.message,
    required this.type,
  });

  final String message;
  final MessageType type;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final isError = type == MessageType.error;

    final bgColor = isError
        ? colors.error.withValues(alpha: 0.1)
        : colors.mint.withValues(alpha: 0.1);
    final borderColor = isError
        ? colors.error.withValues(alpha: 0.25)
        : colors.mint.withValues(alpha: 0.25);
    final textColor = isError ? colors.error : colors.mint;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          message,
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 12,
            height: 1.5,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

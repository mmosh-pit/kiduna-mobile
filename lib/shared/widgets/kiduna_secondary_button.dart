import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';

class KidunaSecondaryButton extends StatelessWidget {
  const KidunaSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.sky,
          side: BorderSide(color: colors.sky.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(
            fontFamily: 'Avenir',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

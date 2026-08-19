import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';

class KidunaGoldButton extends StatefulWidget {
  const KidunaGoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<KidunaGoldButton> createState() => _KidunaGoldButtonState();
}

class _KidunaGoldButtonState extends State<KidunaGoldButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final isActive = !widget.isLoading && widget.onPressed != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(
          0,
          _hovering && isActive ? -1 : 0,
          0,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: isActive ? widget.onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.gold,
              foregroundColor: const Color(0xFF1A1005),
              disabledBackgroundColor: colors.gold.withValues(alpha: 0.5),
              disabledForegroundColor: const Color(0xFF1A1005)
                  .withValues(alpha: 0.5),
              elevation: 0,
              shadowColor: colors.gold.withValues(alpha: 0.16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Avenir',
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1A1005),
                    ),
                  )
                : Text(widget.label),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';

class KidunaPrimaryButton extends StatefulWidget {
  const KidunaPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;

  @override
  State<KidunaPrimaryButton> createState() => _KidunaPrimaryButtonState();
}

class _KidunaPrimaryButtonState extends State<KidunaPrimaryButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final isActive = widget.enabled && !widget.isLoading;

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
          height: 52,
          child: ElevatedButton(
            onPressed: isActive ? widget.onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _hovering && isActive
                  ? colors.skyHover
                  : colors.sky,
              foregroundColor: colors.skyButtonInk,
              disabledBackgroundColor: colors.sky.withValues(alpha: 0.5),
              disabledForegroundColor: colors.skyButtonInk.withValues(
                alpha: 0.5,
              ),
              elevation: 0,
              shadowColor: colors.sky.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Avenir',
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.skyButtonInk,
                    ),
                  )
                : Text(widget.label),
          ),
        ),
      ),
    );
  }
}

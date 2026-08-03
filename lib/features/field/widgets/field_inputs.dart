import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// CSS `.fieldTitle` — label text + 24px circular "→" ask-Ki button.
class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.text, this.onAskKi});

  final String text;
  final VoidCallback? onAskKi;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 26),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: context.kidunaText.label.copyWith(color: colors.cream),
            ),
          ),
          const SizedBox(width: 8),
          _AskKiButton(onPressed: onAskKi),
        ],
      ),
    );
  }
}

class _AskKiButton extends StatelessWidget {
  const _AskKiButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.sky.withValues(alpha: 0.055),
          border: Border.all(color: colors.sky.withValues(alpha: 0.28)),
        ),
        child: Text(
          '→',
          style: context.kidunaText.micro.copyWith(
            color: colors.sky,
            height: 1,
          ),
        ),
      ),
    );
  }
}

InputDecoration _decoration(
  BuildContext context,
  String? hint, {
  bool isMultiLine = false,
  double? minHeight,
}) {
  final colors = context.kiduna;
  final inputStyle = context.kidunaText.caption.copyWith(height: 1.4);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(context.metrics.radiusMd),
    borderSide: BorderSide(color: colors.camel.withValues(alpha: 0.24)),
  );
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: const Color.fromRGBO(6, 3, 4, 0.66),
    hintText: hint,
    hintStyle: inputStyle.copyWith(color: colors.quiet),
    contentPadding: isMultiLine
        ? const EdgeInsets.fromLTRB(10, 9, 10, 9)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
    constraints: BoxConstraints(
      minHeight: minHeight ?? (isMultiLine ? 70 : 37),
      maxHeight: isMultiLine ? double.infinity : 37,
    ),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(borderSide: BorderSide(color: colors.sky)),
  );
}

/// A labelled text (or multi-line) input.
class FieldTextInput extends StatelessWidget {
  const FieldTextInput({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.minHeight,
    this.onAskKi,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final double? minHeight;
  final VoidCallback? onAskKi;

  @override
  Widget build(BuildContext context) {
    final isMultiLine = maxLines > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(text: label, onAskKi: onAskKi),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: context.kidunaText.caption.copyWith(
            color: context.kiduna.text,
            height: 1.4,
          ),
          decoration: _decoration(
            context,
            hint,
            isMultiLine: isMultiLine,
            minHeight: minHeight,
          ),
        ),
      ],
    );
  }
}

/// A labelled dropdown of string [options].
class FieldDropdown extends StatelessWidget {
  const FieldDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.onAskKi,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final VoidCallback? onAskKi;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(text: label, onAskKi: onAskKi),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          dropdownColor: context.kiduna.raised,
          style: context.kidunaText.caption.copyWith(
            color: context.kiduna.text,
            height: 1.4,
          ),
          decoration: _decoration(context, null),
          items: [
            for (final option in options)
              DropdownMenuItem<String>(value: option, child: Text(option)),
          ],
          onChanged: (next) {
            if (next != null) {
              onChanged(next);
            }
          },
        ),
      ],
    );
  }
}

/// The primary sky Action button — dark local-ground ink on a sky fill, never
/// white or cream (the sky-button-ink rule).
class FieldPrimaryButton extends StatelessWidget {
  const FieldPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        backgroundColor: colors.sky,
        foregroundColor: colors.skyButtonInk,
        disabledBackgroundColor: const Color.fromRGBO(203, 188, 172, 0.12),
        disabledForegroundColor: colors.quiet,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.metrics.radiusMd),
        ),
      ),
      child: Text(
        label,
        style: context.kidunaText.bodySmall.copyWith(
          color: colors.skyButtonInk,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Secondary outlined Action button — sky border, transparent fill.
class FieldSecondaryButton extends StatelessWidget {
  const FieldSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 36),
        foregroundColor: colors.sky,
        side: BorderSide(color: colors.sky.withValues(alpha: 0.5)),
        disabledForegroundColor: colors.sky.withValues(alpha: 0.3),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.metrics.radiusMd),
        ),
      ),
      child: Text(
        label,
        style: context.kidunaText.bodySmall.copyWith(
          color: colors.sky,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Quiet / tertiary Action button — minimal visual weight, sky text only.
class FieldQuietButton extends StatelessWidget {
  const FieldQuietButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 36),
        foregroundColor: colors.sky,
        disabledForegroundColor: colors.sky.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.metrics.radiusMd),
        ),
      ),
      child: Text(
        label,
        style: context.kidunaText.bodySmall.copyWith(color: colors.sky),
      ),
    );
  }
}

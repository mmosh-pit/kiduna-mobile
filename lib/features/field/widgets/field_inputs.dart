import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// CSS `.fieldTitle` — label text for form fields.
class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 26),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: context.kidunaText.label.copyWith(color: colors.cream),
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
  String? suffixText,
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
    suffixText: suffixText,
    suffixStyle: suffixText != null
        ? context.kidunaText.micro.copyWith(
            color: colors.quiet,
            fontSize: 9,
          )
        : null,
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
    this.maxLength,
    this.minHeight,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final int? maxLength;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final isMultiLine = maxLines > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(text: label),
        const SizedBox(height: 6),
        if (maxLength != null)
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => TextField(
              controller: controller,
              maxLines: maxLines,
              maxLength: maxLength,
              buildCounter: (context,
                      {required currentLength,
                      required isFocused,
                      required maxLength}) =>
                  null,
              style: context.kidunaText.caption.copyWith(
                color: context.kiduna.text,
                height: 1.4,
              ),
              decoration: _decoration(
                context,
                hint,
                isMultiLine: isMultiLine,
                minHeight: minHeight,
                suffixText: '${controller.text.length}/$maxLength',
              ),
            ),
          )
        else
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
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(context.metrics.radiusMd),
      borderSide: BorderSide(color: colors.camel.withValues(alpha: 0.24)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(text: label),
        const SizedBox(height: 6),
        SizedBox(
          height: 37,
          child: DropdownButtonFormField<String>(
            initialValue: value,
            dropdownColor: colors.raised,
            icon: Icon(
              Icons.arrow_drop_down,
              color: colors.muted,
              size: 18,
            ),
            isDense: true,
            style: context.kidunaText.caption.copyWith(
              color: colors.text,
              height: 1.4,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color.fromRGBO(6, 3, 4, 0.66),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              constraints: const BoxConstraints(
                minHeight: 37,
                maxHeight: 37,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: BorderSide(color: colors.sky),
              ),
            ),
            items: [
              for (final option in options)
                DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ),
            ],
            onChanged: (next) {
              if (next != null) {
                onChanged(next);
              }
            },
          ),
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
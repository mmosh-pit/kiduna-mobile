import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// A small caption label above a field, styled per the prototype `.taskForm`.
class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.kidunaText.label.copyWith(color: context.kiduna.cream),
    );
  }
}

InputDecoration _decoration(BuildContext context, String? hint) {
  final colors = context.kiduna;
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(context.metrics.radiusMd),
    borderSide: BorderSide(color: colors.camel.withValues(alpha: 0.24)),
  );
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: colors.deep.withValues(alpha: 0.66),
    hintText: hint,
    hintStyle: context.kidunaText.body.copyWith(color: colors.quiet),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(text: label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: context.kidunaText.body.copyWith(color: context.kiduna.text),
          decoration: _decoration(context, hint),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(text: label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          dropdownColor: context.kiduna.raised,
          style: context.kidunaText.body.copyWith(color: context.kiduna.text),
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
        backgroundColor: colors.sky,
        foregroundColor: colors.skyButtonInk,
        disabledBackgroundColor: colors.sky.withValues(alpha: 0.09),
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

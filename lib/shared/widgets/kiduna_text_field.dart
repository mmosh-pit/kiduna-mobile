import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';

class KidunaTextField extends StatelessWidget {
  const KidunaTextField({
    super.key,
    required this.label,
    this.placeholder,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.maxLength,
    this.required = false,
    this.suffix,
    this.onChanged,
    this.autofocus = false,
  });

  final String label;
  final String? placeholder;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final bool required;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              label,
              style: text.caption.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: text.caption.copyWith(
                  color: colors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLength: maxLength,
          autofocus: autofocus,
          onChanged: onChanged,
          style: text.body.copyWith(color: colors.text, fontSize: 15),
          cursorColor: colors.sky,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: text.body.copyWith(
              color: colors.text.withValues(alpha: 0.28),
              fontSize: 15,
            ),
            counterText: '',
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            filled: true,
            fillColor: colors.deep.withValues(alpha: 0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: colors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: colors.camel.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: colors.sky),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.onSubmitted,
    this.autofocus = false,
    this.textInputAction,
    this.focusNode,
    this.enableInteractiveSelection = true,
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
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  /// Whether text can be selected, copied, and pasted.
  ///
  /// Set explicitly because Flutter defaults this to `!obscureText`, which
  /// ties selection to visibility: toggling a password field to visible does
  /// not reliably restore select-all and copy, since the coupling is decided
  /// per build rather than per state change.
  final bool enableInteractiveSelection;

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
        // Flutter refuses to copy from a field built with obscureText, and
        // that refusal is decided inside EditableText — toggling the field
        // visible does not lift it. Selection still works, so the user sees
        // their password highlighted and nothing lands on the clipboard.
        // Handling the shortcut here writes the selection out directly.
        Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.keyC, control: true):
                _CopyFieldIntent(),
            SingleActivator(LogicalKeyboardKey.keyC, meta: true):
                _CopyFieldIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _CopyFieldIntent: CallbackAction<_CopyFieldIntent>(
                onInvoke: (_) => _copySelection(context),
              ),
            },
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscureText,
              enableInteractiveSelection: enableInteractiveSelection,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              maxLength: maxLength,
              autofocus: autofocus,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
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
          ),
        ),
      ],
    );
  }

  /// Copy the current selection, or the whole value if nothing is selected.
  ///
  /// Returns null so the action is always considered handled — falling
  /// through would hand the shortcut back to EditableText, which is what
  /// drops it.
  Object? _copySelection(BuildContext context) {
    // Keep Flutter's guard for concealed text: copy is restored only once
    // the user has chosen to reveal the field.
    if (obscureText) return null;

    final c = controller;
    if (c == null) return null;

    final selection = c.selection;
    final value = c.text;
    if (value.isEmpty) return null;

    final selected = selection.isValid && !selection.isCollapsed
        ? selection.textInside(value)
        : value;

    if (selected.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: selected));
    }
    return null;
  }
}

/// Intent for the field-level copy shortcut.
class _CopyFieldIntent extends Intent {
  const _CopyFieldIntent();
}

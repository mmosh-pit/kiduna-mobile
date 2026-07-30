import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// The Ki message composer — a text input with voice and send controls.
class KiComposer extends StatelessWidget {
  const KiComposer({super.key, required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Padding(
      padding: const EdgeInsets.fromLTRB(19, 0, 19, 17),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.deep.withValues(alpha: 0.78),
          border: Border.all(color: colors.camel.withValues(alpha: 0.23)),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onSend(),
                style: context.kidunaText.body.copyWith(color: colors.text),
                decoration: InputDecoration(
                  hintText: '${context.l10n.messageKi}…',
                  hintStyle: context.kidunaText.body.copyWith(
                    color: colors.cream.withValues(alpha: 0.58),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 13),
                  constraints: const BoxConstraints(minHeight: 48),
                ),
              ),
            ),
            IconButton(
              onPressed: () {},
              tooltip: context.l10n.startVoiceInput,
              icon: Icon(Icons.mic_none, size: 18, color: colors.sky),
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              padding: EdgeInsets.zero,
            ),
            _SendButton(controller: controller, onSend: onSend),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final enabled = value.text.trim().isNotEmpty;
        return Semantics(
          button: true,
          label: context.l10n.sendToKi,
          child: IconButton(
            onPressed: enabled ? onSend : null,
            tooltip: context.l10n.sendToKi,
            style: IconButton.styleFrom(
              backgroundColor: enabled
                  ? colors.sky
                  : colors.sky.withValues(alpha: 0.09),
              foregroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            icon: const Text('↑'),
          ),
        );
      },
    );
  }
}

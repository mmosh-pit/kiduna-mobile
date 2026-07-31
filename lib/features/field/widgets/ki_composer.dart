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
          color: const Color.fromRGBO(6, 3, 4, 0.78),
          border: Border.all(color: colors.camel.withValues(alpha: 0.23)),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onSend(),
                style: context.kidunaText.body.copyWith(
                  color: colors.text,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: '${context.l10n.messageKi}…',
                  hintStyle: context.kidunaText.body.copyWith(
                    fontSize: 13,
                    color: colors.cream.withValues(alpha: 0.58),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 13),
                  constraints: const BoxConstraints(minHeight: 48),
                ),
              ),
            ),
            _VoiceButton(onPressed: () {}),
            _SendButton(controller: controller, onSend: onSend),
          ],
        ),
      ),
    );
  }
}

class _VoiceButton extends StatelessWidget {
  const _VoiceButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return SizedBox(
      width: 40,
      height: 48,
      child: IconButton(
        onPressed: onPressed,
        tooltip: context.l10n.startVoiceInput,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        icon: Icon(Icons.mic_none, size: 18, color: colors.sky),
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
          child: SizedBox(
            width: 40,
            height: 48,
            child: Center(
              child: SizedBox(
                width: 34,
                height: 36,
                child: TextButton(
                  onPressed: enabled ? onSend : null,
                  style: TextButton.styleFrom(
                    backgroundColor: enabled
                        ? colors.sky
                        : colors.sky.withValues(alpha: 0.09),
                    foregroundColor: enabled ? colors.deep : colors.quiet,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    textStyle: context.kidunaText.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('↑'),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// The Ki message composer — a text input with voice and send controls.
class KiComposer extends StatefulWidget {
  const KiComposer({super.key, required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  State<KiComposer> createState() => _KiComposerState();
}

class _KiComposerState extends State<KiComposer> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final borderColor = _focused
        ? colors.sky
        : colors.camel.withValues(alpha: 0.23);
    return Padding(
      padding: const EdgeInsets.fromLTRB(19, 0, 19, 17),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color.fromRGBO(6, 3, 4, 0.78),
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(7),
          boxShadow: _focused
              ? [BoxShadow(color: colors.sky.withValues(alpha: 0.1))]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Focus(
                onFocusChange: (v) => setState(() => _focused = v),
                child: TextField(
                  controller: widget.controller,
                  onSubmitted: (_) => widget.onSend(),
                  style: context.kidunaText.body.copyWith(
                    color: colors.text,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: context.l10n.messageKi,
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
            ),
            _VoiceButton(onPressed: () {}),
            _SendButton(controller: widget.controller, onSend: widget.onSend),
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
      child: Center(
        child: SizedBox(
          width: 34,
          height: 36,
          child: IconButton(
            onPressed: onPressed,
            tooltip: context.l10n.startVoiceInput,
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            icon: Icon(Icons.mic_none, size: 18, color: colors.sky),
          ),
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

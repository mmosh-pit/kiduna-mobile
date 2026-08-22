import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';

class KiComposer extends StatefulWidget {
  const KiComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.onMic,
    this.enabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onMic;
  final bool enabled;

  @override
  State<KiComposer> createState() => _KiComposerState();
}

class _KiComposerState extends State<KiComposer> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final borderColor = _focused
        ? colors.sky.withValues(alpha: 0.5)
        : colors.cream.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.deep,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Expanded(
            child: Focus(
              onFocusChange: (v) => setState(() => _focused = v),
              child: TextField(
                controller: widget.controller,
                enabled: widget.enabled,
                onSubmitted: widget.enabled ? (_) => widget.onSend() : null,
                style: context.kidunaText.body.copyWith(color: colors.cream),
                decoration: InputDecoration(
                  hintText: 'Message Ki...',
                  hintStyle: context.kidunaText.body.copyWith(
                    color: colors.quiet,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          _MicButton(
            onTap: widget.onMic,
            enabled: widget.enabled,
          ),
          const SizedBox(width: 5),
          _SendButton(
            controller: widget.controller,
            onSend: widget.onSend,
            enabled: widget.enabled,
          ),
        ],
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.onTap, required this.enabled});

  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final active = enabled && onTap != null;

    return GestureDetector(
      onTap: active ? onTap : null,
      child: MouseRegion(
        cursor: active ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colors.sky.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.mic,
            size: 16,
            color: active ? colors.sky : colors.quiet,
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final active = value.text.trim().isNotEmpty && enabled;

        return GestureDetector(
          onTap: active ? onSend : null,
          child: MouseRegion(
            cursor: active
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: active ? colors.sky : colors.sky.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_upward_rounded,
                size: 16,
                color: active ? colors.deep : colors.quiet,
              ),
            ),
          ),
        );
      },
    );
  }
}

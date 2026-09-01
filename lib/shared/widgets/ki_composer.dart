import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';

class KiComposer extends StatefulWidget {
  const KiComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.onMic,
    this.onPlus,
    this.enabled = true,
    this.hintText,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onMic;

  /// Called when the + button is tapped (attachments, quick actions).
  final VoidCallback? onPlus;
  final bool enabled;

  /// Override the default placeholder text.
  final String? hintText;

  @override
  State<KiComposer> createState() => _KiComposerState();
}

class _KiComposerState extends State<KiComposer> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    final borderColor = _focused
        ? colors.sky.withValues(alpha: 0.55)
        : colors.cream.withValues(alpha: 0.08);

    final glowColor = _focused
        ? colors.sky.withValues(alpha: 0.1)
        : Colors.transparent;

    final hint = widget.hintText ?? 'Say or type what you want to help move...';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(4, 4, 6, 4),
      decoration: BoxDecoration(
        color: colors.deep,
        border: Border.all(color: borderColor, width: 1.2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (_focused)
            BoxShadow(
              color: glowColor,
              blurRadius: 12,
            ),
        ],
      ),
      child: Row(
        children: [
          // + button.
          _PlusButton(
            onTap: widget.onPlus,
            enabled: widget.enabled,
          ),
          const SizedBox(width: 4),
          // Text input.
          Expanded(
            child: Focus(
              onFocusChange: (v) => setState(() => _focused = v),
              child: TextField(
                controller: widget.controller,
                enabled: widget.enabled,
                onSubmitted: widget.enabled ? (_) => widget.onSend() : null,
                style: context.kidunaText.body.copyWith(
                  color: colors.cream,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: context.kidunaText.body.copyWith(
                    color: colors.quiet.withValues(alpha: 0.6),
                    fontSize: 13,
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
          const SizedBox(width: 4),
          // Mic button.
          _MicButton(
            onTap: widget.onMic,
            enabled: widget.enabled,
          ),
          const SizedBox(width: 4),
          // Send button.
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

class _PlusButton extends StatefulWidget {
  const _PlusButton({required this.onTap, required this.enabled});

  final VoidCallback? onTap;
  final bool enabled;

  @override
  State<_PlusButton> createState() => _PlusButtonState();
}

class _PlusButtonState extends State<_PlusButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final active = widget.enabled;

    return MouseRegion(
      cursor: active ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: active ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _hovered
                ? colors.sky.withValues(alpha: 0.12)
                : colors.cream.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? colors.sky.withValues(alpha: 0.3)
                  : colors.cream.withValues(alpha: 0.08),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.add_rounded,
            size: 18,
            color: _hovered
                ? colors.sky
                : (active
                    ? colors.cream.withValues(alpha: 0.5)
                    : colors.quiet),
          ),
        ),
      ),
    );
  }
}

class _MicButton extends StatefulWidget {
  const _MicButton({required this.onTap, required this.enabled});

  final VoidCallback? onTap;
  final bool enabled;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final active = widget.enabled && widget.onTap != null;

    return MouseRegion(
      cursor: active ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: active ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _hovered
                ? colors.sky.withValues(alpha: 0.12)
                : colors.sky.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.mic_rounded,
            size: 17,
            color: _hovered
                ? colors.sky
                : (active ? colors.sky.withValues(alpha: 0.7) : colors.quiet),
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatefulWidget {
  const _SendButton({
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        final active = value.text.trim().isNotEmpty && widget.enabled;

        return MouseRegion(
          cursor:
              active ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: active ? widget.onSend : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: active
                    ? (_hovered
                        ? colors.sky.withValues(alpha: 0.85)
                        : colors.sky)
                    : colors.sky.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_upward_rounded,
                size: 17,
                color: active ? colors.deep : colors.quiet,
              ),
            ),
          ),
        );
      },
    );
  }
}
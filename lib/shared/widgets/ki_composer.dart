import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';

/// Ki chat input bar with + button, mic, send.
/// Teal glow on focus, dark purple background.
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
  final VoidCallback? onPlus;
  final bool enabled;
  final String? hintText;

  @override
  State<KiComposer> createState() => _KiComposerState();
}

class _KiComposerState extends State<KiComposer> {
  bool _focused = false;

  // Hardcoded colors matching David's PDF palette.
  static const _deep = Color(0xFF15121D);
  static const _teal = Color(0xFF03C7D5);
  static const _cream = Color(0xFFE8E0D4);
  static const _muted = Color(0xFF8A7E72);
  static const _quiet = Color(0xFF4A4440);
  static const _border = Color(0xFF2A2235);

  @override
  Widget build(BuildContext context) {
    final borderColor = _focused
        ? _teal.withValues(alpha: 0.55)
        : _border;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(5, 5, 6, 5),
      decoration: BoxDecoration(
        color: _deep,
        border: Border.all(color: borderColor, width: 1.3),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          if (_focused)
            BoxShadow(
              color: _teal.withValues(alpha: 0.12),
              blurRadius: 14,
            ),
        ],
      ),
      child: Row(
        children: [
          // + button.
          _ComposerBtn(
            icon: Icons.add_rounded,
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
                style: const TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 14,
                  color: _cream,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText ?? 'Say or type what you want to help move...',
                  hintStyle: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 13,
                    color: _muted.withValues(alpha: 0.5),
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

          // Mic.
          _ComposerBtn(
            icon: Icons.mic_rounded,
            onTap: widget.onMic,
            enabled: widget.enabled && widget.onMic != null,
            accent: true,
          ),
          const SizedBox(width: 4),

          // Send.
          _SendBtn(
            controller: widget.controller,
            onSend: widget.onSend,
            enabled: widget.enabled,
          ),
        ],
      ),
    );
  }
}

class _ComposerBtn extends StatefulWidget {
  const _ComposerBtn({
    required this.icon,
    required this.onTap,
    required this.enabled,
    this.accent = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;
  final bool accent;

  @override
  State<_ComposerBtn> createState() => _ComposerBtnState();
}

class _ComposerBtnState extends State<_ComposerBtn> {
  bool _h = false;

  static const _teal = Color(0xFF03C7D5);
  static const _cream = Color(0xFFE8E0D4);
  static const _quiet = Color(0xFF4A4440);
  static const _border = Color(0xFF2A2235);

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled;

    return MouseRegion(
      cursor: active ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: active ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _h
                ? _teal.withValues(alpha: 0.1)
                : _cream.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _h
                  ? _teal.withValues(alpha: 0.3)
                  : _border.withValues(alpha: 0.6),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            widget.icon,
            size: 17,
            color: _h
                ? _teal
                : (widget.accent
                    ? _teal.withValues(alpha: 0.5)
                    : (active
                        ? _cream.withValues(alpha: 0.4)
                        : _quiet)),
          ),
        ),
      ),
    );
  }
}

class _SendBtn extends StatefulWidget {
  const _SendBtn({
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  @override
  State<_SendBtn> createState() => _SendBtnState();
}

class _SendBtnState extends State<_SendBtn> {
  bool _h = false;

  static const _teal = Color(0xFF03C7D5);
  static const _deep = Color(0xFF0C0914);
  static const _quiet = Color(0xFF4A4440);
  static const _border = Color(0xFF2A2235);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        final active = value.text.trim().isNotEmpty && widget.enabled;

        return MouseRegion(
          cursor: active ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _h = true),
          onExit: (_) => setState(() => _h = false),
          child: GestureDetector(
            onTap: active ? widget.onSend : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: active
                    ? (_h ? _teal.withValues(alpha: 0.85) : _teal)
                    : _teal.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: active ? null : Border.all(color: _border.withValues(alpha: 0.6)),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_upward_rounded,
                size: 17,
                color: active ? _deep : _quiet,
              ),
            ),
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// CSS `.ki form` — the Ki message composer.
/// grid-template-columns: minmax(0,1fr) 34px; gap 5px; padding 6px;
/// border: 1px solid var(--line); border-radius: 9px; background: #090b0c
class KiComposer extends StatefulWidget {
  const KiComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.isStreaming = false,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isStreaming;

  @override
  State<KiComposer> createState() => _KiComposerState();
}

class _KiComposerState extends State<KiComposer> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    // CSS .ki form: padding 6, border 1px solid var(--line), radius 9, bg #090b0c
    // --line = rgba(242,234,223,.13)
    final borderColor = _focused
        ? const Color(0x8003CCD9) // sky 50% on focus — not full bright
        : const Color(0x1AF2EADF); // rgba(242,234,223,.10) — very faint

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF090B0C), // CSS background: #090b0c
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(9), // CSS border-radius: 9px
      ),
      child: Row(
        children: [
          // CSS grid-template-columns: minmax(0,1fr) — input takes remaining
          Expanded(
            child: Focus(
              onFocusChange: (v) => setState(() => _focused = v),
              child: TextField(
                controller: widget.controller,
                onSubmitted: widget.isStreaming ? null : (_) => widget.onSend(),
                // CSS .ki input: font-size 8px, color var(--cream)
                style: const TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFF2EADF), // --cream
                ),
                decoration: InputDecoration(
                  hintText: context.l10n.messageKi,
                  // CSS .ki input::placeholder: color #686661
                  hintStyle: const TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF686661),
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
          const SizedBox(width: 5), // CSS gap: 5px
          // Voice + Send in a row, each ~34px
          _VoiceButton(onPressed: () {}),
          const SizedBox(width: 5),
          _SendButton(
            controller: widget.controller,
            onSend: widget.onSend,
            isStreaming: widget.isStreaming,
          ),
        ],
      ),
    );
  }
}

/// CSS `.voiceButton` — 34×36, grid+place-items:center, hover sky 8%.
class _VoiceButton extends StatefulWidget {
  const _VoiceButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<_VoiceButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Container(
          width: 34,
          height: 36,
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0x1403CCD9) // rgba(3,204,217,.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: const _MicIcon(color: Color(0xFF03CCD9)),
        ),
      ),
    );
  }
}

/// CSS `.voiceButton span` + `::before` + `::after` — built from borders,
/// no CustomPaint. Capsule 9×14, pickup U-arc 13×8, stem 1.5×4.
class _MicIcon extends StatelessWidget {
  const _MicIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 13,
      height: 22,
      child: Stack(
        children: [
          // CSS span: 9×14, border 1.5px solid, border-radius 7px (capsule)
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: 9,
              height: 14,
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 1.5),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
          // CSS ::before: U-shape — bottom half of a 13×16 rounded rect clipped
          // to 8px height, positioned at y=11 (bottom:-5px from 14px capsule)
          Positioned(
            top: 11,
            left: 0,
            child: ClipRect(
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: 0.5,
                child: Container(
                  width: 13,
                  height: 16,
                  decoration: BoxDecoration(
                    border: Border.all(color: color, width: 1.5),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ),
          ),
          // CSS ::after: stem 1.5×4, centered, y=18→22
          Positioned(
            top: 18,
            left: (13 - 1.5) / 2,
            child: Container(width: 1.5, height: 4, color: color),
          ),
        ],
      ),
    );
  }
}

/// CSS `.sendButton` — 34×34, sky fill when enabled, dimmed when disabled.
/// border-radius 6, color dark when enabled.
class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.controller,
    required this.onSend,
    this.isStreaming = false,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final enabled = value.text.trim().isNotEmpty && !isStreaming;
        return GestureDetector(
          onTap: enabled ? onSend : null,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              // CSS: enabled = sky solid, disabled = sky 9%
              color: enabled
                  ? const Color(0xFF03CCD9) // sky
                  : const Color(0x1703CCD9), // sky 9%
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              '↑',
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                // CSS: enabled = dark ground, disabled = quiet
                color: enabled
                    ? const Color(0xFF090B0C) // ground
                    : const Color(0xFF918B82), // quiet
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Ki — a floating panel over the full-bleed Field.
///
/// Ki is **not a Field object**. It never enters the world, never scales with
/// the camera, and the Field never reaches into it. It is a persistent surface
/// the Source can move, and on a narrow viewport it becomes a bottom sheet
/// rather than trying to hold a column that does not fit.
///
/// The Field-focus control is the one thing here that touches the Field, and
/// it touches **opacity only** — see [KiPanel.onFocus] and how `main.dart`
/// applies it.
library;

import 'package:flutter/material.dart';

import '../design/ground.dart';
import '../design/tokens.dart';
import '../design/typography.dart';
import 'ki_voice.dart';

class KiPanel extends StatefulWidget {
  const KiPanel({
    required this.line,
    required this.focus,
    required this.onFocus,
    this.allies = 0,
    super.key,
  });

  final KiLine line;

  /// Field opacity, 0.2–1.0.
  final double focus;

  /// Reports a new Field opacity. Nothing else may be inferred from it.
  final ValueChanged<double> onFocus;

  final int allies;

  @override
  State<KiPanel> createState() => _KiPanelState();
}

class _KiPanelState extends State<KiPanel> {
  static const _width = 380.0;
  static const _narrow = 900.0;

  /// Desktop placement, in logical pixels from the top-left. Null until the
  /// Source moves it, so it can rest against the right edge at any size.
  Offset? _at;

  /// Sheet extent on a narrow viewport: peek, or opened.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width < _narrow ? _sheet(context, size) : _floating(context, size);
  }

  // ── Desktop and web · a movable panel ─────────────────────────────────

  Widget _floating(BuildContext context, Size size) {
    final at = _at ?? Offset(size.width - _width - 24, 24);
    final maxHeight = size.height - 48;

    return Positioned(
      left: at.dx.clamp(8.0, size.width - _width - 8),
      top: at.dy.clamp(8.0, size.height - 120),
      width: _width,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: _shell(
          context,
          onDrag: (delta) => setState(() => _at = at + delta),
          scrollable: true,
        ),
      ),
    );
  }

  // ── Narrow · a draggable bottom sheet ─────────────────────────────────

  Widget _sheet(BuildContext context, Size size) {
    final height = _expanded ? size.height * 0.62 : 132.0;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: height,
        child: _shell(
          context,
          onDrag: (delta) {
            if (delta.dy < -4 && !_expanded) setState(() => _expanded = true);
            if (delta.dy > 4 && _expanded) setState(() => _expanded = false);
          },
          scrollable: true,
          grabHandle: true,
        ),
      ),
    );
  }

  // ── Shared chrome ─────────────────────────────────────────────────────

  Widget _shell(
    BuildContext context, {
    required ValueChanged<Offset> onDrag,
    required bool scrollable,
    bool grabHandle = false,
  }) {
    return KidunaGround(
      ground: Enamel.warmSurface,
      child: Material(
        color: Enamel.warmSurface.withValues(alpha: 0.97),
        elevation: 0,
        borderRadius: BorderRadius.circular(grabHandle ? 0 : 5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(grabHandle ? 0 : 5),
            border: Border.all(color: Enamel.raisedUmber),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (d) => onDrag(d.delta),
                child: _header(grabHandle: grabHandle),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.line.body, style: Type.body),
                      const SizedBox(height: 16),
                      for (final q in widget.line.questions)
                        _SuggestedQuestion(q),
                    ],
                  ),
                ),
              ),
              const _Composer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header({required bool grabHandle}) => Padding(
        padding: EdgeInsets.fromLTRB(18, grabHandle ? 8 : 16, 14, 12),
        child: Column(
          children: [
            if (grabHandle)
              Container(
                width: 40,
                height: 3,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Enamel.camel.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            Row(
              children: [
                Image.asset('assets/brand/ki-mark.png', width: 34, height: 34),
                const SizedBox(width: 11),
                Text('Ki', style: Type.heading),
                const SizedBox(width: 12),
                if (widget.allies > 0) _AlliesChip(count: widget.allies),
                const Spacer(),
                _FieldFocus(value: widget.focus, onChanged: widget.onFocus),
              ],
            ),
          ],
        ),
      );
}

class _AlliesChip extends StatelessWidget {
  const _AlliesChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Enamel.skyBlue.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Your Allies  $count',
          style: Type.operational.copyWith(color: Enamel.skyBlue),
        ),
      );
}

/// **Field focus.**
///
/// > Field focus changes Field opacity only; it never changes Ki, visibility,
/// > authority, relationship truth, or underlying data.
///
/// This widget reports a number between 0.2 and 1.0 and holds no other
/// reference to the Field. It is incapable of doing anything else.
class _FieldFocus extends StatelessWidget {
  const _FieldFocus({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Text('FIELD FOCUS', style: Type.eyebrow),
            const SizedBox(width: 8),
            Text(
              '${(value * 100).round()}%',
              style: Type.operational.copyWith(color: Enamel.skyBlue),
            ),
          ],
        ),
        SizedBox(
          width: 120,
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Enamel.skyBlue,
              inactiveTrackColor: Enamel.raisedUmber,
              thumbColor: Enamel.cream,
              overlayColor: Enamel.skyBlue.withValues(alpha: 0.14),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value,
              min: 0.2,
              max: 1.0,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// Terse, and phrased as the Source would ask them.
class _SuggestedQuestion extends StatelessWidget {
  const _SuggestedQuestion(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(color: Enamel.skyBlue.withValues(alpha: 0.32)),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            text,
            style: Type.body.copyWith(color: Enamel.skyBlue, fontSize: 13),
          ),
        ),
      );
}

/// The composer is present and inert. This build demonstrates the surface; it
/// does not run an agent, and it must not appear to.
class _Composer extends StatelessWidget {
  const _Composer();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Enamel.raisedUmber)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Message Ki…',
                style: Type.body.copyWith(
                  color: Enamel.camel.withValues(alpha: 0.7),
                ),
              ),
            ),
            Icon(Icons.mic_none, size: 19, color: Enamel.camel),
            const SizedBox(width: 10),
            const SkyAction(label: '↑'),
          ],
        ),
      );
}

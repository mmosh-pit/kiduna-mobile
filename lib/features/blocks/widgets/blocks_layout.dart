/// Horizontal scrollable block canvas for the Blocks view.
///
/// File placement: lib/features/blocks/widgets/blocks_layout.dart
library;

import 'dart:math' show Random, max, min;

import 'package:flutter/material.dart';

// ── Teal + Gold theme ────────────────────────────────────────────────

const Color _bgCanvas = Color(0xFF0A0E10);
const Color _cardSurface = Color(0xF2151A1E);
const Color _cardBorder = Color(0xFF223038);
const Color _cardBorderHover = Color(0xFF03CCD9);
const Color _teal = Color(0xFF03CCD9);
const Color _gold = Color(0xFFEDC169);
const Color _cream = Color(0xFFF2EADF);
const Color _muted = Color(0xFF9E8E78);
const Color _quiet = Color(0xFF5A5248);
const Color _green = Color(0xFF4CAF50);
const Color _btnFill = Color(0xFF03CCD9);
const Color _btnText = Color(0xFF0A0E10);

// ── Data models ──────────────────────────────────────────────────────

class BlockItem {
  const BlockItem({
    required this.id,
    required this.title,
    required this.priority,
    this.tealLabel,
    this.description,
    this.quoteText,
    this.quoteFrom,
    this.activityText,
    this.buttons = const [],
    this.actionRows = const [],
    this.bottomButtonLabel,
    this.onTap,
  });

  final String id;
  final String title;
  final int priority;
  final String? tealLabel;
  final String? description;
  final String? quoteText;
  final String? quoteFrom;
  final String? activityText;
  final List<BlockButton> buttons;
  final List<BlockActionRow> actionRows;
  /// Single action button at bottom of card (e.g. "Create", "Play").
  final String? bottomButtonLabel;
  final VoidCallback? onTap;
}

class BlockButton {
  const BlockButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;
}

class BlockActionRow {
  const BlockActionRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;
}

// ── Canvas layout ────────────────────────────────────────────────────

class BlocksCanvasLayout extends StatelessWidget {
  const BlocksCanvasLayout({super.key, required this.items});

  final List<BlockItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Container(color: _bgCanvas);

    return Container(
      color: _bgCanvas,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _DotsPainter())),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                return Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: h * 0.85,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          for (int i = 0; i < items.length; i++) ...[
                            if (i > 0) const SizedBox(width: 18),
                            _SizedCard(item: items[i], screenWidth: w),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SizedCard extends StatelessWidget {
  const _SizedCard({required this.item, required this.screenWidth});

  final BlockItem item;
  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    final base = max(200.0, min(screenWidth * 0.22, 290.0));
    final double factor;
    if (item.priority >= 8) {
      factor = 1.25;
    } else if (item.priority >= 5) {
      factor = 1.05;
    } else {
      factor = 0.95;
    }
    return SizedBox(
      width: base * factor,
      child: _BlockCard(item: item),
    );
  }
}

// ── Card ─────────────────────────────────────────────────────────────

class _BlockCard extends StatefulWidget {
  const _BlockCard({required this.item});

  final BlockItem item;

  @override
  State<_BlockCard> createState() => _BlockCardState();
}

class _BlockCardState extends State<_BlockCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.item.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _cardSurface,
            border: Border.all(
              color: _hovered ? _cardBorderHover : _cardBorder,
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? _teal.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.3),
                blurRadius: _hovered ? 24 : 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Sigil(hovered: _hovered),
              const SizedBox(height: 16),

              if (widget.item.tealLabel != null) ...[
                Text(
                  widget.item.tealLabel!,
                  style: const TextStyle(
                    fontFamily: 'Avenir', fontSize: 10,
                    fontWeight: FontWeight.w700, color: _teal,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              Text(
                widget.item.title,
                style: TextStyle(
                  fontFamily: widget.item.priority >= 8
                      ? 'GoudyHeavyface' : 'Avenir',
                  fontSize: widget.item.priority >= 8 ? 22 : 16,
                  fontWeight: widget.item.priority >= 8
                      ? FontWeight.w400 : FontWeight.w700,
                  color: _cream, height: 1.3,
                ),
              ),

              if (widget.item.description != null) ...[
                const SizedBox(height: 10),
                Text(
                  widget.item.description!,
                  style: const TextStyle(
                    fontFamily: 'Avenir', fontSize: 13,
                    color: _muted, height: 1.55,
                  ),
                ),
              ],

              // Quote box.
              if (widget.item.quoteText != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(
                        color: _gold.withValues(alpha: 0.35),
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.item.quoteFrom != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            widget.item.quoteFrom!,
                            style: TextStyle(
                              fontFamily: 'Avenir', fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _gold.withValues(alpha: 0.7),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      Text(
                        '"${widget.item.quoteText!}"',
                        style: TextStyle(
                          fontFamily: 'Avenir', fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: _cream.withValues(alpha: 0.75),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (widget.item.activityText != null) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(
                        color: _green, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: _green, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.item.activityText!,
                        style: const TextStyle(
                          fontFamily: 'Avenir', fontSize: 12, color: _muted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              if (widget.item.actionRows.isNotEmpty) ...[
                const SizedBox(height: 16),
                for (final row in widget.item.actionRows)
                  _ActionRow(row: row),
              ],

              if (widget.item.buttons.isNotEmpty) ...[
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10, runSpacing: 8,
                  children: [
                    for (final btn in widget.item.buttons)
                      _Btn(button: btn),
                  ],
                ),
              ],

              // Bottom action button.
              if (widget.item.bottomButtonLabel != null) ...[
                const SizedBox(height: 18),
                _BottomBtn(
                  label: widget.item.bottomButtonLabel!,
                  onTap: widget.item.onTap,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sigil ─────────────────────────────────────────────────────────────

class _Sigil extends StatelessWidget {
  const _Sigil({required this.hovered});
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48, height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          _gold.withValues(alpha: hovered ? 0.35 : 0.2),
          _gold.withValues(alpha: 0.02),
        ]),
        border: Border.all(
          color: _gold.withValues(alpha: hovered ? 0.5 : 0.25), width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: hovered ? 0.15 : 0.05),
            blurRadius: hovered ? 18 : 8,
          ),
        ],
      ),
      child: const Icon(Icons.auto_awesome, size: 22, color: _gold),
    );
  }
}

// ── Top buttons (Step into the Field, etc.) ──────────────────────────

class _Btn extends StatefulWidget {
  const _Btn({required this.button});
  final BlockButton button;
  @override
  State<_Btn> createState() => _BtnState();
}

class _BtnState extends State<_Btn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final p = widget.button.primary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.button.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: p ? (_h ? _btnFill.withValues(alpha: 0.85) : _btnFill)
                : (_h ? _cream.withValues(alpha: 0.06) : Colors.transparent),
            border: p ? null : Border.all(
              color: _h ? _teal.withValues(alpha: 0.45)
                  : _quiet.withValues(alpha: 0.4),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.button.label,
            style: TextStyle(
              fontFamily: 'Avenir', fontSize: 12, fontWeight: FontWeight.w600,
              color: p ? _btnText : (_h ? _teal : _cream.withValues(alpha: 0.85)),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom action button (Create, Play, Start, etc.) ─────────────────

class _BottomBtn extends StatefulWidget {
  const _BottomBtn({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  State<_BottomBtn> createState() => _BottomBtnState();
}

class _BottomBtnState extends State<_BottomBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _h ? _teal.withValues(alpha: 0.12) : _teal.withValues(alpha: 0.06),
            border: Border.all(
              color: _h ? _teal.withValues(alpha: 0.5) : _teal.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Avenir', fontSize: 13, fontWeight: FontWeight.w600,
              color: _h ? _teal : _teal.withValues(alpha: 0.8),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Action row ───────────────────────────────────────────────────────

class _ActionRow extends StatefulWidget {
  const _ActionRow({required this.row});
  final BlockActionRow row;
  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.row.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: _quiet.withValues(alpha: 0.12))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(widget.row.label,
                  style: TextStyle(
                    fontFamily: 'Avenir', fontSize: 14,
                    color: _h ? _teal : _cream.withValues(alpha: 0.75), height: 1.3,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18,
                color: _h ? _teal : _quiet.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dots ─────────────────────────────────────────────────────────────

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    final gp = Paint()..color = _gold.withValues(alpha: 0.2);
    final tp = Paint()..color = _teal.withValues(alpha: 0.14);
    for (int i = 0; i < 100; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 2.0 + 0.4;
      canvas.drawCircle(Offset(x, y), r, rng.nextBool() ? gp : tp);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
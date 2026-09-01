/// Blocks View — true Pinterest masonry layout.
/// 3 columns, shortest-column-first placement, content-based height.
/// Staggered entrance animation, tap = Enter.
///
/// File placement: lib/features/blocks/widgets/blocks_layout.dart
library;

import 'dart:math' show Random;
import 'package:flutter/material.dart';

const Color _bg = Color(0xFF0C0914);
const Color _cardTop = Color(0xFF1D1725);
const Color _cardBot = Color(0xFF13101B);
const Color _cardBorder = Color(0xFF2A2235);
const Color _teal = Color(0xFF03C7D5);
const Color _gold = Color(0xFFD4A84B);
const Color _goldLight = Color(0xFFEDC169);
const Color _cream = Color(0xFFE8E0D4);
const Color _muted = Color(0xFF8A7E72);
const Color _quiet = Color(0xFF4A4440);
const Color _green = Color(0xFF4CAF50);

class BlockItem {
  const BlockItem({
    required this.id,
    required this.title,
    this.tealLabel,
    this.description,
    this.activityText,
    this.bottomButtonLabel,
    this.onBottomButtonTap,
  });
  final String id, title;
  final String? tealLabel, description, activityText, bottomButtonLabel;
  final VoidCallback? onBottomButtonTap;
}

// ── Canvas ───────────────────────────────────────────────────────────

class BlocksCanvasLayout extends StatelessWidget {
  const BlocksCanvasLayout({super.key, required this.items});
  final List<BlockItem> items;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    // Number of columns.
    int cols;
    if (items.length <= 1) {
      cols = 1;
    } else if (items.length == 2 || screenW < 600) {
      cols = screenW < 450 ? 1 : 2;
    } else {
      cols = 3;
    }

    // Distribute items into columns — shortest column first (true masonry).
    // We estimate height by content: title length + description + extras.
    final colItems = List.generate(cols, (_) => <_MasonryItem>[]);
    final colHeights = List.filled(cols, 0.0);

    for (int i = 0; i < items.length; i++) {
      // Find shortest column.
      int shortest = 0;
      for (int c = 1; c < cols; c++) {
        if (colHeights[c] < colHeights[shortest]) shortest = c;
      }
      colItems[shortest].add(_MasonryItem(item: items[i], index: i));
      // Estimate card height for distribution.
      colHeights[shortest] += _estimateHeight(items[i]);
    }

    // Max width for the grid.
    final maxGridW = cols == 1
        ? 440.0
        : (cols == 2 ? 740.0 : 1100.0);

    return Container(
      color: _bg,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _DotsPainter())),
          Positioned.fill(
            child: ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxGridW),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int c = 0; c < cols; c++) ...[
                          if (c > 0) const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              children: [
                                for (int r = 0;
                                    r < colItems[c].length;
                                    r++) ...[
                                  if (r > 0) const SizedBox(height: 20),
                                  if (colItems[c][r].item.tealLabel == 'ECOSYSTEM')
                                    _EcosystemCard(
                                      item: colItems[c][r].item,
                                      index: colItems[c][r].index,
                                    )
                                  else
                                    _BlockCard(
                                      item: colItems[c][r].item,
                                      index: colItems[c][r].index,
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Rough height estimate for masonry distribution.
  static double _estimateHeight(BlockItem item) {
    double h = 160; // sigil + label + title + padding + button
    if (item.description != null) {
      h += 20 + (item.description!.length / 30 * 18).clamp(18, 72);
    }
    if (item.activityText != null) h += 30;
    return h;
  }
}

class _MasonryItem {
  const _MasonryItem({required this.item, required this.index});
  final BlockItem item;
  final int index;
}

// ── Ecosystem hero card (premium, unique) ────────────────────────────

class _EcosystemCard extends StatefulWidget {
  const _EcosystemCard({required this.item, required this.index});
  final BlockItem item;
  final int index;
  @override State<_EcosystemCard> createState() => _EcosystemCardState();
}

class _EcosystemCardState extends State<_EcosystemCard>
    with TickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;
  late final AnimationController _enterAnim;
  late final AnimationController _pulseAnim;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _enterAnim = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 600));
    _fadeIn = CurvedAnimation(parent: _enterAnim, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterAnim, curve: Curves.easeOutCubic));

    // Pulsing glow on the sigil.
    _pulseAnim = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _enterAnim.forward();
    });
  }

  @override
  void dispose() {
    _enterAnim.dispose();
    _pulseAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasTap = widget.item.onBottomButtonTap != null;

    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: MouseRegion(
          cursor: hasTap ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() { _hovered = false; _pressed = false; }),
          child: GestureDetector(
            onTapDown: hasTap ? (_) => setState(() => _pressed = true) : null,
            onTapUp: hasTap ? (_) => setState(() => _pressed = false) : null,
            onTapCancel: hasTap ? () => setState(() => _pressed = false) : null,
            onTap: hasTap ? widget.item.onBottomButtonTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              transform: _pressed
                  ? (Matrix4.identity()..translate(0.0, 2.0))
                  : Matrix4.identity(),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [
                    _hovered ? const Color(0xFF251C32) : const Color(0xFF201830),
                    const Color(0xFF14101C),
                  ],
                ),
                border: Border.all(
                  color: _hovered
                      ? _teal.withValues(alpha: 0.45)
                      : _teal.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 24, offset: const Offset(0, 10)),
                  BoxShadow(color: _teal.withValues(alpha: _hovered ? 0.1 : 0.04),
                    blurRadius: 50),
                  BoxShadow(color: _gold.withValues(alpha: 0.03),
                    blurRadius: 60),
                ],
              ),
              padding: const EdgeInsets.all(26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Premium sigil with pulse.
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, child) {
                      final pulse = _pulseAnim.value * 0.3 + 0.7;
                      return Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            _gold.withValues(alpha: 0.35 * pulse),
                            _gold.withValues(alpha: 0.01),
                          ]),
                          border: Border.all(
                            color: _gold.withValues(alpha: 0.5 * pulse), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: _goldLight.withValues(alpha: 0.25 * pulse),
                              blurRadius: 20),
                          ],
                        ),
                        child: const Icon(Icons.auto_awesome, size: 22, color: _goldLight),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // Teal label.
                  Text(
                    widget.item.tealLabel ?? 'ECOSYSTEM',
                    style: TextStyle(
                      fontFamily: 'Avenir', fontSize: 10, fontWeight: FontWeight.w700,
                      color: _teal.withValues(alpha: _hovered ? 1 : 0.85),
                      letterSpacing: 2.0),
                  ),
                  const SizedBox(height: 8),

                  // Title — large, serif.
                  Text(
                    widget.item.title,
                    style: const TextStyle(
                      fontFamily: 'GoudyHeavyface', fontSize: 24,
                      fontWeight: FontWeight.w400, color: _cream, height: 1.2),
                  ),

                  // Description.
                  if (widget.item.description != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      widget.item.description!,
                      style: const TextStyle(
                        fontFamily: 'Avenir', fontSize: 13,
                        color: _muted, height: 1.55),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Activity with pulsing dot.
                  if (widget.item.activityText != null) ...[
                    const SizedBox(height: 12),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (context, child) => Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(
                            color: _green, shape: BoxShape.circle,
                            boxShadow: [BoxShadow(
                              color: _green.withValues(alpha: 0.4 + _pulseAnim.value * 0.3),
                              blurRadius: 5 + _pulseAnim.value * 3)]),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(widget.item.activityText!,
                        style: const TextStyle(fontFamily: 'Avenir', fontSize: 12, color: _muted)),
                    ]),
                  ],

                  // Enter button — premium style.
                  if (widget.item.bottomButtonLabel != null) ...[
                    const SizedBox(height: 16),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          _hovered ? _teal.withValues(alpha: 0.2) : _teal.withValues(alpha: 0.08),
                          _hovered ? _teal.withValues(alpha: 0.12) : _teal.withValues(alpha: 0.03),
                        ]),
                        border: Border.all(
                          color: _hovered
                              ? _teal.withValues(alpha: 0.5)
                              : _teal.withValues(alpha: 0.18)),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          if (_hovered)
                            BoxShadow(color: _teal.withValues(alpha: 0.08), blurRadius: 20),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.item.bottomButtonLabel!,
                            style: TextStyle(fontFamily: 'Avenir', fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _hovered ? _teal : _teal.withValues(alpha: 0.8),
                              letterSpacing: 0.5),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18,
                            color: _hovered ? _teal : _teal.withValues(alpha: 0.6)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Block card (normal) ──────────────────────────────────────────────

class _BlockCard extends StatefulWidget {
  const _BlockCard({required this.item, required this.index});
  final BlockItem item;
  final int index;

  @override
  State<_BlockCard> createState() => _BlockCardState();
}

class _BlockCardState extends State<_BlockCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;
  late final AnimationController _enterAnim;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _enterAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeIn = CurvedAnimation(parent: _enterAnim, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _enterAnim, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _enterAnim.forward();
    });
  }

  @override
  void dispose() {
    _enterAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasTap = widget.item.onBottomButtonTap != null;

    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: MouseRegion(
          cursor:
              hasTap ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() {
            _hovered = false;
            _pressed = false;
          }),
          child: GestureDetector(
            onTapDown:
                hasTap ? (_) => setState(() => _pressed = true) : null,
            onTapUp:
                hasTap ? (_) => setState(() => _pressed = false) : null,
            onTapCancel:
                hasTap ? () => setState(() => _pressed = false) : null,
            onTap: hasTap ? widget.item.onBottomButtonTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              transform: _pressed
                  ? (Matrix4.identity()
                    ..translate(0.0, 2.0))
                  : Matrix4.identity(),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _hovered ? const Color(0xFF221A2E) : _cardTop,
                    _cardBot,
                  ],
                ),
                border: Border.all(
                  color: _hovered
                      ? _teal.withValues(alpha: 0.35)
                      : _cardBorder,
                  width: _hovered ? 1.3 : 1.0,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: _hovered ? 28 : 16,
                    offset: Offset(0, _hovered ? 10 : 6),
                  ),
                  if (_hovered)
                    BoxShadow(
                      color: _teal.withValues(alpha: 0.06),
                      blurRadius: 40,
                    ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sigil.
                  _Sigil(hovered: _hovered),
                  const SizedBox(height: 16),

                  // Teal label.
                  if (widget.item.tealLabel != null) ...[
                    Text(
                      widget.item.tealLabel!,
                      style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color:
                            _teal.withValues(alpha: _hovered ? 1 : 0.8),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Title.
                  Text(
                    widget.item.title,
                    style: const TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _cream,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Description.
                  if (widget.item.description != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      widget.item.description!,
                      style: const TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 13,
                        color: _muted,
                        height: 1.55,
                      ),
                      // No maxLines — content determines card height (masonry).
                    ),
                  ],

                  // Activity.
                  if (widget.item.activityText != null) ...[
                    const SizedBox(height: 14),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _green.withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.item.activityText!,
                          style: const TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 12,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Enter button.
                  if (widget.item.bottomButtonLabel != null) ...[
                    const SizedBox(height: 18),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: _hovered
                            ? _teal.withValues(alpha: 0.12)
                            : _teal.withValues(alpha: 0.04),
                        border: Border.all(
                          color: _hovered
                              ? _teal.withValues(alpha: 0.4)
                              : _teal.withValues(alpha: 0.12),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.item.bottomButtonLabel!,
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _hovered
                              ? _teal
                              : _teal.withValues(alpha: 0.7),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sigil ────────────────────────────────────────────────────────────

class _Sigil extends StatelessWidget {
  const _Sigil({required this.hovered});
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            _gold.withValues(alpha: hovered ? 0.35 : 0.18),
            _gold.withValues(alpha: 0.01),
          ],
        ),
        border: Border.all(
          color: _gold.withValues(alpha: hovered ? 0.6 : 0.28),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _goldLight.withValues(alpha: hovered ? 0.22 : 0.06),
            blurRadius: hovered ? 20 : 8,
          ),
          if (hovered)
            BoxShadow(
              color: _goldLight.withValues(alpha: 0.08),
              blurRadius: 30,
            ),
        ],
      ),
      child: const Icon(Icons.auto_awesome, size: 20, color: _goldLight),
    );
  }
}

// ── Dots ─────────────────────────────────────────────────────────────

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    final gp = Paint()..color = _goldLight.withValues(alpha: 0.15);
    final tp = Paint()..color = _teal.withValues(alpha: 0.08);
    for (int i = 0; i < 80; i++) {
      canvas.drawCircle(
        Offset(
            rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        rng.nextDouble() * 1.8 + 0.3,
        rng.nextBool() ? gp : tp,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
/// Pinterest/masonry block canvas — vertical scroll, multi-column.
/// Tap card body → expands height to show more content.
/// Tap button → triggers action. Tap close → shrinks back.
///
/// File placement: lib/features/blocks/widgets/blocks_layout.dart
library;

import 'dart:math' show Random, max, min;
import 'package:flutter/material.dart';

const Color _bgCanvas = Color(0xFF0C0914);
const Color _cardTop = Color(0xFF1D1725);
const Color _cardBot = Color(0xFF13101B);
const Color _cardSurface = Color(0xFF15121D);
const Color _cardBorder = Color(0xFF2A2235);
const Color _cardBorderHover = Color(0xFF03C7D5);
const Color _teal = Color(0xFF03C7D5);
const Color _gold = Color(0xFFD4A84B);
const Color _goldLight = Color(0xFFEDC169);
const Color _cream = Color(0xFFE8E0D4);
const Color _muted = Color(0xFF8A7E72);
const Color _quiet = Color(0xFF4A4440);
const Color _green = Color(0xFF4CAF50);
const Color _scrim = Color(0xFF0C0914);

// ── Data ─────────────────────────────────────────────────────────────

class BlockItem {
  const BlockItem({
    required this.id, required this.title, required this.priority,
    this.tealLabel, this.description, this.quoteText, this.quoteFrom,
    this.activityText, this.buttons = const [],
    this.bottomButtonLabel, this.onBottomButtonTap,
  });
  final String id, title;
  final int priority;
  final String? tealLabel, description, quoteText, quoteFrom,
      activityText, bottomButtonLabel;
  final List<BlockButton> buttons;
  final VoidCallback? onBottomButtonTap;
}

class BlockButton {
  const BlockButton({required this.label, required this.onTap, this.primary = false});
  final String label; final VoidCallback onTap; final bool primary;
}

// ── Canvas ───────────────────────────────────────────────────────────

class BlocksCanvasLayout extends StatefulWidget {
  const BlocksCanvasLayout({super.key, required this.items});
  final List<BlockItem> items;
  @override State<BlocksCanvasLayout> createState() => _CanvasState();
}

class _CanvasState extends State<BlocksCanvasLayout>
    with SingleTickerProviderStateMixin {
  String? _zoomedId;
  late final AnimationController _anim;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _curve = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _zoom(String id) {
    if (_zoomedId == id) {
      _unzoom();
      return;
    }
    setState(() => _zoomedId = id);
    _anim.forward(from: 0);
  }

  void _unzoom() {
    _anim.reverse().then((_) {
      if (mounted) setState(() => _zoomedId = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgCanvas,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _DotsPainter())),
          Positioned.fill(
            child: LayoutBuilder(builder: (ctx, box) {
              final w = box.maxWidth;
              final cols = w > 1100 ? 3 : (w > 600 ? 2 : 1);
              return _MasonryGrid(
                items: widget.items,
                columns: cols,
                zoomedId: _zoomedId,
                zoomAnim: _curve,
                onZoom: _zoom,
                onUnzoom: _unzoom,
              );
            }),
          ),
          // Scrim for zoomed card.
          if (_zoomedId != null)
            AnimatedBuilder(
              animation: _curve,
              builder: (_, __) => Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: ColoredBox(
                      color: _scrim.withValues(alpha: 0.5 * _curve.value)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Masonry grid ─────────────────────────────────────────────────────

class _MasonryGrid extends StatelessWidget {
  const _MasonryGrid({
    required this.items,
    required this.columns,
    required this.zoomedId,
    required this.zoomAnim,
    required this.onZoom,
    required this.onUnzoom,
  });

  final List<BlockItem> items;
  final int columns;
  final String? zoomedId;
  final Animation<double> zoomAnim;
  final void Function(String) onZoom;
  final VoidCallback onUnzoom;

  @override
  Widget build(BuildContext context) {
    // Distribute items across columns (shortest-column-first).
    final colItems = List.generate(columns, (_) => <BlockItem>[]);

    // Simple distribution: items already sorted by priority.
    // Distribute round-robin but give first column more high-priority items.
    for (int i = 0; i < items.length; i++) {
      // Put into the column with fewest items (balanced masonry).
      int minCol = 0;
      int minCount = colItems[0].length;
      for (int c = 1; c < columns; c++) {
        if (colItems[c].length < minCount) {
          minCount = colItems[c].length;
          minCol = c;
        }
      }
      colItems[minCol].add(items[i]);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int c = 0; c < columns; c++) ...[
            if (c > 0) const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  for (int r = 0; r < colItems[c].length; r++) ...[
                    if (r > 0) const SizedBox(height: 14),
                    _CardWidget(
                      item: colItems[c][r],
                      isZoomed: zoomedId == colItems[c][r].id,
                      zoomAnim: zoomAnim,
                      onBodyTap: () => onZoom(colItems[c][r].id),
                      onClose: onUnzoom,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Card ─────────────────────────────────────────────────────────────

class _CardWidget extends StatefulWidget {
  const _CardWidget({
    required this.item,
    required this.isZoomed,
    required this.zoomAnim,
    required this.onBodyTap,
    required this.onClose,
  });

  final BlockItem item;
  final bool isZoomed;
  final Animation<double> zoomAnim;
  final VoidCallback onBodyTap, onClose;

  @override
  State<_CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<_CardWidget> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isZoomed) {
      return AnimatedBuilder(
        animation: widget.zoomAnim,
        builder: (_, __) => _buildCard(zoomed: true, t: widget.zoomAnim.value),
      );
    }
    return _buildCard(zoomed: false, t: 0);
  }

  Widget _buildCard({required bool zoomed, required double t}) {
    final isHero = widget.item.priority >= 8;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: zoomed ? null : widget.onBodyTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          transform: zoomed
              ? (Matrix4.identity()..scale(1.0 + 0.02 * t))
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_cardTop, _cardBot],
            ),
            border: Border.all(
              color: zoomed
                  ? _teal.withValues(alpha: 0.35)
                  : (_h ? _cardBorderHover : _cardBorder),
              width: zoomed ? 1.4 : (_h ? 1.2 : 1.0),
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: zoomed ? 0.6 : 0.4),
                blurRadius: zoomed ? 28 : 16,
                offset: Offset(0, zoomed ? 10 : 6),
              ),
              if (zoomed)
                BoxShadow(
                    color: _teal.withValues(alpha: 0.06),
                    blurRadius: 50),
              if (_h && !zoomed)
                BoxShadow(
                    color: _teal.withValues(alpha: 0.04),
                    blurRadius: 28),
            ],
          ),
          padding: EdgeInsets.all(isHero ? 22 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header — zoomed has close button.
              if (zoomed) ...[
                Row(
                  children: [
                    _Sigil(size: 36, hovered: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.item.tealLabel != null)
                            Text(widget.item.tealLabel!,
                                style: const TextStyle(
                                    fontFamily: 'Avenir',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: _teal,
                                    letterSpacing: 1.2)),
                          const SizedBox(height: 2),
                          Text(
                            widget.item.title.replaceAll('\n', ' '),
                            style: TextStyle(
                              fontFamily:
                                  isHero ? 'GoudyHeavyface' : 'Avenir',
                              fontSize: isHero ? 18 : 15,
                              fontWeight: isHero
                                  ? FontWeight.w400
                                  : FontWeight.w700,
                              color: _cream,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _CloseBtn(onTap: widget.onClose),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                      height: 1,
                      color: _quiet.withValues(alpha: 0.12)),
                ),
              ] else ...[
                // Normal header.
                _Sigil(size: isHero ? 42 : 34, hovered: _h),
                SizedBox(height: isHero ? 12 : 10),
                if (widget.item.tealLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(widget.item.tealLabel!,
                        style: const TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _teal,
                            letterSpacing: 1.3)),
                  ),
                Text(
                  widget.item.title,
                  style: TextStyle(
                    fontFamily: isHero ? 'GoudyHeavyface' : 'Avenir',
                    fontSize: isHero ? 19 : 14,
                    fontWeight:
                        isHero ? FontWeight.w400 : FontWeight.w700,
                    color: _cream,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Description.
              if (widget.item.description != null) ...[
                SizedBox(height: zoomed ? 10 : 6),
                Text(
                  widget.item.description!,
                  style: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: zoomed ? 13 : 12,
                    color: _muted,
                    height: 1.5,
                  ),
                  maxLines: zoomed ? 10 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Quote — expanded content (only when zoomed).
              if (zoomed && widget.item.quoteText != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _cardSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(
                          color: _gold.withValues(alpha: 0.4),
                          width: 3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.item.quoteFrom != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(widget.item.quoteFrom!,
                              style: TextStyle(
                                  fontFamily: 'Avenir',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      _gold.withValues(alpha: 0.65),
                                  letterSpacing: 0.8)),
                        ),
                      Text('"${widget.item.quoteText!}"',
                          style: TextStyle(
                              fontFamily: 'Avenir',
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color:
                                  _cream.withValues(alpha: 0.65),
                              height: 1.5)),
                    ],
                  ),
                ),
              ],

              // Extra buttons — only when zoomed.
              if (zoomed && widget.item.buttons.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 7,
                  children: [
                    for (final b in widget.item.buttons)
                      _Btn(button: b),
                  ],
                ),
              ],

              // Activity.
              if (widget.item.activityText != null) ...[
                SizedBox(height: zoomed ? 12 : 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: _green, blurRadius: 4)
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(widget.item.activityText!,
                          style: const TextStyle(
                              fontFamily: 'Avenir',
                              fontSize: 11,
                              color: _muted),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],

              // Bottom action button.
              if (widget.item.bottomButtonLabel != null) ...[
                SizedBox(height: zoomed ? 14 : 10),
                _ActionBtn(
                  label: widget.item.bottomButtonLabel!,
                  onTap: widget.item.onBottomButtonTap,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────

class _Sigil extends StatelessWidget {
  const _Sigil({required this.size, required this.hovered});
  final double size;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          _gold.withValues(alpha: hovered ? 0.32 : 0.16),
          _gold.withValues(alpha: 0.01),
        ]),
        border: Border.all(
            color: _gold.withValues(alpha: hovered ? 0.55 : 0.25),
            width: 1.5),
        boxShadow: [
          BoxShadow(
              color: _goldLight
                  .withValues(alpha: hovered ? 0.18 : 0.05),
              blurRadius: hovered ? 18 : 8),
        ],
      ),
      child: Icon(Icons.auto_awesome,
          size: size * 0.44, color: _goldLight),
    );
  }
}

class _CloseBtn extends StatefulWidget {
  const _CloseBtn({required this.onTap});
  final VoidCallback onTap;
  @override
  State<_CloseBtn> createState() => _CloseBtnState();
}

class _CloseBtnState extends State<_CloseBtn> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _h
                ? _cream.withValues(alpha: 0.08)
                : _cream.withValues(alpha: 0.03),
            border: Border.all(
                color: _h ? _quiet : _quiet.withValues(alpha: 0.25)),
          ),
          child: Icon(Icons.close_rounded,
              size: 14,
              color: _h
                  ? _cream.withValues(alpha: 0.7)
                  : _muted.withValues(alpha: 0.4)),
        ),
      ),
    );
  }
}

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
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: p
                ? (_h
                    ? _teal.withValues(alpha: 0.85)
                    : _teal)
                : (_h
                    ? _cream.withValues(alpha: 0.05)
                    : Colors.transparent),
            border: p
                ? null
                : Border.all(
                    color: _h
                        ? _teal.withValues(alpha: 0.4)
                        : _quiet.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.button.label,
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: p
                  ? const Color(0xFF0C0914)
                  : (_h
                      ? _teal
                      : _cream.withValues(alpha: 0.8)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  const _ActionBtn({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _h
                ? _teal.withValues(alpha: 0.14)
                : _teal.withValues(alpha: 0.05),
            border: Border.all(
                color: _h
                    ? _teal.withValues(alpha: 0.45)
                    : _teal.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:
                  _h ? _teal : _teal.withValues(alpha: 0.7),
            ),
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
    final gp = Paint()..color = _goldLight.withValues(alpha: 0.18);
    final tp = Paint()..color = _teal.withValues(alpha: 0.1);
    for (int i = 0; i < 120; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width,
            rng.nextDouble() * size.height),
        rng.nextDouble() * 2.0 + 0.3,
        rng.nextBool() ? gp : tp,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

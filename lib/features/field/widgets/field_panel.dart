import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// Display modes for a [FieldPanel], mirroring the prototype panel contract.
enum FieldPanelMode { expanded, collapsed, minimized }

/// A movable Field panel — the common chrome shared by Navigation, Compute,
/// Inspect, Possible Actions, and the working panels.
///
/// Reproduces the prototype `.fieldPanel`: a warm translucent surface with a
/// draggable chrome header carrying close/collapse, minimize, and expand
/// controls. It must be a direct child of a [Stack]; it positions itself and
/// clamps dragging within [bounds]. [opacity] is driven by the Field-focus
/// control (0–1); at 0 the panel is present but non-interactive.
class FieldPanel extends StatefulWidget {
  const FieldPanel({
    super.key,
    required this.label,
    required this.bounds,
    required this.child,
    this.summary,
    this.width,
    this.initialOffset = const Offset(24, 24),
    this.initialMode = FieldPanelMode.expanded,
    this.opacity = 1,
    this.accent = false,
    this.onClose,
  });

  /// Full panel title, shown when expanded.
  final String label;

  /// Available area used to clamp dragging.
  final Size bounds;

  /// Panel body, shown only when expanded.
  final Widget child;

  /// Short title shown when collapsed or minimized; defaults to [label].
  final String? summary;

  /// Fixed panel width; when null the panel sizes to its content.
  final double? width;

  final Offset initialOffset;
  final FieldPanelMode initialMode;
  final double opacity;

  /// When true the panel uses the gold emphasis border + glow (Possible
  /// Actions).
  final bool accent;

  /// When provided the first control is Close (removing the panel); otherwise
  /// it is Collapse.
  final VoidCallback? onClose;

  @override
  State<FieldPanel> createState() => _FieldPanelState();
}

class _FieldPanelState extends State<FieldPanel> {
  late FieldPanelMode _mode = widget.initialMode;
  late Offset _offset = widget.initialOffset;

  void _drag(Offset delta) {
    if (_mode == FieldPanelMode.minimized) {
      return;
    }
    setState(() {
      final width = widget.width ?? 260;
      final maxLeft = (widget.bounds.width - width - 8).clamp(
        8.0,
        double.infinity,
      );
      final maxTop = (widget.bounds.height - 48).clamp(8.0, double.infinity);
      _offset = Offset(
        (_offset.dx + delta.dx).clamp(8.0, maxLeft),
        (_offset.dy + delta.dy).clamp(8.0, maxTop),
      );
    });
  }

  void _setMode(FieldPanelMode mode) {
    setState(() {
      if (mode == FieldPanelMode.expanded) {
        final width = widget.width ?? 260;
        _offset = Offset(
          ((widget.bounds.width - width) / 2).clamp(8.0, double.infinity),
          (widget.bounds.height * 0.16).clamp(8.0, double.infinity),
        );
      }
      _mode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final metrics = context.metrics;
    final radius = BorderRadius.circular(metrics.radiusPanel);
    final panel = Container(
      width: widget.width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.raised.withValues(alpha: 0.94),
            colors.surface.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(
          color: widget.accent
              ? colors.gold.withValues(alpha: 0.48)
              : colors.camel.withValues(alpha: 0.3),
        ),
        borderRadius: radius,
        boxShadow: [
          const BoxShadow(
            color: Color(0x6B000000),
            blurRadius: 52,
            offset: Offset(0, 18),
          ),
          if (widget.accent)
            BoxShadow(
              color: colors.gold.withValues(alpha: 0.06),
              blurRadius: 28,
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelChrome(
            title: _mode == FieldPanelMode.expanded
                ? widget.label
                : (widget.summary ?? widget.label),
            emphasised: _mode != FieldPanelMode.expanded,
            onDrag: _drag,
            onFirst: widget.onClose ?? () => _setMode(FieldPanelMode.collapsed),
            firstIsClose: widget.onClose != null,
            onMinimize: () => _setMode(FieldPanelMode.minimized),
            onExpand: () => _setMode(FieldPanelMode.expanded),
          ),
          if (_mode == FieldPanelMode.expanded)
            Padding(padding: const EdgeInsets.all(2), child: widget.child),
        ],
      ),
    );

    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: IgnorePointer(
        ignoring: widget.opacity == 0,
        child: Opacity(
          opacity: widget.opacity,
          child: Semantics(
            container: true,
            label: widget.label,
            child: ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: panel,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelChrome extends StatelessWidget {
  const _PanelChrome({
    required this.title,
    required this.emphasised,
    required this.onDrag,
    required this.onFirst,
    required this.firstIsClose,
    required this.onMinimize,
    required this.onExpand,
  });

  final String title;
  final bool emphasised;
  final ValueChanged<Offset> onDrag;
  final VoidCallback onFirst;
  final bool firstIsClose;
  final VoidCallback onMinimize;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return MouseRegion(
      cursor: SystemMouseCursors.move,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) => onDrag(details.delta),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: colors.deep.withValues(alpha: 0.35),
            border: Border(
              bottom: BorderSide(color: colors.camel.withValues(alpha: 0.13)),
            ),
          ),
          child: Row(
            children: [
              _ChromeButton(
                glyph: firstIsClose ? '×' : '‹',
                tooltip: firstIsClose ? 'Close' : 'Collapse',
                onTap: onFirst,
              ),
              const SizedBox(width: 4),
              _ChromeButton(glyph: '–', tooltip: 'Minimize', onTap: onMinimize),
              const SizedBox(width: 4),
              _ChromeButton(glyph: '↗', tooltip: 'Expand', onTap: onExpand),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.kidunaText.labelStrong.copyWith(
                    color: emphasised ? colors.cream : colors.muted,
                  ),
                ),
              ),
              Text(
                '⋮⋮',
                style: context.kidunaText.micro.copyWith(
                  color: colors.quiet.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChromeButton extends StatelessWidget {
  const _ChromeButton({
    required this.glyph,
    required this.tooltip,
    required this.onTap,
  });

  final String glyph;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final size = context.metrics.panelControl;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.cream.withValues(alpha: 0.025),
              shape: BoxShape.circle,
              border: Border.all(color: colors.camel.withValues(alpha: 0.22)),
            ),
            child: Text(
              glyph,
              style: TextStyle(color: colors.muted, fontSize: 10, height: 1),
            ),
          ),
        ),
      ),
    );
  }
}

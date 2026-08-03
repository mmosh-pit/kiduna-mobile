/// Where you are in the Field, and how to get to the next orbits.
///
/// Not paging. The whole Field is always present — this shows which part of it
/// the viewport is looking at, and moves the viewport. Every orbit keeps its
/// place, so returning to one means returning to *where it was*.
///
/// > the member can always **pan and zoom to any orbit** and override the
/// > arrangement — `taxonomy.md` §22
library;

import 'package:flame/components.dart' show Vector2;
import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../design/typography.dart';
import '../field/models.dart';

class FieldNavigator extends StatelessWidget {
  const FieldNavigator({
    required this.clusters,
    required this.viewport,
    required this.visibleFraction,
    required this.onJump,
    required this.onStep,
    super.key,
  });

  /// Every orbit in the Field — including the ones currently off-screen.
  final List<ClusterDef> clusters;

  /// Where the viewport sits, 0–1 on each axis.
  final Vector2 viewport;

  /// How much of the Field the viewport covers, 0–1 on each axis.
  final Size visibleFraction;

  final ValueChanged<Vector2> onJump;
  final void Function(int dx, int dy) onStep;

  static const _w = 300.0;
  static const _h = 92.0;

  @override
  Widget build(BuildContext context) {
    final named = clusters.where((c) => !c.isBranch).toList();
    final inView = named.where(_isInView).length;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 24,
      child: Center(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Enamel.warmSurface.withValues(alpha: 0.94),
            border: Border.all(color: Enamel.raisedUmber),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Arrow('‹', () => onStep(-1, 0)),
              const SizedBox(width: 12),
              Column(
                children: [
                  SizedBox(
                    width: _w,
                    height: _h,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) => _jumpFrom(d.localPosition),
                      onPanUpdate: (d) => _jumpFrom(d.localPosition),
                      child: CustomPaint(
                        painter: _MapPainter(
                          clusters: named,
                          viewport: viewport,
                          visibleFraction: visibleFraction,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '$inView OF ${named.length} ORBITS IN VIEW  ·  '
                    'DRAG THE MAP, OR PAN THE FIELD',
                    style: Type.eyebrow,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              _Arrow('›', () => onStep(1, 0)),
            ],
          ),
        ),
      ),
    );
  }

  bool _isInView(ClusterDef c) {
    final left = viewport.x * (1 - visibleFraction.width);
    final top = viewport.y * (1 - visibleFraction.height);
    final x = c.left / 100;
    final y = c.top / 100;
    return x >= left &&
        x <= left + visibleFraction.width &&
        y >= top &&
        y <= top + visibleFraction.height;
  }

  void _jumpFrom(Offset local) {
    // The tap point is the centre of the desired viewport, so the arithmetic
    // undoes the inset the viewport rectangle occupies.
    final fx = ((local.dx / _w) - visibleFraction.width / 2) /
        (1 - visibleFraction.width).clamp(0.0001, 1.0);
    final fy = ((local.dy / _h) - visibleFraction.height / 2) /
        (1 - visibleFraction.height).clamp(0.0001, 1.0);
    onJump(Vector2(fx.clamp(0.0, 1.0), fy.clamp(0.0, 1.0)));
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow(this.glyph, this.onTap);

  final String glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Enamel.skyBlue.withValues(alpha: 0.55)),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            glyph,
            style: Type.heading.copyWith(fontSize: 17, color: Enamel.skyBlue),
          ),
        ),
      );
}

/// The whole Field at a glance: every orbit as a dot in its own accent, and a
/// rectangle for what the viewport currently holds.
class _MapPainter extends CustomPainter {
  const _MapPainter({
    required this.clusters,
    required this.viewport,
    required this.visibleFraction,
  });

  final List<ClusterDef> clusters;
  final Vector2 viewport;
  final Size visibleFraction;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Enamel.deepField,
    );

    for (final c in clusters) {
      final centre = Offset(c.left / 100 * size.width, c.top / 100 * size.height);
      final r = c.radiusX / 100 * size.width * 0.9;
      canvas.drawOval(
        Rect.fromCenter(center: centre, width: r * 2, height: r * 1.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..color = c.accent.withValues(alpha: 0.42),
      );
      canvas.drawCircle(centre, 1.6, Paint()..color = c.accent);
    }

    // What the viewport currently holds.
    final w = visibleFraction.width.clamp(0.05, 1.0) * size.width;
    final h = visibleFraction.height.clamp(0.05, 1.0) * size.height;
    final left = viewport.x * (size.width - w);
    final top = viewport.y * (size.height - h);
    final rect = Rect.fromLTWH(left, top, w, h);

    canvas.drawRect(rect, Paint()..color = Enamel.cream.withValues(alpha: 0.05));
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Enamel.cream.withValues(alpha: 0.62),
    );
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.viewport != viewport || old.visibleFraction != visibleFraction;
}

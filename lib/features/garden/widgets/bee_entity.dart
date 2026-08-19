import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/bee_manifest.dart';

/// An animated bee entity on the Apiary scene.
///
/// Renders a sprite sheet crawl-loop at the given position. Tappable
/// to show task details. When selected, animation pauses and a
/// highlight ring appears.
class BeeEntity extends StatefulWidget {
  const BeeEntity({
    super.key,
    required this.beeType,
    required this.headingDeg,
    required this.size,
    required this.isSelected,
    required this.onTap,
  });

  final BeeType beeType;
  final double headingDeg;
  final double size;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<BeeEntity> createState() => _BeeEntityState();
}

class _BeeEntityState extends State<BeeEntity>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  ui.Image? _sheet;
  int _frame = 0;

  @override
  void initState() {
    super.initState();
    _frame = math.Random().nextInt(widget.beeType.loopEnd + 1);

    _ticker = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (1000 / widget.beeType.fps).round(),
      ),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && !widget.isSelected) {
          _frame = (_frame + 1) % (widget.beeType.loopEnd + 1);
          _ticker.forward(from: 0);
          if (_sheet != null) setState(() {});
        }
      });

    _loadSheet();
  }

  Future<void> _loadSheet() async {
    // Use Flutter's ImageProvider which handles path resolution correctly
    // across web, desktop, and mobile.
    final provider = AssetImage(widget.beeType.spriteSheet);
    final stream = provider.resolve(ImageConfiguration.empty);
    stream.addListener(ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(() {
          _sheet = info.image;
        });
        if (!widget.isSelected) _ticker.forward();
      },
      onError: (error, stackTrace) {
        debugPrint('Failed to load sprite: ${widget.beeType.spriteSheet} - $error');
      },
    ));
  }

  @override
  void didUpdateWidget(BeeEntity oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _ticker.stop();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _ticker.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Selection ring.
              if (widget.isSelected)
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFDAB875).withValues(alpha: 0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDAB875).withValues(alpha: 0.15),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),

              // Contact shadow.
              Positioned(
                bottom: 2,
                child: Container(
                  width: widget.size * 0.45,
                  height: widget.size * 0.12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

              // Sprite frame.
              Transform.rotate(
                angle: widget.headingDeg * (math.pi / 180),
                child: _sheet != null
                    ? CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: _SpriteFramePainter(
                          sheet: _sheet!,
                          frame: _frame,
                          columns: widget.beeType.columns,
                          frameWidth: widget.beeType.frameWidth,
                          frameHeight: widget.beeType.frameHeight,
                        ),
                      )
                    : _fallback(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: widget.size * 0.7,
      height: widget.size * 0.7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1A1508),
        border: Border.all(
          color: const Color(0xFFDAB875).withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Icon(
        Icons.bug_report_outlined,
        color: const Color(0xFFDAB875).withValues(alpha: 0.6),
        size: widget.size * 0.3,
      ),
    );
  }
}

/// Paints a single frame from a sprite sheet.
class _SpriteFramePainter extends CustomPainter {
  _SpriteFramePainter({
    required this.sheet,
    required this.frame,
    required this.columns,
    required this.frameWidth,
    required this.frameHeight,
  });

  final ui.Image sheet;
  final int frame;
  final int columns;
  final int frameWidth;
  final int frameHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final col = frame % columns;
    final row = frame ~/ columns;

    final src = Rect.fromLTWH(
      (col * frameWidth).toDouble(),
      (row * frameHeight).toDouble(),
      frameWidth.toDouble(),
      frameHeight.toDouble(),
    );

    final dst = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(
      sheet, src, dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_SpriteFramePainter old) => old.frame != frame;
}
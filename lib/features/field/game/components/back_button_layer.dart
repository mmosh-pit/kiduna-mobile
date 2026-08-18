import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../enamel_tokens.dart';
import '../field_typography.dart';
import 'star_layer.dart';

class BackButtonLayer extends PositionComponent {
  BackButtonLayer() : super(priority: 950);

  double opacity = 0;
  StaticStar? star;
  int realmCount = 0;

  static const _padLeft = 24.0;
  static const _padTop = 24.0;
  static const _panelPadH = 16.0;
  static const _panelPadV = 12.0;

  String? _builtFor;
  TextPainter? _backPainter;
  TextPainter? _titlePainter;
  TextPainter? _subtitlePainter;
  double _panelWidth = 0;
  double _panelHeight = 0;

  Rect get _backRect =>
      Rect.fromLTWH(_padLeft, _padTop, _panelWidth, _panelHeight);

  String? tapAt(Vector2 viewportPoint) {
    if (opacity < 0.5 || star == null) {
      return null;
    }
    if (_backRect.inflate(8).contains(viewportPoint.toOffset())) {
      return 'back';
    }
    return null;
  }

  void _build() {
    if (star == null) {
      return;
    }
    final key = '${star!.id}_$realmCount';
    if (_builtFor == key) {
      return;
    }
    _builtFor = key;
    final accent = star!.accent;

    _backPainter = TextPainter(
      text: TextSpan(
        text: '←  BACK TO ATLAS',
        style: TextStyle(
          fontFamily: Type.eyebrow.fontFamily,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 1.6,
          color: accent,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    _titlePainter = TextPainter(
      text: TextSpan(
        text: star!.label.toUpperCase(),
        style: TextStyle(
          fontFamily: Type.realmName.fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 24,
          letterSpacing: 1.0,
          color: Enamel.cream,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    _subtitlePainter = TextPainter(
      text: TextSpan(
        text: '$realmCount Realms',
        style: TextStyle(
          fontFamily: Type.body.fontFamily,
          fontSize: 12,
          color: Enamel.camel,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final maxTextW = [
      _backPainter!.width,
      _titlePainter!.width,
      _subtitlePainter!.width,
    ].reduce((a, b) => a > b ? a : b);

    _panelWidth = maxTextW + _panelPadH * 2;
    _panelHeight = 11 + 8 + 24 + 6 + 12 + 8 + 2 + _panelPadV * 2;
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0.01 || star == null) {
      return;
    }
    _build();

    final useFade = opacity < 1;
    if (useFade) {
      canvas.saveLayer(
        null,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: opacity),
      );
    }

    final panelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(_padLeft, _padTop, _panelWidth, _panelHeight),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      panelRect,
      Paint()..color = Enamel.deepEspresso.withValues(alpha: 0.85),
    );
    canvas.drawRRect(
      panelRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = star!.accent.withValues(alpha: 0.3),
    );

    const tx = _padLeft + _panelPadH;
    var ty = _padTop + _panelPadV;

    _backPainter?.paint(canvas, Offset(tx, ty));
    ty += 11 + 8;

    _titlePainter?.paint(canvas, Offset(tx, ty));
    ty += 24 + 6;

    _subtitlePainter?.paint(canvas, Offset(tx, ty));
    ty += 12 + 8;

    canvas.drawRect(
      Rect.fromLTWH(tx, ty, 40, 2),
      Paint()..color = star!.accent.withValues(alpha: 0.6),
    );

    if (useFade) {
      canvas.restore();
    }
  }
}

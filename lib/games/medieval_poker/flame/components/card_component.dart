import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import 'package:medieval_poker_engine/medieval_poker_engine.dart';
import 'package:medieval_poker_engine/protocol.dart';
import '../../session/card_zoom.dart';
import '../poker_assets.dart';

/// Renders a single playing card, face-up or face-down. Uses the themed card
/// art from [PokerCardAtlas] when available, and falls back to drawn cards.
class CardComponent extends PositionComponent {
  PlayingCard? card;
  bool faceUp;

  /// Shared card art. When null (or a sprite is missing), cards are drawn.
  PokerCardAtlas? atlas;

  /// 0..1 — cards for folded/empty seats are drawn dimmed.
  double opacity = 1.0;

  CardComponent({
    this.card,
    this.faceUp = false,
    this.atlas,
    super.position,
    Vector2? size,
  }) : super(size: size ?? Vector2(46, 64), anchor: Anchor.topLeft);

  /// Apply a wire [CardCode] (used by the snapshot-driven online renderer).
  /// `null` or [CardCode.hidden] ("??") renders a face-down back; any other
  /// code decodes to the real card and shows it face-up.
  void applyCode(String? code) {
    if (code == null || code == CardCode.hidden) {
      card = null;
      faceUp = false;
    } else {
      card = CardCode.decode(code);
      faceUp = true;
    }
  }

  static const _cornerRadius = 6.0;
  static const _backColor = Color(0xFF5A1E1E);
  static const _backBorder = Color(0xFFC8A24B);
  static const _faceColor = Color(0xFFF7F1E1);
  static const _faceBorder = Color(0xFF2A2A2A);

  @override
  void render(Canvas canvas) {
    final dimmed = opacity < 0.999;
    if (dimmed) {
      canvas.saveLayer(
        Offset.zero & Size(width, height),
        Paint()..color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0)),
      );
    }

    final rect = RRect.fromRectAndRadius(
      Offset.zero & Size(width, height),
      const Radius.circular(_cornerRadius),
    );

    // Drop shadow for depth.
    canvas.drawRRect(
      rect.shift(const Offset(0, 1.5)),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    // Prefer themed art; fall back to drawn cards if unavailable.
    final sprite = _spriteFor();
    if (sprite != null) {
      _renderSprite(canvas, rect, sprite);
    } else if (!faceUp || card == null) {
      _renderBack(canvas, rect);
    } else if (card!.isItem) {
      _renderItem(canvas, rect, card!);
    } else if (card!.isJoker) {
      _renderJoker(canvas, rect);
    } else {
      _renderFace(canvas, rect, card!);
    }

    if (dimmed) canvas.restore();
  }

  Sprite? _spriteFor() {
    final a = atlas;
    if (a == null || !a.loaded) return null;
    if (!faceUp || card == null) return a.back;
    return a.faceFor(card!);
  }

  void _renderSprite(Canvas canvas, RRect rect, Sprite sprite) {
    canvas.save();
    canvas.clipRRect(rect);
    sprite.render(canvas, size: Vector2(width, height));
    canvas.restore();
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = const Color(0x552A2A2A),
    );
  }

  void _renderBack(Canvas canvas, RRect rect) {
    canvas.drawRRect(rect, Paint()..color = _backColor);
    canvas.drawRRect(
      rect.deflate(3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = _backBorder,
    );
    // Simple gold diamond emblem.
    final cx = width / 2;
    final cy = height / 2;
    final path = Path()
      ..moveTo(cx, cy - 10)
      ..lineTo(cx + 8, cy)
      ..lineTo(cx, cy + 10)
      ..lineTo(cx - 8, cy)
      ..close();
    canvas.drawPath(path, Paint()..color = _backBorder.withValues(alpha: 0.8));
  }

  void _renderItem(Canvas canvas, RRect rect, PlayingCard c) {
    const teal = Color(0xFF1E5A6E);
    canvas.drawRRect(rect, Paint()..color = const Color(0xFFEAF6F9));
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = teal,
    );
    TextPaint(style: TextStyle(color: teal, fontSize: height * 0.26))
        .render(canvas, '◈', Vector2(width / 2, height * 0.32),
            anchor: Anchor.center);
    final name = Items.byId(c.itemId!)?.name ?? 'Item';
    TextPaint(
      style: TextStyle(
        color: teal,
        fontSize: height * 0.1,
        fontWeight: FontWeight.w700,
      ),
    ).render(canvas, name, Vector2(width / 2, height * 0.62),
        anchor: Anchor.center);
  }

  void _renderJoker(Canvas canvas, RRect rect) {
    canvas.drawRRect(rect, Paint()..color = _faceColor);
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF7A3E9D),
    );
    TextPaint(
      style: TextStyle(
        color: const Color(0xFF7A3E9D),
        fontSize: height * 0.30,
      ),
    ).render(canvas, '★', Vector2(width / 2, height * 0.38),
        anchor: Anchor.center);
    TextPaint(
      style: TextStyle(
        color: const Color(0xFF7A3E9D),
        fontSize: height * 0.13,
        fontWeight: FontWeight.w800,
      ),
    ).render(canvas, 'WILD', Vector2(width / 2, height * 0.72),
        anchor: Anchor.center);
  }

  void _renderFace(Canvas canvas, RRect rect, PlayingCard c) {
    canvas.drawRRect(rect, Paint()..color = _faceColor);
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = _faceBorder,
    );

    final color = c.suit.isRed ? const Color(0xFFB3261E) : const Color(0xFF1A1A1A);

    final corner = TextPaint(
      style: TextStyle(
        color: color,
        fontSize: height * 0.22,
        fontWeight: FontWeight.w700,
        height: 1.0,
      ),
    );
    corner.render(canvas, c.rankLabel, Vector2(4, 3));

    final center = TextPaint(
      style: TextStyle(color: color, fontSize: height * 0.42),
    );
    center.render(
      canvas,
      c.suit.glyph,
      Vector2(width / 2, height / 2),
      anchor: Anchor.center,
    );
  }
}

/// A [CardComponent] you can tap to enlarge (via a shared [CardZoomController]).
/// Used by the snapshot-driven online table; the legacy offline game keeps the
/// plain non-tappable [CardComponent], so its behaviour is unchanged. Only a
/// face-up, real card zooms — tapping a face-down back or empty slot does
/// nothing.
class ZoomableCardComponent extends CardComponent with TapCallbacks {
  final CardZoomController? cardZoom;

  ZoomableCardComponent({
    this.cardZoom,
    super.card,
    super.faceUp,
    super.atlas,
    super.position,
    super.size,
  });

  @override
  void onTapUp(TapUpEvent event) => zoomOnTap();

  /// Enlarge this card if it's a face-up real card (via [cardZoom]); returns
  /// whether it zoomed. Split from [onTapUp] so the logic is unit-testable
  /// without synthesizing a Flame tap event.
  @visibleForTesting
  bool zoomOnTap() {
    final z = cardZoom;
    final c = card;
    if (z == null || c == null || !faceUp) return false;
    z.show(_zoomTarget(c));
    return true;
  }

  CardZoomTarget _zoomTarget(PlayingCard c) {
    if (c.isItem) {
      final name = Items.byId(c.itemId!)?.name ?? 'Item';
      return CardZoomTarget(
        assets: ['assets/medieval_poker/items/${c.itemId}.png'],
        title: name,
        fallback: '◈',
      );
    }
    if (c.isJoker) {
      return const CardZoomTarget(
        assets: ['assets/medieval_poker/cards/joker.png'],
        title: 'Joker · Wild',
        fallback: '★',
      );
    }
    final key = PokerCardAtlas.assetKeyForCard(c);
    final s = c.suit.name; // clubs / diamonds / hearts / spades
    final suitTitle = '${s[0].toUpperCase()}${s.substring(1)}';
    return CardZoomTarget(
      assets: ['assets/medieval_poker/cards/$key.png'],
      title: '${c.rankLabel} of $suitTitle',
      fallback: '${c.rankLabel}${c.suit.glyph}',
    );
  }
}

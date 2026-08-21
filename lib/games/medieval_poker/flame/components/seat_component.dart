import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'package:medieval_poker_engine/medieval_poker_engine.dart';
import '../poker_assets.dart';
import 'card_component.dart';

/// Renders one player's seat: their hole cards, a name/stack plate, dealer
/// button, last-action label, and an "it's your turn" highlight.
class SeatComponent extends PositionComponent {
  final PokerPlayer player;
  final int holeCardCount;
  final Vector2 cardSize;
  final PokerCardAtlas? atlas;

  bool isActing = false;
  bool isDealer = false;

  final List<CardComponent> _cards = [];

  static const _plateHeight = 34.0;
  static const _cardGap = 4.0;

  SeatComponent({
    required this.player,
    required this.holeCardCount,
    this.atlas,
    Vector2? cardSize,
    super.position,
  })  : cardSize = cardSize ?? Vector2(42, 58),
        super(anchor: Anchor.center) {
    final rowWidth =
        holeCardCount * cardSize!.x + (holeCardCount - 1) * _cardGap;
    size = Vector2(
      rowWidth < 130 ? 130 : rowWidth,
      cardSize.y + _plateHeight + 6,
    );
  }

  @override
  Future<void> onLoad() async {
    final rowWidth =
        holeCardCount * cardSize.x + (holeCardCount - 1) * _cardGap;
    // Placeholder empty slots; grown/positioned in sync() once cards deal.
    for (int i = 0; i < holeCardCount; i++) {
      final c = CardComponent(size: cardSize.clone(), atlas: atlas);
      _cards.add(c);
      add(c);
    }
    _positionCards(holeCardCount, rowWidth);
  }

  /// Lay [count] cards across the seat's row width, overlapping when a player
  /// has more than the base number of hole cards (from Power Card effects).
  void _positionCards(int count, double rowWidth) {
    if (count <= 0) return;
    final maxStep = cardSize.x + _cardGap;
    final step = count > 1
        ? ((rowWidth - cardSize.x) / (count - 1)).clamp(cardSize.x * 0.45, maxStep)
        : 0.0;
    final spread = step * (count - 1) + cardSize.x;
    final startX = (width - spread) / 2;
    for (int i = 0; i < count && i < _cards.length; i++) {
      _cards[i].position = Vector2(startX + i * step, 0);
    }
  }

  /// Refresh card faces and visibility from the current player state, growing
  /// the number of rendered cards to match the (possibly extended) hole.
  void sync({bool revealAll = false}) {
    final n = player.eliminated
        ? holeCardCount
        : (player.hole.length > holeCardCount
            ? player.hole.length
            : holeCardCount);
    while (_cards.length < n) {
      final c = CardComponent(size: cardSize.clone(), atlas: atlas);
      _cards.add(c);
      add(c);
    }
    final rowWidth =
        holeCardCount * cardSize.x + (holeCardCount - 1) * _cardGap;
    _positionCards(_cards.length, rowWidth);

    for (int i = 0; i < _cards.length; i++) {
      final hasCard = i < player.hole.length && !player.eliminated;
      _cards[i].card = hasCard ? player.hole[i] : null;
      _cards[i].faceUp = hasCard &&
          (player.isHuman ||
              revealAll ||
              player.showdownHand != null ||
              player.revealedToHuman) &&
          !player.folded;
      _cards[i].opacity = hasCard && !player.folded ? 1.0 : 0.25;
    }
  }

  @override
  void render(Canvas canvas) {
    final plateTop = cardSize.y + 6;
    final plateRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, plateTop, width, _plateHeight),
      const Radius.circular(8),
    );

    // Acting highlight glow.
    if (isActing) {
      canvas.drawRRect(
        plateRect.inflate(3),
        Paint()
          ..color = const Color(0xFFEDC169)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    canvas.drawRRect(
      plateRect,
      Paint()
        ..color = player.folded
            ? const Color(0xFF23201B)
            : const Color(0xFF33291C),
    );
    canvas.drawRRect(
      plateRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = isActing
            ? const Color(0xFFEDC169)
            : const Color(0xFF6B5533),
    );

    final nameStyle = TextStyle(
      color: player.folded ? Colors.white38 : const Color(0xFFF3E7CC),
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );
    TextPaint(style: nameStyle)
        .render(canvas, player.name, Vector2(8, plateTop + 5));

    final stackStyle = TextStyle(
      color: player.folded ? Colors.white24 : const Color(0xFFEDC169),
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    TextPaint(style: stackStyle).render(
      canvas,
      '${player.stack}',
      Vector2(width - 8, plateTop + 5),
      anchor: Anchor.topRight,
    );

    // Dealer button.
    if (isDealer) {
      final c = Offset(width - 10, plateTop - 2);
      canvas.drawCircle(c, 9, Paint()..color = const Color(0xFFF3E7CC));
      TextPaint(
        style: const TextStyle(
          color: Color(0xFF33291C),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ).render(canvas, 'D', Vector2(c.dx, c.dy), anchor: Anchor.center);
    }

    // Status badges (top-left, above the plate).
    if (!player.eliminated) {
      double bx = 0;
      void badge(String text, Color bg, Color fg) {
        final bw = text.length * 6.5 + 12;
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, plateTop - 19, bw, 15),
          const Radius.circular(7),
        );
        canvas.drawRRect(r, Paint()..color = bg);
        TextPaint(
          style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.w800),
        ).render(canvas, text, Vector2(bx + bw / 2, plateTop - 11),
            anchor: Anchor.center);
        bx += bw + 4;
      }

      if (player.heatingUp) {
        badge('🔥 HOT', const Color(0xFFB3401E), const Color(0xFFFFE0A0));
      }
      if (player.tilted) {
        badge('TILT', const Color(0xFF6A1B1B), const Color(0xFFF3C0C0));
      }
      final tokenCount = player.tokens.length + player.courtTokens.length;
      if (tokenCount > 0) {
        badge('◈ $tokenCount', const Color(0xFF3A2A5A),
            const Color(0xFFC79BE6));
      }
      if (player.compChips > 0) {
        badge('◉ ${player.compChips}', const Color(0xFF1E3A4A),
            const Color(0xFF7FD0E0));
      }
    }

    // Last-action label above the plate.
    final label = player.lastActionLabel;
    if (label != null && !player.folded) {
      final tag = RRect.fromRectAndRadius(
        Rect.fromLTWH(width / 2 - 34, plateTop - 20, 68, 16),
        const Radius.circular(8),
      );
      canvas.drawRRect(tag, Paint()..color = const Color(0xCC1B140C));
      TextPaint(
        style: const TextStyle(color: Color(0xFFEDC169), fontSize: 10),
      ).render(canvas, label, Vector2(width / 2, plateTop - 12),
          anchor: Anchor.center);
    }
  }
}

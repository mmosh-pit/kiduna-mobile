import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'package:medieval_poker_engine/protocol.dart';
import '../../session/card_zoom.dart';
import '../poker_assets.dart';
import 'card_component.dart';

/// Renders one seat from a [SeatSnapshot] (the online, server-authoritative
/// view). Visually identical to the offline [SeatComponent], but every field
/// comes from the wire snapshot instead of a live `PokerPlayer`: a hole card is
/// shown face-up iff its code is not [CardCode.hidden] — the server decides
/// what this viewer may see.
class SnapshotSeatComponent extends PositionComponent {
  final int baseHoleCount;
  final Vector2 cardSize;
  final PokerCardAtlas? atlas;

  /// Tapping a face-up hole card enlarges it via this shared controller.
  final CardZoomController? cardZoom;

  SeatSnapshot _seat;

  final List<CardComponent> _cards = [];

  static const _plateHeight = 34.0;
  static const _cardGap = 4.0;

  SnapshotSeatComponent({
    required SeatSnapshot seat,
    required this.baseHoleCount,
    this.atlas,
    this.cardZoom,
    Vector2? cardSize,
    super.position,
  })  : _seat = seat,
        cardSize = cardSize ?? Vector2(42, 58),
        super(anchor: Anchor.center) {
    final rowWidth =
        baseHoleCount * this.cardSize.x + (baseHoleCount - 1) * _cardGap;
    size = Vector2(
      rowWidth < 130 ? 130 : rowWidth,
      this.cardSize.y + _plateHeight + 6,
    );
  }

  int get seat => _seat.seat;

  @override
  Future<void> onLoad() async {
    for (int i = 0; i < baseHoleCount; i++) {
      final c = ZoomableCardComponent(
          size: cardSize.clone(), atlas: atlas, cardZoom: cardZoom);
      _cards.add(c);
      add(c);
    }
    _positionCards(baseHoleCount);
    _sync();
  }

  /// Feed a fresh snapshot for this seat. (Named to avoid Flame's
  /// [Component.update] game-loop tick.)
  void applySnapshot(SeatSnapshot seat) {
    _seat = seat;
    if (isLoaded) _sync();
  }

  void _positionCards(int count) {
    if (count <= 0) return;
    final rowWidth =
        baseHoleCount * cardSize.x + (baseHoleCount - 1) * _cardGap;
    final maxStep = cardSize.x + _cardGap;
    final step = count > 1
        ? ((rowWidth - cardSize.x) / (count - 1))
            .clamp(cardSize.x * 0.45, maxStep)
        : 0.0;
    final spread = step * (count - 1) + cardSize.x;
    final startX = (width - spread) / 2;
    for (int i = 0; i < count && i < _cards.length; i++) {
      _cards[i].position = Vector2(startX + i * step, 0);
    }
  }

  void _sync() {
    final codes = _seat.eliminated ? const <String>[] : _seat.holeCards;
    final n = codes.length > baseHoleCount ? codes.length : baseHoleCount;
    while (_cards.length < n) {
      final c = ZoomableCardComponent(
          size: cardSize.clone(), atlas: atlas, cardZoom: cardZoom);
      _cards.add(c);
      add(c);
    }
    _positionCards(_cards.length);

    for (int i = 0; i < _cards.length; i++) {
      final has = i < codes.length;
      _cards[i].applyCode(has ? codes[i] : null);
      _cards[i].opacity = has && !_seat.folded ? 1.0 : 0.25;
    }
  }

  @override
  void render(Canvas canvas) {
    final s = _seat;
    final plateTop = cardSize.y + 6;
    final plateRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, plateTop, width, _plateHeight),
      const Radius.circular(8),
    );

    if (s.isActing) {
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
        ..color =
            s.folded ? const Color(0xFF23201B) : const Color(0xFF33291C),
    );
    canvas.drawRRect(
      plateRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color =
            s.isActing ? const Color(0xFFEDC169) : const Color(0xFF6B5533),
    );

    TextPaint(
      style: TextStyle(
        color: s.folded ? Colors.white38 : const Color(0xFFF3E7CC),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ).render(canvas, s.name, Vector2(8, plateTop + 5));

    TextPaint(
      style: TextStyle(
        color: s.folded ? Colors.white24 : const Color(0xFFEDC169),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ).render(canvas, '${s.stack}', Vector2(width - 8, plateTop + 5),
        anchor: Anchor.topRight);

    if (s.isDealer) {
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

    if (!s.eliminated) {
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

      if (s.heatingUp) {
        badge('🔥 HOT', const Color(0xFFB3401E), const Color(0xFFFFE0A0));
      }
      if (s.tilted) {
        badge('TILT', const Color(0xFF6A1B1B), const Color(0xFFF3C0C0));
      }
      if (s.tokenCount > 0) {
        badge('◈ ${s.tokenCount}', const Color(0xFF3A2A5A),
            const Color(0xFFC79BE6));
      }
      if (s.compChips > 0) {
        badge('◉ ${s.compChips}', const Color(0xFF1E3A4A),
            const Color(0xFF7FD0E0));
      }
    }

    final label = s.lastAction;
    if (label != null && !s.folded) {
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

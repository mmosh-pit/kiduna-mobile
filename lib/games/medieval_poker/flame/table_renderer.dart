import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'package:medieval_poker_engine/protocol.dart';

import '../session/card_zoom.dart';
import '../session/game_session.dart';
import 'components/snapshot_seat_component.dart';
import 'seat_ring.dart';
import 'components/card_component.dart';
import 'components/table_component.dart';
import 'poker_assets.dart';

/// Renders a Medieval Poker table purely from the [GameSession]'s
/// [TableSnapshot] stream — no engine, no sockets. Used by the online table
/// (and, once the offline path is converged onto a `LocalSession`, by that too).
/// The viewer's own seat is drawn at the bottom; the rest ring the felt.
class TableRenderer extends FlameGame {
  final GameSession session;

  /// Tapping a face-up poker card on the felt enlarges it via this shared
  /// controller (the HUD renders the overlay). Null → cards aren't tap-zoomable.
  final CardZoomController? cardZoom;

  final PokerCardAtlas _cardAtlas = PokerCardAtlas();
  late TableComponent _table;
  final Map<int, SnapshotSeatComponent> _seats = {};
  final List<CardComponent> _board = [];
  late TextComponent _potText;

  bool _ready = false;

  TableRenderer({required this.session, this.cardZoom});

  @override
  Color backgroundColor() => const Color(0xFF14100A);

  @override
  Future<void> onLoad() async {
    await _cardAtlas.load();

    _table = TableComponent();
    await add(_table);

    for (int i = 0; i < 5; i++) {
      final c = ZoomableCardComponent(
        size: Vector2(46, 64),
        atlas: _cardAtlas,
        cardZoom: cardZoom,
      );
      _board.add(c);
      await add(c);
    }

    _potText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFEDC169),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      anchor: Anchor.center,
    );
    await add(_potText);

    _ready = true;
    session.table.addListener(_onTable);
    final current = session.table.value;
    if (current != null) await _apply(current);
    _layout();
  }

  @override
  void onRemove() {
    session.table.removeListener(_onTable);
    super.onRemove();
  }

  void _onTable() {
    final snap = session.table.value;
    if (snap != null) _apply(snap);
  }

  Future<void> _apply(TableSnapshot snap) async {
    if (!_ready) return;

    // Build the seat components once we learn the table shape.
    if (_seats.isEmpty && snap.seats.isNotEmpty) {
      for (final s in snap.seats) {
        final isViewer = s.seat == session.viewerSeat;
        final seat = SnapshotSeatComponent(
          seat: s,
          baseHoleCount: 3,
          atlas: _cardAtlas,
          cardZoom: cardZoom,
          cardSize: isViewer ? Vector2(48, 66) : Vector2(40, 56),
        );
        _seats[s.seat] = seat;
        await add(seat);
      }
      _layout();
    }

    for (final s in snap.seats) {
      _seats[s.seat]?.applySnapshot(s);
    }

    for (int i = 0; i < _board.length; i++) {
      final has = i < snap.board.length;
      _board[i].applyCode(has ? snap.board[i] : null);
      _board[i].opacity = has ? 1.0 : 0.18;
    }
    _potText.text = 'Pot  ${snap.pot}';
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_ready) _layout();
  }

  void _layout() {
    final w = size.x;
    final h = size.y;
    final cx = w / 2;
    final cy = h * 0.42;

    // Scale cards/seats/pot up on larger (desktop/web) windows so the felt reads
    // well in landscape. 1.0 on phones (layout unchanged), capped so it stays
    // sensible; everything below reduces to the phone layout at scale 1.0.
    final scale = (min(w, h) / 420).clamp(1.0, 1.7);

    final fx = (w * 0.46).clamp(120.0, w / 2 - 8);
    final fy = (h * 0.24).clamp(90.0, h * 0.30);
    _table.position = Vector2(cx, cy);
    _table.size = Vector2(fx * 2, fy * 2);

    final ringX = w * 0.37;
    final ringY = fy + 62 * scale;
    final topReserve = 46.0 * scale;
    final bottomReserve = 92.0 * scale;

    // Viewer sits at the bottom (90°); the remaining seats spread evenly across
    // the top arc, symmetric and never overlapping the bottom slot.
    final others = _seats.keys.where((s) => s != session.viewerSeat).toList()
      ..sort();
    final m = others.length;
    void place(SnapshotSeatComponent seat, double sx, double sy) {
      seat.scale = Vector2.all(scale);
      final hw = seat.width * scale / 2;
      final hh = seat.height * scale / 2;
      seat.position = Vector2(
        sx.clamp(hw + 4, w - hw - 4),
        sy.clamp(topReserve + hh, h - bottomReserve - hh),
      );
    }

    final ring = SeatRing(
      centreX: cx,
      centreY: cy,
      radiusX: ringX,
      radiusY: ringY,
      viewerDrop: fy * 0.52,
    );

    final me = _seats[session.viewerSeat];
    if (me != null) place(me, ring.viewer.x, ring.viewer.y);
    for (int k = 0; k < m; k++) {
      final slot = ring.opponent(k, m);
      place(_seats[others[k]]!, slot.x, slot.y);
    }

    final cardW = 46.0 * scale;
    final cardH = 64.0 * scale;
    final gap = 6.0 * scale;
    final boardW = _board.length * cardW + (_board.length - 1) * gap;
    final startX = cx - boardW / 2;
    final boardY = cy - cardH / 2;
    for (int k = 0; k < _board.length; k++) {
      _board[k].size = Vector2(cardW, cardH);
      _board[k].position = Vector2(startX + k * (cardW + gap), boardY);
    }
    _potText.scale = Vector2.all(scale);
    _potText.position = Vector2(cx, cy + 46 * scale);
  }
}

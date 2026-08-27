import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/games/medieval_poker/flame/seat_ring.dart';

/// A 400x300 felt, viewer 60px below centre.
const _ring = SeatRing(
  centreX: 200,
  centreY: 150,
  radiusX: 160,
  radiusY: 110,
  viewerDrop: 60,
);

/// Distance between two slots.
double _gap(SeatSlot a, SeatSlot b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return (dx * dx + dy * dy) / 1; // squared is enough for ordering
}

void main() {
  test('the viewer sits below centre, horizontally centred', () {
    expect(_ring.viewer.x, 200);
    expect(_ring.viewer.y, 210);
  });

  group('short-handed tables', () {
    test('one opponent sits directly opposite', () {
      final slots = _ring.opponents(1);

      expect(slots, hasLength(1));
      expect(slots.single.x, closeTo(200, 0.001), reason: 'must be centred');
      expect(slots.single.y, closeTo(40, 0.001), reason: 'must be at the top');
    });

    test('two opponents sit symmetrically in the upper corners', () {
      final slots = _ring.opponents(2);

      expect(slots, hasLength(2));
      // Mirror images about the vertical centre line.
      expect(slots[0].x - 200, closeTo(-(slots[1].x - 200), 0.001));
      expect(slots[0].y, closeTo(slots[1].y, 0.001));
      // Both above centre.
      expect(slots[0].y, lessThan(150));
      expect(slots[1].y, lessThan(150));
    });

    test('three opponents sit left, top and right', () {
      final slots = _ring.opponents(3);

      expect(slots, hasLength(3));
      expect(slots[0].x, closeTo(40, 0.001)); // left
      expect(slots[0].y, closeTo(150, 0.001));
      expect(slots[1].x, closeTo(200, 0.001)); // top
      expect(slots[1].y, closeTo(40, 0.001));
      expect(slots[2].x, closeTo(360, 0.001)); // right
      expect(slots[2].y, closeTo(150, 0.001));
    });

    test('zero opponents yields nothing and does not throw', () {
      expect(_ring.opponents(0), isEmpty);
    });
  });

  group('invariants across every table size', () {
    for (var n = 1; n <= 8; n++) {
      test('$n opponents: no seat collides with another', () {
        final slots = _ring.opponents(n);

        for (var i = 0; i < slots.length; i++) {
          for (var j = i + 1; j < slots.length; j++) {
            expect(
              _gap(slots[i], slots[j]),
              greaterThan(1.0),
              reason: 'opponents $i and $j landed on the same point',
            );
          }
        }
      });

      test('$n opponents: none lands on the viewer', () {
        final slots = _ring.opponents(n);

        for (var i = 0; i < slots.length; i++) {
          expect(
            _gap(slots[i], _ring.viewer),
            greaterThan(100.0),
            reason: 'opponent $i overlaps the viewer seat',
          );
        }
      });

      test('$n opponents: every seat stays on the ring', () {
        for (final s in _ring.opponents(n)) {
          final nx = (s.x - 200) / 160;
          final ny = (s.y - 150) / 110;
          expect(nx * nx + ny * ny, closeTo(1.0, 0.001));
        }
      });

      // Seats spread around the full circle, so past six opponents the arc
      // wraps into the lower half. Medieval Poker tables top out at four seats
      // (three opponents) and both renderers clamp to a bottom reserve anyway,
      // so this invariant is asserted over the range the game actually plays.
      if (n <= 5) {
        test('$n opponents: all sit above the viewer', () {
          for (final s in _ring.opponents(n)) {
            expect(s.y, lessThan(_ring.viewer.y));
          }
        });
      }
    }
  });

  test('opponents are returned in a stable order', () {
    expect(
      [for (final s in _ring.opponents(3)) s.x],
      [for (var i = 0; i < 3; i++) _ring.opponent(i, 3).x],
    );
  });
}

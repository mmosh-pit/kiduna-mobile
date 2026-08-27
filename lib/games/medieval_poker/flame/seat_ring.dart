import 'dart:math';

/// Where one seat sits on the felt, in pixels.
class SeatSlot {
  final double x;
  final double y;
  const SeatSlot(this.x, this.y);

  @override
  String toString() =>
      'SeatSlot(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';
}

/// Seat positions around the table rim.
///
/// The viewer always sits at the bottom, drawn onto the lower felt rather than
/// the outer rim so their hole cards clear the action bar. Everyone else is
/// spread evenly across the remaining arc, symmetric about the vertical axis.
///
/// Works for any [opponentCount] from 0 up. Tournament tables run short-handed
/// when no-shows leave them light, so 1 and 2 opponents are ordinary cases, not
/// edge cases:
///
/// * 1 opponent  → directly opposite (top)
/// * 2 opponents → upper-left and upper-right
/// * 3 opponents → left, top, right
///
/// Seats step around the full circle, so beyond five opponents the arc wraps
/// into the lower half of the felt. Medieval Poker tables top out at four
/// seats, and callers clamp to a bottom reserve regardless.
///
/// This was previously written out twice — once in the offline game and once in
/// the online renderer, with different index bases that happened to agree. One
/// implementation, one set of tests.
class SeatRing {
  /// Centre of the felt.
  final double centreX;
  final double centreY;

  /// Horizontal and vertical radius of the seat ring.
  final double radiusX;
  final double radiusY;

  /// How far below the centre the viewer sits.
  final double viewerDrop;

  const SeatRing({
    required this.centreX,
    required this.centreY,
    required this.radiusX,
    required this.radiusY,
    required this.viewerDrop,
  });

  /// The viewer's slot, on the lower felt.
  SeatSlot get viewer => SeatSlot(centreX, centreY + viewerDrop);

  /// Slot for opponent [index] (0-based) when there are [opponentCount] of them.
  ///
  /// Angles start at the viewer's position and step evenly around the full
  /// circle, so the last opponent never lands back on top of the viewer.
  SeatSlot opponent(int index, int opponentCount) {
    assert(opponentCount >= 0, 'opponentCount cannot be negative');
    assert(
      index >= 0 && index < opponentCount,
      'opponent index $index out of range for $opponentCount opponents',
    );

    final degrees = 90 + (index + 1) * 360 / (opponentCount + 1);
    final radians = degrees * pi / 180.0;
    return SeatSlot(
      centreX + radiusX * cos(radians),
      centreY + radiusY * sin(radians),
    );
  }

  /// Every opponent slot, in order.
  List<SeatSlot> opponents(int opponentCount) => [
    for (var i = 0; i < opponentCount; i++) opponent(i, opponentCount),
  ];
}

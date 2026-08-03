import 'package:aev_flutter/field/render/motion.dart';
import 'package:flutter_test/flutter_test.dart';

/// The motion canon is *specified*, not invented. These tests hold the
/// implementation to the published numbers, and hold reduced motion to its
/// promise: stop the movement, keep the information.
void main() {
  group('the canon numbers', () {
    test('Breathe never exceeds 1.035', () {
      expect(1 + Verb.breatheScale, 1.035);
    });

    test('Breathe runs 6–8 seconds', () {
      expect(Verb.breathePeriodMin, 6.0);
      expect(Verb.breathePeriodMax, 8.0);
    });

    test('Drift stays within ±8px over 14–18s', () {
      expect(Verb.driftMax, 8.0);
      expect(Verb.driftPeriodMin, 14.0);
      expect(Verb.driftPeriodMax, 18.0);
    });

    test('Gather settles in 900ms with a 120–150ms sibling stagger', () {
      expect(Verb.gatherSettle, 0.9);
      expect(Verb.gatherStagger, inInclusiveRange(0.12, 0.15));
    });

    test('Orbit takes at least 16 seconds per revolution', () {
      expect(Verb.orbitMinPeriod, 16.0);
      expect(Verb.roleOrbitPeriod, greaterThanOrEqualTo(Verb.orbitMinPeriod));
    });

    test('node drift is slower and smaller than the canon ceiling', () {
      // The reference's own drift is 56–105s over roughly ±3px: alive without
      // anything appearing to move.
      for (var i = 0; i < 8; i++) {
        expect(Verb.nodeDriftPeriod(i), inInclusiveRange(56.0, 105.0));
        expect(Verb.nodeDriftPeriod(i),
            greaterThan(Verb.driftPeriodMax));
      }
      final travel = (Verb.nodeDriftTo.$1 - Verb.nodeDriftFrom.$1).abs();
      expect(travel, lessThan(Verb.driftMax));
    });
  });

  group('nothing is ever in phase', () {
    test('drift periods spread across eight distinct values', () {
      final periods = {for (var i = 0; i < 40; i++) Verb.nodeDriftPeriod(i)};
      expect(periods, hasLength(8));
    });

    test('drift phases are negative and staggered across nine values', () {
      final phases = {for (var i = 0; i < 40; i++) Verb.nodeDriftPhase(i)};
      expect(phases, hasLength(9));
      expect(phases.every((p) => p <= 0), isTrue);
    });

    test('two neighbouring nodes never share both period and phase', () {
      for (var i = 0; i < 60; i++) {
        final same = Verb.nodeDriftPeriod(i) == Verb.nodeDriftPeriod(i + 1) &&
            Verb.nodeDriftPhase(i) == Verb.nodeDriftPhase(i + 1);
        expect(same, isFalse, reason: 'nodes $i and ${i + 1} move as one');
      }
    });
  });

  group('curves', () {
    test('cycle wraps 0 → 1 and never leaves the range', () {
      for (final t in [0.0, 3.0, 11.9, 60.0, 1234.5]) {
        final v = Verb.cycle(t, 12);
        expect(v, inInclusiveRange(0, 1));
      }
      expect(Verb.cycle(0, 12), 0);
      expect(Verb.cycle(6, 12), closeTo(0.5, 1e-9));
    });

    test('a negative phase still yields a value in range', () {
      for (var i = 0; i < 40; i++) {
        final v = Verb.cycle(0.5, 60, phase: Verb.nodeDriftPhase(i));
        expect(v, inInclusiveRange(0, 1));
      }
    });

    test('pingPong returns to where it started — no accumulated drift', () {
      expect(Verb.pingPong(0, 10), closeTo(0, 1e-9));
      expect(Verb.pingPong(10, 10), closeTo(1, 1e-9));
      expect(Verb.pingPong(20, 10), closeTo(0, 1e-9));
      expect(Verb.pingPong(200, 10), closeTo(0, 1e-9));
    });

    test('easing is monotonic and lands exactly on 0 and 1', () {
      expect(Verb.easeInOut(0), 0);
      expect(Verb.easeInOut(1), 1);
      expect(Verb.easeOut(0), 0);
      expect(Verb.easeOut(1), 1);
      var previous = -1.0;
      for (var i = 0; i <= 100; i++) {
        final v = Verb.easeInOut(i / 100);
        expect(v, greaterThanOrEqualTo(previous));
        previous = v;
      }
    });

    test('easing clamps rather than overshooting', () {
      expect(Verb.easeInOut(-5), 0);
      expect(Verb.easeInOut(5), 1);
    });
  });

  group('the comet idles, then passes', () {
    test('it is dormant for 72% of its cycle', () {
      for (final t in [0.0, 0.2, 0.5, 0.71]) {
        expect(Verb.cometOpacity(t), Verb.cometDormantOpacity);
      }
    });

    test('it peaks at 82% and returns to dormant', () {
      expect(Verb.cometOpacity(0.82), closeTo(Verb.cometPeakOpacity, 1e-9));
      expect(Verb.cometOpacity(1.0), closeTo(Verb.cometDormantOpacity, 1e-9));
    });

    test('it never exceeds its peak', () {
      for (var i = 0; i <= 200; i++) {
        expect(Verb.cometOpacity(i / 200),
            lessThanOrEqualTo(Verb.cometPeakOpacity + 1e-9));
      }
    });
  });

  group('Gather entry', () {
    test('siblings arrive in order, staggered', () {
      final m = Motion()..tick(0.0);
      expect(m.entry(0), 0, reason: 'nothing has started yet');
      m.tick(Verb.gatherStagger * 2.5);
      expect(m.entry(0), greaterThan(m.entry(1)));
      expect(m.entry(1), greaterThan(m.entry(2)));
      expect(m.entry(5), 0, reason: 'later siblings have not begun');
    });

    test('every sibling completes', () {
      final m = Motion()..tick(100);
      for (var i = 0; i < 40; i++) {
        expect(m.entry(i), 1);
      }
    });

    test('progress never leaves 0–1', () {
      final m = Motion();
      for (var step = 0; step < 100; step++) {
        m.tick(0.05);
        for (var i = 0; i < 12; i++) {
          expect(m.entry(i), inInclusiveRange(0, 1));
        }
      }
    });
  });

  group('reduced motion', () {
    test('freezes the clock so every phase rests', () {
      final m = Motion(reduced: true);
      for (var i = 0; i < 100; i++) {
        m.tick(0.016);
      }
      expect(m.elapsed, 0);
      expect(Verb.pingPong(m.elapsed, 8), 0);
      expect(Verb.cycle(m.elapsed, Verb.roleOrbitPeriod), 0);
    });

    test('skips entry to completion — information is never withheld', () {
      final m = Motion(reduced: true);
      for (var i = 0; i < 40; i++) {
        expect(m.entry(i), 1,
            reason: 'a Realm must not be invisible because motion is off');
      }
    });

    test('can be switched on at runtime and the clock stops immediately', () {
      final m = Motion();
      m.tick(5);
      expect(m.elapsed, 5);
      m.reduced = true;
      expect(m.elapsed, 0);
      m.reduced = false;
      expect(m.elapsed, 5, reason: 'the clock kept running underneath');
    });

    test('the resting frame is the same one the animation passes through', () {
      // pingPong(0) and cycle(0) are genuine points on each curve, not a
      // special case — which is why nothing has to branch at the draw site.
      final moving = Motion();
      moving.tick(0);
      final resting = Motion(reduced: true)..tick(99);
      expect(Verb.pingPong(moving.elapsed, 7), Verb.pingPong(resting.elapsed, 7));
      expect(Verb.cycle(moving.elapsed, 24), Verb.cycle(resting.elapsed, 24));
    });
  });
}

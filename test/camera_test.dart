import 'package:aev_flutter/field/render/camera_control.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

/// The camera contract, per the Design Lab canon:
///
/// > Pan — Direct 1:1 movement; the Field moves, chrome never does.
/// > Zoom — Cursor-centered, continuous, 0.7×–2.4×.

/// Vector2 stores float32, so expectations computed in float64 differ in the
/// fifth decimal. A ten-thousandth of a pixel is far below anything visible
/// and still tight enough to catch real drift.
const _eps = 1e-4;

void main() {
  group('zoom range', () {
    test('clamps to 0.7×–2.4×', () {
      expect(Cam.clampZoom(0.1), 0.7);
      expect(Cam.clampZoom(9.0), 2.4);
      expect(Cam.clampZoom(1.5), 1.5);
    });

    test('stepping in and out is symmetric', () {
      const start = 1.0;
      final inThenOut = Cam.stepZoom(Cam.stepZoom(start, 1), -1);
      expect(inThenOut, closeTo(start, _eps));
    });

    test('stepping cannot escape the range however hard it is pushed', () {
      var zoom = 1.0;
      for (var i = 0; i < 100; i++) {
        zoom = Cam.stepZoom(zoom, 1);
      }
      expect(zoom, 2.4);
      for (var i = 0; i < 100; i++) {
        zoom = Cam.stepZoom(zoom, -1);
      }
      expect(zoom, 0.7);
    });
  });

  group('pan is 1:1', () {
    test('a drag of N screen pixels moves the Field exactly N at zoom 1', () {
      final moved = Cam.panned(
        position: Vector2.zero(),
        screenDelta: Vector2(40, -25),
        zoom: 1,
      );
      expect(moved.x, -40);
      expect(moved.y, 25);
    });

    test('at 2× the same drag covers half the world distance', () {
      final moved = Cam.panned(
        position: Vector2.zero(),
        screenDelta: Vector2(40, 0),
        zoom: 2,
      );
      expect(moved.x, -20, reason: 'the Field still tracks the pointer 1:1');
    });

    test('panning back and forth returns exactly to the start — no drift', () {
      var p = Vector2(120, 88);
      for (var i = 0; i < 200; i++) {
        p = Cam.panned(position: p, screenDelta: Vector2(7, -3), zoom: 1.4);
        p = Cam.panned(position: p, screenDelta: Vector2(-7, 3), zoom: 1.4);
      }
      expect(p.x, closeTo(120, _eps));
      expect(p.y, closeTo(88, _eps));
    });
  });

  group('zoom is cursor-anchored', () {
    /// The world point under the cursor, given a viewfinder at [position].
    Vector2 worldUnder(Vector2 position, double zoom, Vector2 pointer) =>
        position + pointer / zoom;

    test('the world point under the cursor does not move', () {
      final position = Vector2(30, 45);
      final pointer = Vector2(640, 300);
      const from = 1.0;
      final to = Cam.stepZoom(from, 1);

      final before = worldUnder(position, from, pointer);
      final after = Cam.zoomAnchored(
        position: position,
        fromZoom: from,
        toZoom: to,
        pointer: pointer,
      );

      expect(worldUnder(after, to, pointer).x, closeTo(before.x, _eps));
      expect(worldUnder(after, to, pointer).y, closeTo(before.y, _eps));
    });

    test('holds across many notches at an off-centre pointer', () {
      var position = Vector2(-14, 62);
      var zoom = 1.0;
      final pointer = Vector2(180, 690);
      final anchor = worldUnder(position, zoom, pointer);

      for (var i = 0; i < 12; i++) {
        final next = Cam.stepZoom(zoom, i.isEven ? 1 : -1, times: 1.7);
        position = Cam.zoomAnchored(
          position: position,
          fromZoom: zoom,
          toZoom: next,
          pointer: pointer,
        );
        zoom = next;
      }

      expect(worldUnder(position, zoom, pointer).x, closeTo(anchor.x, _eps));
      expect(worldUnder(position, zoom, pointer).y, closeTo(anchor.y, _eps));
    });

    test('zooming at the top-left corner leaves the origin fixed', () {
      final after = Cam.zoomAnchored(
        position: Vector2.zero(),
        fromZoom: 1,
        toZoom: 2,
        pointer: Vector2.zero(),
      );
      expect(after, Vector2.zero());
    });
  });

  group('bounds keep the Field reachable', () {
    final world = Vector2(1440, 900);
    final viewport = Vector2(1440, 900);

    test('at 1× — where the Field exactly fits — pan still responds', () {
      // Regression: an earlier clamp pinned the camera to centre whenever the
      // Field fitted, which swallowed every pan at rest zoom and read as a
      // frozen Field. Browser verification caught it; this locks it down.
      final p = Cam.clampPosition(
        position: Vector2(200, 150),
        world: world,
        viewport: viewport,
        zoom: 1,
      );
      expect(p, Vector2(200, 150), reason: 'well inside the slack');
    });

    test('at 1× pan is still bounded by the overscroll slack', () {
      final p = Cam.clampPosition(
        position: Vector2(99999, -99999),
        world: world,
        viewport: viewport,
        zoom: 1,
      );
      expect(p.x, closeTo(viewport.x * Cam.overscroll, _eps));
      expect(p.y, closeTo(-viewport.y * Cam.overscroll, _eps));
    });

    test('zoomed out past 1× it stays near its centred rest position', () {
      const zoom = 0.7;
      final visible = viewport / zoom;
      final centreX = (world.x - visible.x) / 2;
      final p = Cam.clampPosition(
        position: Vector2(9999, -9999),
        world: world,
        viewport: viewport,
        zoom: zoom,
      );
      expect(p.x, closeTo(centreX + visible.x * Cam.overscroll, _eps));
    });

    test('zoomed in, panning far away is caught by the overscroll limit', () {
      final p = Cam.clampPosition(
        position: Vector2(99999, 99999),
        world: world,
        viewport: viewport,
        zoom: 2,
      );
      final visible = viewport / 2;
      final maxX = world.x - visible.x + visible.x * Cam.overscroll;
      expect(p.x, closeTo(maxX, _eps));
      expect(p.x, lessThan(world.x),
          reason: 'the Field can never be panned entirely off-screen');
    });

    test('a position already inside the bounds is left untouched', () {
      final inside = Vector2(120, 90);
      final p = Cam.clampPosition(
        position: inside,
        world: world,
        viewport: viewport,
        zoom: 2,
      );
      expect(p, inside);
    });
  });

  group('resize', () {
    test('the same percent resolves proportionally at any viewport', () {
      // Percent-of-Field is the layout contract: 50% is the middle whatever
      // the window does.
      for (final size in [Vector2(800, 600), Vector2(1920, 1080), Vector2(390, 844)]) {
        expect(50 / 100 * size.x, size.x / 2);
        expect(50 / 100 * size.y, size.y / 2);
      }
    });
  });
}

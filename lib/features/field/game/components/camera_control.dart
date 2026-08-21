import 'dart:math' as math;

import 'package:flame/components.dart';

abstract final class Cam {
  static const minZoom = 0.45;
  static const maxZoom = 2.4;
  static const zoomStep = 1.12;
  static const keyPanPerSecond = 620.0;
  static const overscroll = 0.5;

  static double clampZoom(double zoom) =>
      zoom.clamp(minZoom, maxZoom).toDouble();

  static Vector2 zoomAnchored({
    required Vector2 position,
    required double fromZoom,
    required double toZoom,
    required Vector2 pointer,
  }) {
    final world = position + pointer / fromZoom;
    return world - pointer / toZoom;
  }

  static Vector2 clampPosition({
    required Vector2 position,
    required Vector2 world,
    required Vector2 viewport,
    required double zoom,
  }) {
    final visible = viewport / zoom;
    double axis(double value, double worldExtent, double visibleExtent) {
      final slack = visibleExtent * overscroll;
      if (visibleExtent >= worldExtent) {
        final centre = (worldExtent - visibleExtent) / 2;
        return value.clamp(centre - slack, centre + slack);
      }
      return value.clamp(-slack, worldExtent - visibleExtent + slack);
    }

    return Vector2(
      axis(position.x, world.x, visible.x),
      axis(position.y, world.y, visible.y),
    );
  }

  static Vector2 panned({
    required Vector2 position,
    required Vector2 screenDelta,
    required double zoom,
  }) =>
      position - screenDelta / zoom;

  static double stepZoom(double zoom, double direction, {double times = 1}) =>
      clampZoom(zoom * math.pow(zoomStep, direction * times).toDouble());
}

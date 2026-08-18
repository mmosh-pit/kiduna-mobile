import 'package:flame/components.dart';

import '../../data/field_models.dart';

abstract final class Layer {
  static const ground = 0;
  static const geometry = 10;
  static const connection = 20;
  static const object = 30;
  static const signal = 40;
}

Vector2 project(FieldPoint point, Vector2 size) => Vector2(
      point.left / 100 * size.x,
      point.top / 100 * size.y,
    );

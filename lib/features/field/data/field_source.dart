import 'dart:async';

import 'field_events.dart';
import 'field_models.dart';

abstract interface class FieldSource {
  Future<FieldSnapshot> load();

  Stream<FieldEvent> get events;

  void emit(FieldEvent event);

  Future<void> dispose();
}

mixin FieldEventSink implements FieldSource {
  final _controller = StreamController<FieldEvent>.broadcast();

  @override
  Stream<FieldEvent> get events => _controller.stream;

  @override
  void emit(FieldEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  @override
  Future<void> dispose() => _controller.close();
}

/// The seam between where Field data comes from and what the Field draws.
///
/// The Flame world talks only to this interface. Swapping [MockFieldSource]
/// for a live implementation must require **zero** changes inside the renderer.
library;

import 'dart:async';

import 'events.dart';
import 'models.dart';

abstract interface class FieldSource {
  /// Loads the snapshot for the current viewer.
  Future<FieldSnapshot> load();

  /// Everything the Field emits. Only `GravityChanged` is a write.
  Stream<FieldEvent> get events;

  /// Called by the renderer when something happens in the Field.
  void emit(FieldEvent event);

  /// Releases the event stream.
  Future<void> dispose();
}

/// Shared event plumbing. Sources differ in where snapshots come from, not in
/// how events are broadcast.
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

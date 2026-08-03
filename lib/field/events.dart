/// Dart mirror of `contracts/field-event.schema.json`.
///
/// Six events. Only [GravityChanged] is a write; everything else is
/// observation.
///
/// **There is deliberately no `RealmEntered`.** Entry is a consequential Action
/// with its own authority, inspection, confirmation, execution, settlement and
/// recovery boundaries — none of which this build performs. Leaving it out of
/// the vocabulary is what prevents selection from being wired to navigation by
/// accident. If entry is added later it arrives as a *new*, separately reviewed
/// event; it must never be smuggled in as a variant of selection.
library;

import '../design/tokens.dart';

sealed class FieldEvent {
  const FieldEvent(this.at);

  final DateTime at;

  String get type;

  Map<String, dynamic> toJson();

  Map<String, dynamic> _base() => {
        'type': type,
        'at': at.toUtc().toIso8601String(),
      };
}

/// Inspection. Highlights **existing** paths and updates context.
/// Does not enter, join, or grant anything.
class RealmSelected extends FieldEvent {
  const RealmSelected(this.realmId, super.at);

  final String realmId;

  @override
  String get type => 'RealmSelected';

  @override
  Map<String, dynamic> toJson() => {..._base(), 'realmId': realmId};
}

/// Selection cleared. Paths return to their resting light.
class RealmDeselected extends FieldEvent {
  const RealmDeselected(super.at);

  @override
  String get type => 'RealmDeselected';

  @override
  Map<String, dynamic> toJson() => _base();
}

/// Explicit intent on an already-selected Realm. Opens the inspection alert.
/// It is **not** entry.
class RealmActivated extends FieldEvent {
  const RealmActivated(this.realmId, super.at);

  final String realmId;

  @override
  String get type => 'RealmActivated';

  @override
  Map<String, dynamic> toJson() => {..._base(), 'realmId': realmId};
}

/// The only write. Viewer-scoped: it changes how this Source sees the Realm
/// and nothing else — never authority, membership, or truth.
class GravityChanged extends FieldEvent {
  const GravityChanged(this.realmId, this.from, this.to, super.at);

  final String realmId;
  final Gravity from;
  final Gravity to;

  @override
  String get type => 'GravityChanged';

  @override
  Map<String, dynamic> toJson() => {
        ..._base(),
        'realmId': realmId,
        'from': from.level,
        'to': to.level,
      };
}

/// Optional, for persisting a viewport. Fixed chrome never scales with it.
class CameraChanged extends FieldEvent {
  const CameraChanged(this.x, this.y, this.zoom, super.at);

  final double x;
  final double y;

  /// Clamped to the recommended 0.7×–2.4× range before context changes.
  final double zoom;

  @override
  String get type => 'CameraChanged';

  @override
  Map<String, dynamic> toJson() =>
      {..._base(), 'x': x, 'y': y, 'zoom': zoom};
}

/// The Ki focus dimmer. Changes Field **opacity only** — never Ki context,
/// visibility, authority, relationship truth, or underlying data.
/// The Field's presentation state changed.
///
/// Reported because the receiving system may want to follow it — Ki's context,
/// a Sentinel's read of engagement — but it is **presentation only**: nothing
/// downstream may treat a state as evidence of intent, authority, or consent.
/// The canon is explicit that expressive state is never evidence of legal
/// intent or authorization.
class FieldStateChanged extends FieldEvent {
  const FieldStateChanged(this.state, super.at);

  final String state;

  @override
  String get type => 'FieldStateChanged';

  @override
  Map<String, dynamic> toJson() => {..._base(), 'state': state};
}

class FieldFocusChanged extends FieldEvent {
  const FieldFocusChanged(this.dimmed, super.at);

  final bool dimmed;

  @override
  String get type => 'FieldFocusChanged';

  @override
  Map<String, dynamic> toJson() => {..._base(), 'dimmed': dimmed};
}

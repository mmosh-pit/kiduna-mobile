import '../game/enamel_tokens.dart';

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

class RealmSelected extends FieldEvent {
  const RealmSelected(this.realmId, super.at);

  final String realmId;

  @override
  String get type => 'RealmSelected';

  @override
  Map<String, dynamic> toJson() => {..._base(), 'realmId': realmId};
}

class RealmDeselected extends FieldEvent {
  const RealmDeselected(super.at);

  @override
  String get type => 'RealmDeselected';

  @override
  Map<String, dynamic> toJson() => _base();
}

class RealmActivated extends FieldEvent {
  const RealmActivated(this.realmId, super.at);

  final String realmId;

  @override
  String get type => 'RealmActivated';

  @override
  Map<String, dynamic> toJson() => {..._base(), 'realmId': realmId};
}

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

class CameraChanged extends FieldEvent {
  const CameraChanged(this.x, this.y, this.zoom, super.at);

  final double x;
  final double y;
  final double zoom;

  @override
  String get type => 'CameraChanged';

  @override
  Map<String, dynamic> toJson() =>
      {..._base(), 'x': x, 'y': y, 'zoom': zoom};
}

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

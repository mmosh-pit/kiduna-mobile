import 'package:flutter/foundation.dart';

/// A single conversational turn from Ki: an optional [title] eyebrow, the [body]
/// it says, and an optional [invitation] follow-up line.
@immutable
class KiTopic {
  const KiTopic({this.title = '', required this.body, this.invitation = ''});

  final String title;
  final String body;
  final String invitation;

  @override
  bool operator ==(Object other) =>
      other is KiTopic &&
      other.title == title &&
      other.body == body &&
      other.invitation == invitation;

  @override
  int get hashCode => Object.hash(title, body, invitation);
}

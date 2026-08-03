/// What Ki says, and the rules it says it under.
///
/// **Ki speaks in the third person, never "I".** That is not a style
/// preference: Ki is present and can prepare or explain work *without
/// absorbing the Source's authority*, and first-person voice quietly implies an
/// actor with intentions of its own.
///
/// Ki also never claims to have done anything. It orients, it explains, and it
/// offers to prepare — the Source decides.
library;

import '../field/placement.dart';

class KiLine {
  const KiLine(this.body, {this.questions = const []});

  /// **Ki's voice.** Third person, always. Never "I", never "we".
  final String body;

  /// **The Source's voice.** These are prompts the member sends, not things Ki
  /// says — so first person is correct here, and the reference phrases them
  /// exactly this way: "What should I do first?"
  ///
  /// The distinction matters: the third-person rule protects Ki from reading
  /// as an actor with intentions of its own. It does not apply to words the
  /// member is about to speak.
  final List<String> questions;
}

abstract final class KiVoice {
  /// The resting Field, nothing selected.
  static KiLine field(String ecosystem, String viewer) => KiLine(
        '$ecosystem is the current Realm. The Field shows the other Realms '
        'visible through this Source’s authority and relationships.',
        questions: [
          'What should I do first?',
          'Tell me more about $ecosystem.',
          'Which Realms need attention?',
        ],
      );

  /// A Realm is under inspection. Ki reports standing and nothing private.
  static KiLine realm(Placement placement) {
    final realm = placement.realm;
    final ally = placement.ally?.name ?? 'no stationed Ally';

    final proposed = realm.fixture
        ? ' It is a proposed entity and does not yet exist.'
        : '';

    return KiLine(
      '${realm.name} is ${_article(realm.typeName)} ${realm.typeName}, held at '
      '${placement.gravity.label}. This Source is ${placement.role.label} '
      'there, with $ally.$proposed Selecting a Realm inspects it; it does not '
      'enter it.',
      questions: [
        'What may be done in ${realm.name}?',
        'Why is ${realm.name} here?',
        if (realm.childIds.isNotEmpty) 'What does ${realm.name} contain?',
      ],
    );
  }

  /// The empty Ecosystem — the newly-created case.
  static const KiLine empty = KiLine(
    'This Ecosystem contains no Realms yet. Nothing has been formed, and '
    'nothing is missing.',
    questions: [
      'How is a Realm formed?',
      'What should exist first?',
    ],
  );

  static String _article(String word) =>
      'AEIOU'.contains(word.isEmpty ? 'X' : word[0].toUpperCase()) ? 'an' : 'a';
}

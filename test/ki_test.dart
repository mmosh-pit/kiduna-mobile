import 'dart:io';

import 'package:aev_flutter/design/tokens.dart';
import 'package:aev_flutter/field/mock_source.dart';
import 'package:aev_flutter/field/placement.dart';
import 'package:aev_flutter/ki/ki_voice.dart';
import 'package:flutter_test/flutter_test.dart';

/// **Ki speaks in the third person, never "I".**
///
/// This is not a style preference. Ki is present and can prepare or explain
/// work *without absorbing the Source's authority*, and first-person voice
/// quietly implies an actor with intentions of its own. It is the kind of rule
/// that erodes one helpful sentence at a time, so it is tested.
void main() {
  ResolvedField load(String name) => resolveField(
        parseSnapshot(
          File('assets/fixtures/$name-snapshot.json').readAsStringSync(),
        ),
      );

  /// First person, as whole words only — "I" must not match "Institution",
  /// and "me" must not match "Ceremony".
  final firstPerson = RegExp(
    r"\b(I|I'm|I’m|I've|I’ve|I'll|I’ll|me|my|mine|myself|we|we're|we’re|us|our|ours)\b",
    caseSensitive: false,
  );

  List<KiLine> allLines() => [
        KiVoice.field('Kinship Duna', 'Alice'),
        KiVoice.empty,
        for (final p in load('alice').placements) KiVoice.realm(p),
        for (final p in load('coverage').placements) KiVoice.realm(p),
        for (final p in load('edge').placements) KiVoice.realm(p),
      ];

  /// Only what **Ki** says. Suggested questions are the Source's own voice —
  /// "What should I do first?" is the member speaking, and the reference
  /// phrases them exactly that way.
  List<String> everythingKiSays() => [for (final l in allLines()) l.body];

  group('Ki never speaks in the first person', () {
    test('across every line it can say about every fixture', () {
      final offenders = <String>[];
      for (final text in everythingKiSays()) {
        final match = firstPerson.firstMatch(text);
        if (match != null) offenders.add('"${match.group(0)}" in: $text');
      }
      expect(
        offenders,
        isEmpty,
        reason: 'Ki must speak in the third person:\n${offenders.join('\n')}',
      );
    });

    test('suggested questions are the Source speaking, so may say "I"', () {
      // The rule protects Ki from reading as an actor with intentions of its
      // own. It does not apply to words the member is about to send.
      final asked = [for (final l in allLines()) ...l.questions];
      expect(asked.any(firstPerson.hasMatch), isTrue,
          reason: 'prompts should read as the Source would phrase them');
    });

    test('the detector would actually catch a lapse', () {
      // Guard against a regex that silently matches nothing.
      expect(firstPerson.hasMatch('I can prepare that for you'), isTrue);
      expect(firstPerson.hasMatch('Let me open it'), isTrue);
      expect(firstPerson.hasMatch('We formed this Realm'), isTrue);
    });

    test('it does not trip on Realm names that merely contain the letters', () {
      expect(firstPerson.hasMatch('Institution'), isFalse);
      expect(firstPerson.hasMatch('The Ceremony Machine'), isFalse);
      expect(firstPerson.hasMatch('Indigenous Revival'), isFalse);
      expect(firstPerson.hasMatch('Mycelial Aid'), isFalse);
    });
  });

  group('Ki reports standing, and claims nothing', () {
    test('it never says a consequential Action has happened', () {
      const claims = [
        'has been created',
        'has been sent',
        'was granted',
        'you now have',
        'entered',
        'joined',
      ];
      for (final text in everythingKiSays()) {
        for (final claim in claims) {
          expect(
            text.toLowerCase(),
            isNot(contains(claim)),
            reason: 'Ki claimed an Action in: $text',
          );
        }
      }
    });

    test('it states that selection is inspection, not entry', () {
      final line = KiVoice.realm(load('alice').byId('dunaversity')!);
      expect(line.body, contains('does not enter'));
    });

    test('a proposed entity is named as not yet existing', () {
      final proposed = load('coverage')
          .placements
          .firstWhere((p) => p.realm.fixture);
      expect(KiVoice.realm(proposed).body, contains('does not yet exist'));
    });

    test('an unstationed Realm reads as having no Ally, not a blank', () {
      final line = KiVoice.realm(load('alice').byId('agency')!);
      expect(line.body, contains('no stationed Ally'));
    });

    test('a stationed Ally is named', () {
      final withAlly = load('coverage')
          .placements
          .firstWhere((p) => p.ally != null);
      expect(KiVoice.realm(withAlly).body, contains(withAlly.ally!.name));
    });
  });

  group('context', () {
    test('the empty Ecosystem is described as unformed, not broken', () {
      expect(KiVoice.empty.body, contains('no Realms yet'));
      expect(KiVoice.empty.body, contains('nothing is missing'));
    });

    test('every line offers at least one terse question', () {
      for (final p in load('alice').placements) {
        expect(KiVoice.realm(p).questions, isNotEmpty);
      }
      expect(KiVoice.field('X', 'Y').questions, isNotEmpty);
      expect(KiVoice.empty.questions, isNotEmpty);
    });

    test('Gravity is reported by name, not as a number', () {
      final line = KiVoice.realm(load('alice').byId('dunaversity')!);
      expect(line.body, contains(Gravity.vital.label));
      expect(line.body, isNot(contains('Gravity 5')));
    });
  });
}

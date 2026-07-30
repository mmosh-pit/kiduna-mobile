import '../../../data/models/field_realm.dart';
import '../../../data/models/ki_topic.dart';

/// A selectable fact in the Inspect panel.
typedef FieldFact = ({String label, String value, KiTopic topic});

/// An entry in the Possible Actions grid.
typedef FieldAction = ({
  String id,
  String label,
  String panelLabel,
  String icon,
  KiTopic topic,
});

/// A suggested-prompt chip offered beneath the Ki thread.
typedef KiChip = ({String label, KiTopic topic});

/// A Capacity that can be developed for a Realm or Ally.
typedef Capacity = ({String id, String label, String detail, String icon});

/// Simulation fixtures for the Newly Created Ecosystem View (`the-field-01`),
/// transcribed verbatim from the prototype.
///
/// This is prototype content, not translatable UI chrome: in production the
/// Realm, facts, and Ki dialogue come from authorized services (see the
/// prototype's ENGINEERING-HANDOFF), so it lives in the data layer rather than
/// `app_en.arb`. App chrome (button labels, "Inspect", "Field focus", …) does
/// live in `app_en.arb`.
abstract class FieldFixtures {
  const FieldFixtures._();

  static const FieldRealm kinshipDuna = FieldRealm(
    name: 'Kinship Duna',
    type: 'Ecosystem',
    emblemAsset: 'assets/images/realm-emblems/organization.jpg',
  );

  /// The five Capacities of a Realm or Ally (Shape / Design your Ally).
  static const List<Capacity> capacities = [
    (
      id: 'wisdom',
      label: 'Inform with Wisdom',
      detail: 'Give permitted knowledge and trusted sources.',
      icon: '✦',
    ),
    (
      id: 'presence',
      label: 'Instruct with Presence',
      detail: 'Shape behavior, tone, and boundaries.',
      icon: '◉',
    ),
    (
      id: 'connections',
      label: 'Empower with Connections',
      detail: 'Grant access to specific outside accounts.',
      icon: '⌁',
    ),
    (
      id: 'automations',
      label: 'Enable with Automations',
      detail: 'Define what starts, continues, and stops work.',
      icon: '↻',
    ),
    (
      id: 'skills',
      label: 'Impart Skills',
      detail: 'Provide versioned instructions for specific work.',
      icon: '◇',
    ),
  ];

  /// The roles that may be proposed in an invitation.
  static const List<String> roles = [
    'Guest',
    'Member',
    'Organizer',
    'Creator',
    'Builder',
    'Catalyst',
    'Luminary',
    'Mage',
  ];

  /// Expiration options for an invitation.
  static const List<String> expirations = [
    '15 minutes',
    '1 hour',
    '24 hours',
    '7 days',
    '30 days',
    '1 year',
  ];

  /// Realm types available when forming a new Realm.
  static const List<String> realmTypes = [
    'Organization',
    'Alliance',
    'Community',
    'Program',
    'Project',
    'Relationship',
    'Institution',
  ];

  /// Fixture invitation link and code shown in the review.
  static const String invitationLink =
      'https://join.kiduna.org/k/7FK9-DUNA-3M2Q';
  static const String invitationCode = '7FK9-DUNA-3M2Q';

  static const KiTopic defaultKi = KiTopic(
    body:
        'Welcome Alice! Let’s get to work, unless you have some questions. '
        'In that case, ask away!',
  );

  static const KiTopic messagePreserved = KiTopic(
    title: 'Let’s work through it',
    body: 'Ki has kept Alice’s message in this conversation.',
    invitation:
        'Ki will ask for only the next detail needed and show any prepared '
        'changes in the Field.',
  );

  static const List<FieldAction> actions = [
    (
      id: 'invite',
      label: 'Invite people to join you here',
      panelLabel: 'Prepare a Kiduna Invitation',
      icon: '⇄',
      topic: KiTopic(
        title: 'Invite someone',
        body:
            'Let’s prepare one invitation for one person, with a clear '
            'purpose, exact access, and a private handshake between you.',
        invitation:
            'Alice can fill in the invitation here or tell Ki about the '
            'person; Ki can prepare it through dialogue.',
      ),
    ),
    (
      id: 'realm',
      label: 'Form a New Realm',
      panelLabel: 'Form a New Realm',
      icon: '✦',
      topic: KiTopic(
        title: 'Form a New Realm',
        body:
            'A Realm gives an effort its own purpose, boundaries, people, '
            'Wisdom, and authority.',
        invitation:
            'Use the working panel or tell Ki what should become possible; '
            'Ki can help form it through dialogue.',
      ),
    ),
    (
      id: 'shape',
      label: 'Shape Kinship Duna',
      panelLabel: 'Shape Kinship Duna',
      icon: '◈',
      topic: KiTopic(
        title: 'Shape Kinship Duna',
        body:
            'You can develop what this Ecosystem knows, how it behaves, what '
            'it can reach, what keeps working, and what it knows how to do.',
        invitation:
            'Choose a capacity in the working panel or describe the change; '
            'Ki can guide the work through dialogue.',
      ),
    ),
    (
      id: 'present',
      label: 'Present Kinship Duna',
      panelLabel: 'Present Kinship Duna',
      icon: '◎',
      topic: KiTopic(
        title: 'Present Kinship Duna',
        body:
            'Presentation controls how Kinship Duna is named, described, '
            'typed, and recognized when it appears close in the Field.',
        invitation:
            'Edit the Realm directly in the working panel or ask Ki to help '
            'clarify how it should present.',
      ),
    ),
  ];

  static const List<FieldFact> facts = [
    (
      label: 'Ecosystem ID',
      value: 'ECO-KD-001',
      topic: KiTopic(
        title: 'Ecosystem identity',
        body:
            'ECO-KD-001 is the stable fixture identifier for Kinship Duna. '
            'Names and presentation can change without changing this identity.',
        invitation:
            'Would you like to talk about identity, naming, or how this '
            'appears in Records?',
      ),
    ),
    (
      label: 'Registration',
      value: 'Kinship Duna, WV Org. ID 167085',
      topic: KiTopic(
        title: 'Registration',
        body:
            'Kinship Duna is registered in West Virginia under Organization '
            'ID 167085. This world-facing registration is distinct from its '
            'stable Kiduna Ecosystem ID.',
        invitation:
            'Ki can explain what the registration establishes and where its '
            'supporting Records are held.',
      ),
    ),
    (
      label: 'Purpose',
      value:
          'Help people build capable, connected institutions without '
          'surrendering their agency.',
      topic: KiTopic(
        title: 'Kinship Duna’s purpose',
        body:
            'Its current purpose is to help people build capable, connected '
            'institutions without surrendering their agency. As Catalyst, you '
            'may prepare a clearer version before anyone else arrives.',
        invitation: 'Want to refine the purpose together?',
      ),
    ),
    (
      label: 'Capacities',
      value: 'Wisdom · Presence · Connections · Automations · Skills',
      topic: KiTopic(
        title: 'Kinship Duna’s capacities',
        body:
            'Capacities describe what Kinship Duna knows, how it behaves, what '
            'it can reach, what can keep working, and what it knows how to do.',
        invitation:
            'Open Shape Kinship Duna to inspect or develop any one of these '
            'capacities.',
      ),
    ),
    (
      label: 'Organizations',
      value: '0',
      topic: KiTopic(
        title: 'Organizations',
        body:
            'There are no Organizations inside Kinship Duna yet. An '
            'Organization can hold Programs, Projects, people, Resources, and '
            'its own local authority.',
        invitation:
            'You could start the first one now. What should it help '
            'people do?',
      ),
    ),
    (
      label: 'Members',
      value: '1 · Alice',
      topic: KiTopic(
        title: 'Members',
        body:
            'You are currently the only Source in this Ecosystem. Nobody else '
            'can see or act here.',
        invitation:
            'Would you like to plan who should join first and what access '
            'they should receive?',
      ),
    ),
    (
      label: 'Treasury',
      value: '0 KIDUNA',
      topic: KiTopic(
        title: 'Ecosystem treasury',
        body:
            'Kinship Duna’s shared treasury is empty. Your personal Compute '
            'balance remains separate and is shown in the Field.',
        invitation:
            'Ki can explain the difference between personal Resources and an '
            'Ecosystem treasury.',
      ),
    ),
    (
      label: 'Catalyst',
      value: 'Alice · Ecosystem-wide authority',
      topic: KiTopic(
        title: 'Catalyst authority',
        body:
            'The Catalyst can initiate and direct work across this Ecosystem. '
            'Alice’s Ecosystem-wide authority remains available without '
            'filling the interface with controls.',
        invitation:
            'Ask Ki about any authority, boundary, or consequential Action '
            'before using it.',
      ),
    ),
  ];

  static const List<KiChip> chips = [
    (
      label: 'What should I do first?',
      topic: KiTopic(
        title: 'A useful first move',
        body:
            'Start with the thing Alice wants Kinship Duna to make possible. '
            'From there, Ki can help decide whether to invite someone, form a '
            'Realm, shape the Ecosystem, or design an Ally.',
        invitation: 'What do you want to make possible?',
      ),
    ),
    (
      label: 'Tell me more about Kinship Duna.',
      topic: KiTopic(
        title: 'Kinship Duna’s purpose',
        body:
            'Its current purpose is to help people build capable, connected '
            'institutions without surrendering their agency. As Catalyst, you '
            'may prepare a clearer version before anyone else arrives.',
        invitation: 'Want to refine the purpose together?',
      ),
    ),
  ];

  /// Compute balance shown in the Field (fixture values).
  static const String computeBalance = '18,400 KIDUNA';
  static const String computeRateLabel = '1 KIDUNA';
  static const String computeRateValue = '0.25 USDC';
  static const String computeTotalLabel = 'Total value';
  static const String computeTotalValue = '4,600 USDC';
}

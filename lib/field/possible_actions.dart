/// Possible Actions — what may be done in the selected Realm.
///
/// The live AEV shows this panel, seeded with the current Realm and re-seeded
/// on every selection. The inventory below is drawn from `kit/actions.md` §2,
/// reduced to the actions a Realm can actually offer from the Field.
///
/// **Two rules this file exists to keep true.**
///
/// An Action is one of the seven Elements, and the canon is unambiguous about
/// what it is: *"the deterministic, reserved operations intelligence is never
/// allowed to improvise — moving money, issuing tokens, finalizing votes."*
/// So an Action here is a **named, typed offer**, never free text, and never
/// something Ki composed. This build renders them; it performs none of them.
///
/// And they are **role-gated**. What a Source may do in a Realm depends on the
/// role they hold *there* — `actions.md` calls the inventory "role-gated and
/// graph-indexed". A Guest is not shown a Catalyst's Actions and then refused;
/// the offer is absent, because absence is how this system expresses
/// permission everywhere else too.
library;

import 'models.dart';

/// Where an Action sits in the baseline inventory. The groupings are
/// `actions.md`'s own, not invented here.
enum ActionGroup {
  converse('Converse'),
  remember('Remember'),
  connect('Invite · Connect'),
  decide('Decide'),
  pay('Pay'),
  make('Make');

  const ActionGroup(this.label);
  final String label;
}

/// One offered Action.
class PossibleAction {
  const PossibleAction({
    required this.id,
    required this.label,
    required this.motif,
    required this.group,
    required this.minimumRole,
    this.sovereign = false,
    this.webOnly = false,
  });

  final String id;
  final String label;

  /// The glyph, from the same original-artwork vocabulary as Realm motifs.
  final String motif;

  final ActionGroup group;

  /// The least role that may be offered this Action.
  final Role minimumRole;

  /// Sovereign acts are never delegated to an agent and never one-tap:
  /// press-and-hold is reserved for exactly these.
  final bool sovereign;

  /// Money never moves on mobile. `actions.md` §Pay: "always via the web
  /// surface … mobile app never touches payments."
  final bool webOnly;
}

/// The baseline inventory. Ordered by group, then by how ordinary the act is.
const baselineActions = <PossibleAction>[
  PossibleAction(
    id: 'ask',
    label: 'Ask Ki about this Realm',
    motif: '◇',
    group: ActionGroup.converse,
    minimumRole: Role.guest,
  ),
  PossibleAction(
    id: 'inspect',
    label: 'Inspect what it is and where it sits',
    motif: '◎',
    group: ActionGroup.converse,
    minimumRole: Role.guest,
  ),
  PossibleAction(
    id: 'add-wisdom',
    label: 'Add information',
    motif: '⊞',
    group: ActionGroup.remember,
    minimumRole: Role.member,
  ),
  PossibleAction(
    id: 'set-access',
    label: 'Set access level',
    motif: '⊙',
    group: ActionGroup.remember,
    minimumRole: Role.organizer,
  ),
  PossibleAction(
    id: 'connect',
    label: 'Form a relationship',
    motif: '⇄',
    group: ActionGroup.connect,
    minimumRole: Role.member,
  ),
  PossibleAction(
    id: 'extend-code',
    label: 'Extend a Kinship Code',
    motif: '✦',
    group: ActionGroup.connect,
    minimumRole: Role.organizer,
    sovereign: true,
  ),
  PossibleAction(
    id: 'form-realm',
    label: 'Form a new Realm here',
    motif: '✧',
    group: ActionGroup.make,
    minimumRole: Role.creator,
  ),
  PossibleAction(
    id: 'shape',
    label: 'Shape its Wisdom and Presence',
    motif: '◈',
    group: ActionGroup.make,
    minimumRole: Role.creator,
  ),
  PossibleAction(
    id: 'propose',
    label: 'Raise a proposal',
    motif: '▲',
    group: ActionGroup.decide,
    minimumRole: Role.member,
  ),
  PossibleAction(
    id: 'vote',
    label: 'Vote',
    motif: '●',
    group: ActionGroup.decide,
    minimumRole: Role.member,
    sovereign: true,
  ),
  PossibleAction(
    id: 'balances',
    label: 'Check balances',
    motif: '≡',
    group: ActionGroup.pay,
    minimumRole: Role.member,
  ),
  PossibleAction(
    id: 'send-compute',
    label: 'Send Compute',
    motif: '⇢',
    group: ActionGroup.pay,
    minimumRole: Role.organizer,
    webOnly: true,
  ),
];

/// Rank of a role, low to high. Used only to gate the inventory — it is **not**
/// a hierarchy of worth, and nothing else in the Field may consult it.
const _rank = <Role, int>{
  Role.guest: 0,
  Role.member: 1,
  Role.organizer: 2,
  Role.creator: 3,
  Role.builder: 4,
  Role.catalyst: 5,
  Role.luminary: 6,
  Role.mage: 7,
};

/// The Actions a Source holding [role] may be offered in a Realm.
///
/// Returns the offers, not a permission answer. A caller that renders these is
/// showing what is possible; performing any of them still goes through the
/// command boundary, which re-decides authorization at execution time.
List<PossibleAction> actionsFor(Role? role) {
  final held = _rank[role ?? Role.guest] ?? 0;
  return [
    for (final action in baselineActions)
      if ((_rank[action.minimumRole] ?? 0) <= held) action,
  ];
}

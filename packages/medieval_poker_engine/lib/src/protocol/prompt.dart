/// A decision the server asks a specific player to make. Every interactive
/// window in the game maps to one [PromptKind]. The client renders the matching
/// panel; the player's response is sent back as a [GameAction] referencing
/// [promptId]. If [deadlineMs] elapses (or the player disconnects), the server
/// applies the window's default (fold / pass / auto).
library;

enum PromptKind {
  bettingAction, // check / call / fold / bet / raise
  setupWindow, // play Setup power cards (or done)
  roundWindow, // play Round power cards (or done)
  counterWindow, // respond to the counter chain (or pass)
  showdownWindow, // play Showdown cards (or done)
  boardCounter, // "Just Dealt" board counters (or pass)
  targetPick, // choose an opponent (Trash Talker, Show Mercy, Spot the Tell…)
  itemPlay, // play a held Item (or done)
  itemMode, // choose an item's mode (Monkey Paw, Grappling Hook…)
  itemPick, // choose a card the item acts on (discard / mulligan target)
  payChoice, // pay coins vs spend a Comp Chip
  chipSell, // Midas Crown: sell a Comp Chip (or keep)
  classPick, // deck-building: choose a class
  courtPick, // deck-building: choose a Court
  deckBuild, // deck-building: choose which power cards to run
}

PromptKind promptKindFromName(String n) =>
    PromptKind.values.firstWhere((k) => k.name == n);

/// One selectable option in a prompt (a card, an opponent, a mode, …).
class PromptOption {
  final String id; // opaque id the client echoes back
  final String label;
  final String? subtitle;
  final String? cardCode; // for rendering card art, when applicable

  const PromptOption(this.id, this.label, {this.subtitle, this.cardCode});

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        if (subtitle != null) 'subtitle': subtitle,
        if (cardCode != null) 'cardCode': cardCode,
      };

  factory PromptOption.fromJson(Map<String, dynamic> j) => PromptOption(
        j['id'] as String,
        j['label'] as String,
        subtitle: j['subtitle'] as String?,
        cardCode: j['cardCode'] as String?,
      );
}

class PromptSpec {
  final String promptId;
  final PromptKind kind;
  final String title;
  final List<PromptOption> options;

  /// Whether the player may decline / pass / continue without choosing.
  final bool optional;

  final int deadlineMs; // epoch millis when the default fires

  /// Betting context (only for [PromptKind.bettingAction]).
  final int? callAmount;
  final int? minRaiseTo;
  final int? maxRaiseTo;
  final bool canRaise;

  /// Deck-build context (only for [PromptKind.deckBuild]).
  final int? deckTarget;

  const PromptSpec({
    required this.promptId,
    required this.kind,
    required this.title,
    this.options = const [],
    this.optional = false,
    required this.deadlineMs,
    this.callAmount,
    this.minRaiseTo,
    this.maxRaiseTo,
    this.canRaise = false,
    this.deckTarget,
  });

  Map<String, dynamic> toJson() => {
        'promptId': promptId,
        'kind': kind.name,
        'title': title,
        'options': [for (final o in options) o.toJson()],
        'optional': optional,
        'deadlineMs': deadlineMs,
        if (callAmount != null) 'callAmount': callAmount,
        if (minRaiseTo != null) 'minRaiseTo': minRaiseTo,
        if (maxRaiseTo != null) 'maxRaiseTo': maxRaiseTo,
        'canRaise': canRaise,
        if (deckTarget != null) 'deckTarget': deckTarget,
      };

  factory PromptSpec.fromJson(Map<String, dynamic> j) => PromptSpec(
        promptId: j['promptId'] as String,
        kind: promptKindFromName(j['kind'] as String),
        title: j['title'] as String,
        options: [
          for (final o in (j['options'] as List? ?? []))
            PromptOption.fromJson(o as Map<String, dynamic>)
        ],
        optional: j['optional'] as bool? ?? false,
        deadlineMs: j['deadlineMs'] as int,
        callAmount: j['callAmount'] as int?,
        minRaiseTo: j['minRaiseTo'] as int?,
        maxRaiseTo: j['maxRaiseTo'] as int?,
        canRaise: j['canRaise'] as bool? ?? false,
        deckTarget: j['deckTarget'] as int?,
      );
}

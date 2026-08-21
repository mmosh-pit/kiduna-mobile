/// Per-player view of the table, produced by the server's `serializeFor(player)`
/// and rendered by the client. It carries ONLY what the viewing player is
/// allowed to see: their own hole cards / power hand / items, plus public
/// information. Opponents' hole cards are sent as [CardCode.hidden] ("??").
library;

/// One seat as seen by the viewer.
class SeatSnapshot {
  final int seat;
  final String name;
  final int stack;
  final bool folded;
  final bool allIn;
  final bool eliminated;
  final bool heatingUp;
  final bool tilted;
  final bool isDealer;
  final bool isActing;
  final bool isAI;
  final int compChips;
  final int tokenCount;
  final int roundBet;
  final String? lastAction;

  /// Hole-card codes from the viewer's perspective: real codes for the viewer's
  /// own seat (or cards revealed to them); [CardCode.hidden] for everyone else.
  /// List length always equals the seat's real hole-card count.
  final List<String> holeCards;

  const SeatSnapshot({
    required this.seat,
    required this.name,
    required this.stack,
    required this.folded,
    required this.allIn,
    required this.eliminated,
    required this.heatingUp,
    required this.tilted,
    required this.isDealer,
    required this.isActing,
    required this.isAI,
    required this.compChips,
    required this.tokenCount,
    required this.roundBet,
    required this.lastAction,
    required this.holeCards,
  });

  Map<String, dynamic> toJson() => {
        'seat': seat,
        'name': name,
        'stack': stack,
        'folded': folded,
        'allIn': allIn,
        'eliminated': eliminated,
        'heatingUp': heatingUp,
        'tilted': tilted,
        'isDealer': isDealer,
        'isActing': isActing,
        'isAI': isAI,
        'compChips': compChips,
        'tokenCount': tokenCount,
        'roundBet': roundBet,
        'lastAction': lastAction,
        'holeCards': holeCards,
      };

  factory SeatSnapshot.fromJson(Map<String, dynamic> j) => SeatSnapshot(
        seat: j['seat'] as int,
        name: j['name'] as String,
        stack: j['stack'] as int,
        folded: j['folded'] as bool,
        allIn: j['allIn'] as bool,
        eliminated: j['eliminated'] as bool,
        heatingUp: j['heatingUp'] as bool,
        tilted: j['tilted'] as bool,
        isDealer: j['isDealer'] as bool,
        isActing: j['isActing'] as bool,
        isAI: j['isAI'] as bool,
        compChips: j['compChips'] as int,
        tokenCount: j['tokenCount'] as int,
        roundBet: j['roundBet'] as int,
        lastAction: j['lastAction'] as String?,
        holeCards: (j['holeCards'] as List).cast<String>(),
      );
}

/// A Power Card in the viewer's own hand (safe to reveal to them).
class PowerCardView {
  final String templateId;
  final String name;
  final String description;
  final String timing; // 'setup' | 'round' | 'showdown' | 'counter'

  const PowerCardView(this.templateId, this.name, this.description, this.timing);

  Map<String, dynamic> toJson() => {
        'id': templateId,
        'name': name,
        'desc': description,
        'timing': timing,
      };

  factory PowerCardView.fromJson(Map<String, dynamic> j) => PowerCardView(
        j['id'] as String,
        j['name'] as String,
        j['desc'] as String,
        j['timing'] as String,
      );
}

/// A held Item in the viewer's hole (safe to reveal to them).
class ItemView {
  final String id;
  final String name;
  final String description;
  final bool playable; // active/in-pot → can be played on your turn

  const ItemView(this.id, this.name, this.description, this.playable);

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'desc': description, 'playable': playable};

  factory ItemView.fromJson(Map<String, dynamic> j) => ItemView(
        j['id'] as String,
        j['name'] as String,
        j['desc'] as String,
        j['playable'] as bool,
      );
}

/// The full table state as seen by one player.
class TableSnapshot {
  final String roomId;
  final int viewerSeat;
  final int handNumber;
  final List<SeatSnapshot> seats;
  final List<String> board; // public community card codes
  final int pot;
  final int ante;
  final int level;
  final bool inSuddenDeath;
  final int suddenDeathHand; // 1-based, 0 if not in Sudden Death
  final int? levelSecondsLeft; // timed levels (null = untimed)
  final String street; // Street enum name
  final List<PowerCardView> yourPowerHand;
  final List<ItemView> yourItems;
  final List<String> logTail; // recent narration lines

  // The viewer's OWN Power Deck breakdown (safe to reveal to them). Draw-deck
  // order is hidden (name-sorted) so it can't be used to foresee draws.
  final List<PowerCardView> yourDrawDeck;
  final List<PowerCardView> yourDiscard;
  final List<PowerCardView> yourOneShot;

  const TableSnapshot({
    required this.roomId,
    required this.viewerSeat,
    required this.handNumber,
    required this.seats,
    required this.board,
    required this.pot,
    required this.ante,
    required this.level,
    required this.inSuddenDeath,
    required this.suddenDeathHand,
    required this.levelSecondsLeft,
    required this.street,
    required this.yourPowerHand,
    required this.yourItems,
    required this.logTail,
    this.yourDrawDeck = const [],
    this.yourDiscard = const [],
    this.yourOneShot = const [],
  });

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'viewerSeat': viewerSeat,
        'handNumber': handNumber,
        'seats': [for (final s in seats) s.toJson()],
        'board': board,
        'pot': pot,
        'ante': ante,
        'level': level,
        'inSuddenDeath': inSuddenDeath,
        'suddenDeathHand': suddenDeathHand,
        'levelSecondsLeft': levelSecondsLeft,
        'street': street,
        'yourPowerHand': [for (final c in yourPowerHand) c.toJson()],
        'yourItems': [for (final i in yourItems) i.toJson()],
        'logTail': logTail,
        if (yourDrawDeck.isNotEmpty)
          'yourDrawDeck': [for (final c in yourDrawDeck) c.toJson()],
        if (yourDiscard.isNotEmpty)
          'yourDiscard': [for (final c in yourDiscard) c.toJson()],
        if (yourOneShot.isNotEmpty)
          'yourOneShot': [for (final c in yourOneShot) c.toJson()],
      };

  static List<PowerCardView> _cards(dynamic v) => [
        for (final c in (v as List? ?? const []))
          PowerCardView.fromJson(c as Map<String, dynamic>)
      ];

  factory TableSnapshot.fromJson(Map<String, dynamic> j) => TableSnapshot(
        roomId: j['roomId'] as String,
        viewerSeat: j['viewerSeat'] as int,
        handNumber: j['handNumber'] as int,
        seats: [
          for (final s in (j['seats'] as List))
            SeatSnapshot.fromJson(s as Map<String, dynamic>)
        ],
        board: (j['board'] as List).cast<String>(),
        pot: j['pot'] as int,
        ante: j['ante'] as int,
        level: j['level'] as int,
        inSuddenDeath: j['inSuddenDeath'] as bool,
        suddenDeathHand: j['suddenDeathHand'] as int,
        levelSecondsLeft: j['levelSecondsLeft'] as int?,
        street: j['street'] as String,
        yourPowerHand: [
          for (final c in (j['yourPowerHand'] as List))
            PowerCardView.fromJson(c as Map<String, dynamic>)
        ],
        yourItems: [
          for (final i in (j['yourItems'] as List))
            ItemView.fromJson(i as Map<String, dynamic>)
        ],
        logTail: (j['logTail'] as List).cast<String>(),
        yourDrawDeck: _cards(j['yourDrawDeck']),
        yourDiscard: _cards(j['yourDiscard']),
        yourOneShot: _cards(j['yourOneShot']),
      );
}

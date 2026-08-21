/// Item / Token cards. Items are one-shot cards granted "from the bank" by
/// Power Cards; Tokens are permanent effects that stay with a player.
///
/// NOTE: the printed cards assume items are held in hand and played like Round
/// cards, sit in hole cards, or ride in the pot. To keep the economy tractable
/// this build resolves an item's effect **immediately when granted** (card-like
/// items add to the hole), and models Tokens as persistent per-player effects
/// checked at Setup / play-time / pot-resolution. Effects are approximations of
/// the printed text where a deeper subsystem would be required.
enum ItemType { magic, merchant, noble, rogue, token, merchantToken }

/// When an Item card's effect happens.
enum ItemTiming {
  /// Played from hand on your turn, like a Round card.
  active,

  /// Resolves immediately when granted (e.g. Spare Change on draw).
  onGrant,

  /// Held; triggers automatically at showdown / on fold (e.g. Lucky Charm).
  showdown,

  /// Held; triggers when you win a showdown (e.g. Snake Oil).
  onWin,

  /// Played into the pot; affects whoever wins that pot (e.g. Fool's Gold).
  inPot,
}

class GameItem {
  final String id;
  final String name;
  final String description;
  final ItemType type;
  final ItemTiming timing;

  const GameItem({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.timing = ItemTiming.active,
  });

  bool get isToken => type == ItemType.token || type == ItemType.merchantToken;
}

class Items {
  // ── Items (one-shot) ────────────────────────────────────────────────
  static const monkeyPaw = GameItem(
    id: 'monkey_paw',
    name: 'Monkey Paw',
    description: 'Gain a hole card and draw a Power Card.',
    type: ItemType.magic,
  );
  static const rabbitFoot = GameItem(
    id: 'rabbit_foot',
    name: 'Rabbit Foot',
    description: 'Gain a hole card; re-deal a low board card.',
    type: ItemType.magic,
  );
  static const luckyCharm = GameItem(
    id: 'lucky_charm',
    name: 'Lucky Charm',
    description:
        'Showdown: gain 2 hole cards. If you fold holding it, you\'re Heating '
        'Up.',
    type: ItemType.merchant,
    timing: ItemTiming.showdown,
  );
  static const snakeOil = GameItem(
    id: 'snake_oil',
    name: 'Snake Oil',
    description: 'Win a showdown holding it → draw 2 Power Cards.',
    type: ItemType.merchant,
    timing: ItemTiming.onWin,
  );
  static const foolsGold = GameItem(
    id: 'fools_gold',
    name: 'Fool\'s Gold',
    description:
        'Put it in the pot as 10 coins. Whoever wins that pot is Tilted.',
    type: ItemType.merchant,
    timing: ItemTiming.inPot,
  );
  static const spareChange = GameItem(
    id: 'spare_change',
    name: 'Spare Change',
    description: 'When drawn: discard for 5 coins (10 as a Merchant or Noble).',
    type: ItemType.noble,
    timing: ItemTiming.onGrant,
  );
  static const grapplingHook = GameItem(
    id: 'grappling_hook',
    name: 'Grappling Hook',
    description: 'Steal a hole card from a Tilted opponent (else gain one).',
    type: ItemType.rogue,
  );
  static const smokeBomb = GameItem(
    id: 'smoke_bomb',
    name: 'Smoke Bomb',
    description: 'Fold. Cold opponents discard a Power Card. You\'re Stealthed.',
    type: ItemType.rogue,
  );
  static const healingPotion = GameItem(
    id: 'healing_potion',
    name: 'Healing Potion',
    description: 'Draw 1 (draw 2 + Heating Up if Tilted).',
    type: ItemType.rogue,
  );
  static const counterfeitAce = GameItem(
    id: 'counterfeit_ace',
    name: 'Counterfeit Ace',
    description: 'Adds an Ace of Spades to your hole cards.',
    type: ItemType.rogue,
  );

  // ── Tokens (permanent) ─────────────────────────────────────────────
  static const wanted = GameItem(
    id: 'wanted',
    name: 'Most Wanted',
    description: 'When you lose a pot, the winner gains 20 and others draw 1.',
    type: ItemType.token,
  );
  static const merchStockpile = GameItem(
    id: 'merch_stockpile',
    name: 'Merch Stockpile',
    description: 'During Setup, gain a random Merchant Item.',
    type: ItemType.token,
  );
  static const insideConnections = GameItem(
    id: 'inside_connections',
    name: 'Inside Connections',
    description: 'When you win a pot, gain a Merchant Item.',
    type: ItemType.token,
  );
  static const crystalBall = GameItem(
    id: 'crystal_ball',
    name: 'Crystal Ball',
    description: 'Draw an extra Power Card at Setup.',
    type: ItemType.merchantToken,
  );
  static const cursedAmulet = GameItem(
    id: 'cursed_amulet',
    name: 'Cursed Amulet',
    description: 'Play Fire cards while Tilted; extra hole card if Tilted at Setup.',
    type: ItemType.merchantToken,
  );
  static const treasureGoblin = GameItem(
    id: 'treasure_goblin',
    name: 'Treasure Goblin',
    description: 'You\'re Heating Up at Setup.',
    type: ItemType.merchantToken,
  );

  static const all = [
    monkeyPaw, rabbitFoot, luckyCharm, snakeOil, foolsGold, spareChange,
    grapplingHook, smokeBomb, healingPotion, counterfeitAce,
    wanted, merchStockpile, insideConnections, crystalBall, cursedAmulet,
    treasureGoblin,
  ];

  static GameItem? byId(String id) {
    for (final it in all) {
      if (it.id == id) return it;
    }
    return null;
  }

  static List<GameItem> ofType(ItemType t) =>
      all.where((it) => it.type == t).toList();

  /// Items that are not Magic Items (used by the reworked Trading Up).
  static List<GameItem> get nonMagicItems => all
      .where((it) =>
          !it.isToken &&
          it.type != ItemType.magic)
      .toList();

  static List<GameItem> get merchantTokens => ofType(ItemType.merchantToken);
}

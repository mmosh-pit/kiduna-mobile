import 'package:flutter/material.dart';

import 'package:medieval_poker_engine/medieval_poker_engine.dart';
import 'medieval_poker_game.dart';

const _gold = Color(0xFFEDC169);
const _panel = Color(0xF21B140C);
const _panelBorder = Color(0xFF6B5533);

/// Flutter overlay drawn above the Flame table. Reads [MedievalPokerGame.view]
/// and shows the status banner, the action bar on the human's turn, and the
/// game-over panel.
class PokerHud extends StatelessWidget {
  final MedievalPokerGame game;
  final VoidCallback onExit;

  const PokerHud({super.key, required this.game, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PokerViewState>(
      valueListenable: game.view,
      builder: (context, v, _) {
        return Stack(
          children: [
            _ExitButton(onExit: onExit),
            if (!v.showClassSelect && !v.showCourtSelect && !v.gameOver)
              _EventLog(game: game),
            if (!v.showClassSelect && !v.showCourtSelect && !v.gameOver)
              _PowerHandFan(game: game),
            if (!v.showClassSelect && !v.gameOver) _StageChip(game: game),
            if (!v.showClassSelect &&
                !v.showCourtSelect &&
                !v.showDeckBuild &&
                !v.gameOver)
              _DeckButton(game: game),
            if (!v.showClassSelect &&
                !v.showCourtSelect &&
                !v.showDeckBuild &&
                !v.gameOver)
              _ReferenceButton(game: game),
            if (v.banner.isNotEmpty && !v.gameOver) _Banner(text: v.banner),
            if (!v.showClassSelect && !v.showCourtSelect && !v.gameOver)
              _PeekToast(game: game),
            _DeckViewer(game: game),
            if (v.showActions && !v.gameOver)
              Align(
                alignment: Alignment.bottomCenter,
                child: _ActionBar(game: game, view: v),
              ),
            if (v.showPower && !v.gameOver)
              Align(
                alignment: Alignment.bottomCenter,
                child: _PowerPanel(game: game, view: v),
              ),
            if (v.showItemPlay && !v.gameOver)
              Align(
                alignment: Alignment.bottomCenter,
                child: _ItemPanel(game: game, view: v),
              ),
            if (v.showItemMode && !v.gameOver)
              Align(
                alignment: Alignment.bottomCenter,
                child: _ItemModePanel(game: game, view: v),
              ),
            if (v.showTarget && !v.gameOver)
              Align(
                alignment: Alignment.bottomCenter,
                child: _TargetPanel(game: game, view: v),
              ),
            if (v.showPayChoice && !v.gameOver)
              Align(
                alignment: Alignment.bottomCenter,
                child: _PayChoicePanel(game: game, view: v),
              ),
            if (v.showChipSell && !v.gameOver)
              Align(
                alignment: Alignment.bottomCenter,
                child: _ChipSellPanel(game: game, view: v),
              ),
            if (!v.gameOver && !v.showClassSelect && !v.showCourtSelect)
              _HandResultFlash(game: game),
            if (v.showClassSelect && !v.gameOver)
              _ChoicePanel(
                title: 'Choose Your Class',
                subtitle: 'Your class adds 12 cards to your Power Deck.',
                options: v.classOptions,
                onPick: game.submitClassChoice,
              ),
            if (v.showCourtSelect && !v.gameOver)
              _ChoicePanel(
                title: 'Choose Your Court',
                subtitle: 'Your Court adds 9 cards to your Power Deck.',
                options: v.courtOptions,
                onPick: game.submitCourtChoice,
              ),
            if (v.showDeckBuild && !v.gameOver)
              _DeckBuilder(game: game, view: v),
            if (v.gameOver)
              _GameOver(view: v, onPlayAgain: game.restart, onExit: onExit),
            // Rules Reference renders last so it overlays everything (panels,
            // banner, pickers, game-over).
            _ReferenceViewer(game: game),
          ],
        );
      },
    );
  }
}

/// Button to open the in-game Power Deck viewer.
class _DeckButton extends StatelessWidget {
  final MedievalPokerGame game;
  const _DeckButton({required this.game});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 40;
    return Positioned(
      top: top,
      right: 8,
      child: GestureDetector(
        onTap: game.toggleDeckView,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _panelBorder),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🂠', style: TextStyle(fontSize: 14)),
              SizedBox(width: 5),
              Text('Deck',
                  style: TextStyle(
                      color: _gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Button to open the in-game rules Reference.
class _ReferenceButton extends StatelessWidget {
  final MedievalPokerGame game;
  const _ReferenceButton({required this.game});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 76;
    return Positioned(
      top: top,
      right: 8,
      child: GestureDetector(
        onTap: game.toggleReference,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _panelBorder),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('❔', style: TextStyle(fontSize: 13)),
              SizedBox(width: 5),
              Text('Rules',
                  style: TextStyle(
                      color: _gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen rules Reference — the physical reference cards, as swipeable
/// pages (Hand Rankings, Poker Terms, Game Terms, Abilities).
class _ReferenceViewer extends StatelessWidget {
  final MedievalPokerGame game;
  const _ReferenceViewer({required this.game});

  static const _pages = [
    ('Hand Rankings', 'assets/medieval_poker/reference/hand_rankings.png'),
    ('Poker Terms', 'assets/medieval_poker/reference/poker_terms.png'),
    ('Game Terms', 'assets/medieval_poker/reference/game_terms.png'),
    ('Abilities', 'assets/medieval_poker/reference/abilities.png'),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: game.showReference,
      builder: (context, open, _) {
        if (!open) return const SizedBox.shrink();
        final top = MediaQuery.paddingOf(context).top;
        final bottom = MediaQuery.paddingOf(context).bottom;
        final controller = PageController();
        return Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.9),
            padding: EdgeInsets.only(top: top + 8, bottom: bottom + 8),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
                  child: Row(
                    children: [
                      const Text('Rules Reference',
                          style: TextStyle(
                              fontFamily: 'GoudyHeavyface',
                              fontSize: 22,
                              color: _gold)),
                      const Spacer(),
                      IconButton(
                        onPressed: game.toggleReference,
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: controller,
                    itemCount: _pages.length,
                    itemBuilder: (context, i) {
                      final (title, path) = _pages[i];
                      return Column(
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  color: Color(0xFFC79BE6),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Expanded(
                            child: InteractiveViewer(
                              minScale: 1,
                              maxScale: 4,
                              child: Image.asset(path, fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Center(
                                        child: Text('Reference unavailable',
                                            style: TextStyle(
                                                color: Colors.white54)),
                                      )),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Swipe for more  ·  pinch to zoom',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Full-screen viewer of the human's Power Deck, grouped by location.
class _DeckViewer extends StatelessWidget {
  final MedievalPokerGame game;
  const _DeckViewer({required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: game.showDeck,
      builder: (context, open, _) {
        if (!open) return const SizedBox.shrink();
        final sections = game.powerDeckView();
        final total =
            sections.fold<int>(0, (sum, s) => sum + s.cards.length);
        final top = MediaQuery.paddingOf(context).top;
        final bottom = MediaQuery.paddingOf(context).bottom;
        return Positioned.fill(
          child: GestureDetector(
            onTap: game.toggleDeckView,
            child: Container(
              color: Colors.black.withValues(alpha: 0.86),
              padding: EdgeInsets.only(top: top + 8, bottom: bottom + 8),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(
                      children: [
                        const Text(
                          'Your Power Deck',
                          style: TextStyle(
                            fontFamily: 'GoudyHeavyface',
                            fontSize: 22,
                            color: _gold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('$total cards',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                        const Spacer(),
                        IconButton(
                          onPressed: game.toggleDeckView,
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        for (final s in sections)
                          if (s.cards.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 10, bottom: 4, left: 4),
                              child: Text(
                                '${s.label}  ·  ${s.cards.length}',
                                style: const TextStyle(
                                  color: _gold,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            for (final c in s.cards) _DeckViewRow(card: c),
                          ],
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DeckViewRow extends StatelessWidget {
  final DeckCardInfo card;
  const _DeckViewRow({required this.card});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          _PowerCardThumb(templateId: card.templateId),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(card.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF33291C),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: _panelBorder),
                      ),
                      child: Text(card.timing,
                          style:
                              const TextStyle(color: _gold, fontSize: 9)),
                    ),
                  ],
                ),
                Text(card.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Scrolling feed narrating every engine action (so all the depth is visible).
class _EventLog extends StatelessWidget {
  final MedievalPokerGame game;
  const _EventLog({required this.game});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 42;
    final width = MediaQuery.sizeOf(context).width * 0.5;
    return Positioned(
      left: 6,
      top: top,
      width: width,
      child: IgnorePointer(
        child: ValueListenableBuilder<List<String>>(
          valueListenable: game.log,
          builder: (context, lines, _) {
            final recent =
                lines.length > 9 ? lines.sublist(lines.length - 9) : lines;
            if (recent.isEmpty) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.34),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < recent.length; i++)
                    Text(
                      recent[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: i == recent.length - 1
                            ? const Color(0xFFEDC169)
                            : Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A prominent centered flash showing the human's win/lose result each hand.
class _HandResultFlash extends StatelessWidget {
  final MedievalPokerGame game;
  const _HandResultFlash({required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HandResult?>(
      valueListenable: game.handResult,
      builder: (context, r, _) {
        if (r == null) return const SizedBox.shrink();
        final win = r.won;
        final headline = win ? 'You Win the Hand' : 'You Lose the Hand';
        final color = win ? const Color(0xFF3FA96A) : const Color(0xFFB3261E);
        return IgnorePointer(
          child: Align(
            alignment: const Alignment(0, -0.15),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              builder: (context, t, child) => Transform.scale(
                scale: 0.8 + 0.2 * t.clamp(0.0, 1.0),
                child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xF21B140C),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 22,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(win ? '🏆' : '🥀',
                        style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 6),
                    Text(
                      headline,
                      style: TextStyle(
                        fontFamily: 'GoudyHeavyface',
                        fontSize: 26,
                        color: color == const Color(0xFF3FA96A)
                            ? const Color(0xFF7FE0A6)
                            : const Color(0xFFF3A0A0),
                      ),
                    ),
                    if (r.detail.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        r.detail,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Transient PEEK reveal (secret information shown to the human).
class _PeekToast extends StatelessWidget {
  final MedievalPokerGame game;
  const _PeekToast({required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: game.peek,
      builder: (context, text, _) {
        if (text.isEmpty) return const SizedBox.shrink();
        return Align(
          alignment: const Alignment(0, -0.35),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xF22A1F33),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF7A3E9D), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔮  ', style: TextStyle(fontSize: 16)),
                Flexible(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFC79BE6),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StageChip extends StatelessWidget {
  final MedievalPokerGame game;
  const _StageChip({required this.game});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 4;
    return Positioned(
      top: top,
      right: 8,
      child: ValueListenableBuilder<String>(
        valueListenable: game.stage,
        builder: (context, s, _) {
          if (s.isEmpty) return const SizedBox.shrink();
          final sudden = s.contains('SUDDEN');
          return ValueListenableBuilder<int>(
            valueListenable: game.levelClock,
            builder: (context, secs, _) {
              final clock = (!sudden && secs > 0)
                  ? '  ${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}'
                  : '';
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _panel,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: sudden ? const Color(0xFFB3261E) : _panelBorder,
                  ),
                ),
                child: Text(
                  '$s$clock',
                  style: TextStyle(
                    color: sudden ? const Color(0xFFF3A0A0) : _gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String text;
  const _Banner({required this.text});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 6;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _panelBorder),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: _gold,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatefulWidget {
  final MedievalPokerGame game;
  final PokerViewState view;
  const _ActionBar({required this.game, required this.view});

  @override
  State<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends State<_ActionBar> {
  bool _raiseOpen = false;
  double _raiseTo = 0;

  @override
  Widget build(BuildContext context) {
    final v = widget.view;
    final bottom = MediaQuery.paddingOf(context).bottom + 12;
    final isBet = v.callAmount == 0;
    final min = v.minRaiseTo.toDouble();
    final max = v.maxRaiseTo.toDouble();
    final canSlide = max > min;
    final target = _raiseTo.clamp(min, max).round();

    return Padding(
      padding: EdgeInsets.only(bottom: bottom, left: 12, right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_raiseOpen && v.canRaise)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _panelBorder),
              ),
              child: Row(
                children: [
                  Text('${isBet ? 'Bet' : 'Raise to'}  $target',
                      style: const TextStyle(color: _gold, fontSize: 14)),
                  Expanded(
                    child: Slider(
                      value: target.toDouble().clamp(min, max),
                      min: min,
                      max: max,
                      activeColor: _gold,
                      inactiveColor: Colors.white24,
                      onChanged: canSlide
                          ? (val) => setState(() => _raiseTo = val)
                          : null,
                    ),
                  ),
                  _MiniButton(
                    label: 'Confirm',
                    onTap: () {
                      widget.game.submitHumanAction(
                        isBet
                            ? PokerAction.bet(target)
                            : PokerAction.raise(target),
                      );
                      setState(() => _raiseOpen = false);
                    },
                  ),
                ],
              ),
            ),
          Row(
            children: [
              if (v.canCall)
                Expanded(
                  child: _ActionButton(
                    label: 'Fold',
                    color: const Color(0xFF7A2E2E),
                    onTap: () =>
                        widget.game.submitHumanAction(const PokerAction.fold()),
                  ),
                ),
              if (v.canCall) const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: v.canCheck ? 'Check' : 'Call ${v.callAmount}',
                  color: const Color(0xFF2E5A44),
                  onTap: () => widget.game.submitHumanAction(
                    v.canCheck
                        ? const PokerAction.check()
                        : const PokerAction.call(),
                  ),
                ),
              ),
              if (v.canRaise) const SizedBox(width: 8),
              if (v.canRaise)
                Expanded(
                  child: _ActionButton(
                    label: isBet ? 'Bet' : 'Raise',
                    color: const Color(0xFF9A6B1E),
                    onTap: () => setState(() {
                      _raiseOpen = !_raiseOpen;
                      _raiseTo = min;
                    }),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PowerPanel extends StatelessWidget {
  final MedievalPokerGame game;
  final PokerViewState view;
  const _PowerPanel({required this.game, required this.view});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 12;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom, left: 12, right: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF7A3E9D)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              view.powerTitle,
              style: const TextStyle(
                color: Color(0xFFC79BE6),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < view.powerOptions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _PowerCardTile(
                  option: view.powerOptions[i],
                  onTap: () => game.submitPowerChoice(i),
                ),
              ),
            const SizedBox(height: 2),
            _ActionButton(
              label: view.powerDismissLabel,
              color: const Color(0xFF2E5A44),
              onTap: () => game.submitPowerChoice(-1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prompt: play a held Item card (like a Round card).
class _ItemPanel extends StatelessWidget {
  final MedievalPokerGame game;
  final PokerViewState view;
  const _ItemPanel({required this.game, required this.view});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 12;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom, left: 12, right: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF7FD0E0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Your Items',
              style: TextStyle(
                color: Color(0xFFCFEAF2),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < view.itemOptions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _PowerCardTile(
                  option: view.itemOptions[i],
                  onTap: () => game.submitItemChoice(i),
                ),
              ),
            const SizedBox(height: 2),
            _ActionButton(
              label: 'Continue',
              color: const Color(0xFF2E5A44),
              onTap: () => game.submitItemChoice(-1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prompt: choose a mode for a multi-mode Item (e.g. Monkey Paw).
class _ItemModePanel extends StatelessWidget {
  final MedievalPokerGame game;
  final PokerViewState view;
  const _ItemModePanel({required this.game, required this.view});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 12;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom, left: 12, right: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF7FD0E0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              view.itemModeTitle,
              style: const TextStyle(
                color: Color(0xFFCFEAF2),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < view.itemModeOptions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: const Color(0xFF1E3A4A),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => game.submitItemMode(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: const Color(0xFF7FD0E0)),
                      ),
                      child: Text(
                        view.itemModeOptions[i],
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Prompt: sell a Comp Chip to the bank for coins (Midas Crown, at Setup).
class _ChipSellPanel extends StatelessWidget {
  final MedievalPokerGame game;
  final PokerViewState view;
  const _ChipSellPanel({required this.game, required this.view});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 12;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom, left: 12, right: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF7FD0E0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Midas Crown — sell a Comp Chip for ${view.chipSellValue} coins? '
              '(◉ ${view.compChips})',
              style: const TextStyle(
                color: Color(0xFFCFEAF2),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Keep',
                    color: const Color(0xFF2E5A44),
                    onTap: () => game.submitChipSell(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: 'Sell ◉  (+${view.chipSellValue})',
                    color: const Color(0xFF1E5A6E),
                    onTap: () => game.submitChipSell(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Prompt: pay a Power Card's cost with coins or a Comp Chip.
class _PayChoicePanel extends StatelessWidget {
  final MedievalPokerGame game;
  final PokerViewState view;
  const _PayChoicePanel({required this.game, required this.view});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 12;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom, left: 12, right: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF7FD0E0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${view.payCardName}: pay ${view.payCost} coins?',
              style: const TextStyle(
                color: Color(0xFFCFEAF2),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Pay ${view.payCost} coins',
                    color: const Color(0xFF2E5A44),
                    onTap: () => game.submitPayChoice(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: '◉ Comp Chip  (${view.compChips})',
                    color: const Color(0xFF1E5A6E),
                    onTap: () => game.submitPayChoice(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Panel for choosing an opponent to target (no "pass" — a pick is required).
class _TargetPanel extends StatelessWidget {
  final MedievalPokerGame game;
  final PokerViewState view;
  const _TargetPanel({required this.game, required this.view});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 12;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom, left: 12, right: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFB3401E)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              view.targetTitle,
              style: const TextStyle(
                color: Color(0xFFF3C0A0),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < view.targetOptions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _TargetTile(
                  option: view.targetOptions[i],
                  onTap: () => game.submitTargetChoice(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Deck-builder: choose which Power Cards go into your Power Deck.
class _DeckBuilder extends StatefulWidget {
  final MedievalPokerGame game;
  final PokerViewState view;
  const _DeckBuilder({required this.game, required this.view});

  @override
  State<_DeckBuilder> createState() => _DeckBuilderState();
}

class _DeckBuilderState extends State<_DeckBuilder> {
  late final Set<String> _selected;

  int get _target => widget.view.deckTarget;
  List<DeckCardInfo> get _pool => widget.view.deckPool;

  @override
  void initState() {
    super.initState();
    // Pre-select a sensible default deck (the first [_target] cards in pool
    // order: Neutrals, then Class, then Court).
    _selected = _pool.take(_target).map((c) => c.templateId).toSet();
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else if (_selected.length < _target) {
        _selected.add(id);
      }
    });
  }

  void _autoFill() {
    setState(() {
      for (final c in _pool) {
        if (_selected.length >= _target) break;
        _selected.add(c.templateId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ready = _selected.length == _target;
    final groups = ['Neutral', 'Class', 'Court'];
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      color: Colors.black.withValues(alpha: 0.86),
      padding: EdgeInsets.only(top: top + 8, bottom: bottom + 8),
      child: Column(
        children: [
          // Header.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              children: [
                const Text(
                  'Build Your Power Deck',
                  style: TextStyle(
                    fontFamily: 'GoudyHeavyface',
                    fontSize: 24,
                    color: _gold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap cards to add or remove. Choose $_target.',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          // Scrollable grouped card list.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final g in groups) ...[
                  _groupHeader(g),
                  for (final c in _pool.where((c) => c.group == g))
                    _DeckCardRow(
                      card: c,
                      selected: _selected.contains(c.templateId),
                      atCap: _selected.length >= _target,
                      onTap: () => _toggle(c.templateId),
                    ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
          // Footer: count + actions.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: Row(
              children: [
                Text(
                  '${_selected.length} / $_target',
                  style: TextStyle(
                    color: ready ? const Color(0xFF7FE0A6) : _gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                if (_selected.length < _target)
                  TextButton(
                    onPressed: _autoFill,
                    child: const Text('Auto-fill',
                        style: TextStyle(color: Color(0xFFC79BE6))),
                  ),
                const SizedBox(width: 6),
                FilledButton(
                  onPressed:
                      ready ? () => widget.game.submitDeckChoice(_selected.toList()) : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white24,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  ),
                  child: const Text('Play',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupHeader(String g) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4, left: 4),
        child: Text(
          '$g Cards',
          style: const TextStyle(
            color: _gold,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      );
}

class _DeckCardRow extends StatelessWidget {
  final DeckCardInfo card;
  final bool selected;
  final bool atCap;
  final VoidCallback onTap;
  const _DeckCardRow({
    required this.card,
    required this.selected,
    required this.atCap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dim = !selected && atCap;
    return Opacity(
      opacity: dim ? 0.45 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Material(
          color: selected ? const Color(0xFF2E2140) : const Color(0xFF1B140C),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFC79BE6)
                      : const Color(0xFF4A3A28),
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Row(
                children: [
                  _PowerCardThumb(templateId: card.templateId),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                card.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _timingChip(card.timing),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          card.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_outline_rounded,
                    color: selected
                        ? const Color(0xFF7FE0A6)
                        : Colors.white38,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _timingChip(String timing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF33291C),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _panelBorder),
      ),
      child: Text(timing,
          style: const TextStyle(color: _gold, fontSize: 9)),
    );
  }
}

/// Pre-match deck-building picker (used for both Class and Court).
class _ChoicePanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<TargetOption> options;
  final void Function(int) onPick;
  const _ChoicePanel({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.78),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _panelBorder, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'GoudyHeavyface',
                  fontSize: 26,
                  color: _gold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 14),
              for (int i = 0; i < options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TargetTile(
                    option: options[i],
                    onTap: () => onPick(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetTile extends StatelessWidget {
  final TargetOption option;
  final VoidCallback onTap;
  const _TargetTile({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF33241C),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFB3401E)),
          ),
          child: Row(
            children: [
              const Icon(Icons.gps_fixed_rounded,
                  color: Color(0xFFF3C0A0), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      option.subtitle,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The human's Power Card hand, drawn as a fanned row at the bottom.
class _PowerHandFan extends StatelessWidget {
  final MedievalPokerGame game;
  const _PowerHandFan({required this.game});

  static const _cardW = 44.0;
  static const _cardH = 66.0;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 66;
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
      height: 96,
      child: ValueListenableBuilder<List<PowerOption>>(
        valueListenable: game.hand,
        builder: (context, hand, _) {
          if (hand.isEmpty) return const SizedBox.shrink();
          return LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final n = hand.length;
              final mid = (n - 1) / 2.0;
              final spacing = n <= 1
                  ? 0.0
                  : ((w - _cardW - 24) / (n - 1)).clamp(16.0, 30.0);
              final center = w / 2;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  for (int i = 0; i < n; i++)
                    _fanned(hand[i], i - mid, mid == 0 ? 1 : mid, center,
                        spacing),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _fanned(PowerOption card, double off, double span, double center,
      double spacing) {
    final x = center + off * spacing - _cardW / 2;
    final angle = (off / span) * 0.18;
    final dip = (off * off) / (span * span) * 14.0;
    return Positioned(
      left: x,
      top: 20 + dip,
      child: Transform.rotate(
        angle: angle,
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.asset(
              'assets/medieval_poker/power/${card.templateId}.png',
              width: _cardW,
              height: _cardH,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => Container(
                width: _cardW,
                height: _cardH,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1F33),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFF7A3E9D)),
                ),
                child: const Center(
                  child: Text('★',
                      style: TextStyle(color: Color(0xFFC79BE6))),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card-art thumbnail for a Power Card, falling back to a ★ if art is missing.
class _PowerCardThumb extends StatelessWidget {
  final String templateId;
  const _PowerCardThumb({required this.templateId});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(
        'assets/medieval_poker/power/$templateId.png',
        width: 46,
        height: 74,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        // Power art missing → try the Item art, then a ★ placeholder.
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/medieval_poker/items/$templateId.png',
          width: 46,
          height: 74,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => const SizedBox(
            width: 46,
            height: 74,
            child: Center(
              child: Text('★',
                  style: TextStyle(color: Color(0xFFC79BE6), fontSize: 18)),
            ),
          ),
        ),
      ),
    );
  }
}

class _PowerCardTile extends StatelessWidget {
  final PowerOption option;
  final VoidCallback onTap;
  const _PowerCardTile({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2A1F33),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF7A3E9D)),
          ),
          child: Row(
            children: [
              _PowerCardThumb(templateId: option.templateId),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      option.description,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_arrow_rounded,
                  color: Color(0xFFC79BE6), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MiniButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _gold,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1B140C),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _GameOver extends StatelessWidget {
  final PokerViewState view;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;
  const _GameOver(
      {required this.view, required this.onPlayAgain, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.all(28),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _panelBorder, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              view.won ? 'Victory' : 'Defeat',
              style: TextStyle(
                fontFamily: 'GoudyHeavyface',
                fontSize: 34,
                color: view.won ? _gold : const Color(0xFFB3261E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              view.resultText,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MiniButton(label: 'Play Again', onTap: onPlayAgain),
                const SizedBox(width: 12),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: onExit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _panelBorder),
                      ),
                      child: const Text('Leave',
                          style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExitButton extends StatelessWidget {
  final VoidCallback onExit;
  const _ExitButton({required this.onExit});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Positioned(
      top: topPadding + 2,
      left: 4,
      child: GestureDetector(
        onTap: onExit,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}

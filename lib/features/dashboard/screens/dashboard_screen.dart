import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../config/assets.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/ki_composer.dart';
import '../../blocks/widgets/blocks_layout.dart';
import '../../compute/controllers/compute_controller.dart';
import '../../compute/open_buy_kiduna.dart';
import '../../field/controllers/field_controller.dart';
import '../../field/data/field_fixtures.dart';
import '../../ki_chat/controllers/ally_controller.dart';
import '../../ki_chat/controllers/ki_chat_controller.dart';
import '../controllers/ecosystem_controller.dart';

const Color _bgCanvas = Color(0xFF0A0E10);
const Color _teal = Color(0xFF03CCD9);
const Color _cream = Color(0xFFF2EADF);
const Color _muted = Color(0xFF9E8E78);
const Color _barBg = Color(0xFF0D0F10);
const Color _barBorder = Color(0xFF1A1E22);
const Color _chipBorder = Color(0xFF223038);
const Color _chipHover = Color(0xFF03CCD9);
const Color _greenDot = Color(0xFF4CAF50);
const Color _goldWarn = Color(0xFFEDC169);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({
    super.key, this.initialTab = 0, this.startGameInLobby = false,
    this.cellRealmId, this.joinTicket,
  });
  final int initialTab;
  final bool startGameInLobby;
  final String? cellRealmId;
  final Object? joinTicket;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _composer = TextEditingController();
  bool _historyRequested = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(ecosystemControllerProvider.notifier).loadEcosystem();
      ref.read(computeControllerProvider.notifier).loadBalance();
    });
  }

  @override
  void dispose() { _composer.dispose(); super.dispose(); }

  void _onAllyReady() {
    if (_historyRequested) return;
    _historyRequested = true;
    ref.read(kiChatControllerProvider.notifier).loadHistory();
  }

  void _send() {
    final t = _composer.text.trim();
    if (t.isEmpty) return;
    _composer.clear();
    ref.read(kiChatControllerProvider.notifier).sendMessage(t);
  }

  @override
  Widget build(BuildContext context) {
    final allyState = ref.watch(allyControllerProvider);
    final chatState = ref.watch(kiChatControllerProvider);
    final fieldState = ref.watch(fieldControllerProvider);
    final ecoState = ref.watch(ecosystemControllerProvider);
    final ctrl = ref.read(fieldControllerProvider.notifier);

    if (allyState.ally != null && !_historyRequested) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onAllyReady());
    }

    final realm = fieldState.currentRealm;
    final ecoName = ecoState.ecosystem?.name ?? 'Kinship Duna';
    final actions = FieldFixtures.actions;

    final List<BlockItem> items = [
      // Welcome.
      BlockItem(
        id: 'welcome', priority: 9,
        tealLabel: 'WELCOME · ${ecoName.toUpperCase()}',
        title: "There's a place for\nthe way you work.",
        description: 'Everything starts here. Shape your field, invite '
            'others, and let Ki guide you through what comes next.',
        quoteText: 'Welcome to $ecoName. This is your space to build, '
            'connect, and create something meaningful.',
        quoteFrom: 'KI · TO YOU',
        buttons: [
          BlockButton(label: 'Step into the Field', primary: true,
            onTap: () => ctrl.toggleInspect()),
          BlockButton(label: 'Look around first', onTap: () {}),
          BlockButton(label: 'Ask Ki',
            onTap: () => _composer.text = 'What can I do here?'),
        ],
      ),

      // Ecosystem.
      BlockItem(
        id: 'ecosystem', priority: 7,
        tealLabel: 'ECOSYSTEM',
        title: realm.name.isNotEmpty ? realm.name : ecoName,
        description: 'Your root ecosystem. All realms, power maps, '
            'and projects exist within this field.',
        activityText: 'Conversation active now',
        bottomButtonLabel: 'Enter',
        onTap: () => ctrl.toggleInspect(),
      ),

      // Invite.
      BlockItem(
        id: 'invite', priority: 6,
        tealLabel: 'INVITATION',
        title: 'Invite people to\njoin you here',
        description: 'Prepare a Kiduna Invitation and bring '
            'someone into your field.',
        bottomButtonLabel: 'Create Invitation',
        onTap: () {
          final a = actions.firstWhere((a) => a.id == 'invite');
          ctrl.chooseAction(a);
        },
      ),

      // Form Realm.
      BlockItem(
        id: 'realm', priority: 6,
        tealLabel: 'CREATE',
        title: 'Form a New Realm',
        description: 'Start something new — a project, community, '
            'or alliance.',
        bottomButtonLabel: 'Create Realm',
        onTap: () {
          final a = actions.firstWhere((a) => a.id == 'realm');
          ctrl.chooseAction(a);
        },
      ),

      // Game.
      BlockItem(
        id: 'game', priority: 5,
        tealLabel: 'GAME',
        title: 'Royals & Rogues',
        description: 'Medieval poker with power cards, streaks, '
            'and class abilities.',
        activityText: 'Play alone or invite others',
        bottomButtonLabel: 'Play',
        onTap: () => ref.read(kiChatControllerProvider.notifier)
            .sendMessage('I want to play a game'),
      ),

      // Alliance.
      BlockItem(
        id: 'alliance', priority: 4,
        tealLabel: 'COMMUNITY',
        title: 'Alliances',
        description: 'Form or join alliances with shared wallets '
            'and governance.',
        bottomButtonLabel: 'Explore',
        onTap: () => ref.read(kiChatControllerProvider.notifier)
            .sendMessage('Show me alliances'),
      ),

      // Shape.
      BlockItem(
        id: 'shape', priority: 3,
        tealLabel: 'CONFIGURE',
        title: 'Shape $ecoName',
        description: 'Adjust capacities, presence, and connections.',
        bottomButtonLabel: 'Configure',
        onTap: () {
          final a = actions.firstWhere((a) => a.id == 'shape');
          ctrl.chooseAction(a);
        },
      ),

      // Present.
      BlockItem(
        id: 'present', priority: 2,
        tealLabel: 'SHARE',
        title: 'Present $ecoName',
        description: 'Share your ecosystem with the world.',
        bottomButtonLabel: 'Present',
        onTap: () {
          final a = actions.firstWhere((a) => a.id == 'present');
          ctrl.chooseAction(a);
        },
      ),
    ];

    items.sort((a, b) => b.priority.compareTo(a.priority));

    return Scaffold(
      backgroundColor: _bgCanvas,
      body: Column(
        children: [
          const AppHeader(),
          _ContextHeader(ecoName: ecoName),
          Expanded(child: BlocksCanvasLayout(items: items)),
          _KaiBar(chatState: chatState, allyState: allyState,
            composer: _composer, onSend: _send, ecoName: ecoName),
        ],
      ),
    );
  }
}

// ── Context header ───────────────────────────────────────────────────

class _ContextHeader extends StatelessWidget {
  const _ContextHeader({required this.ecoName});
  final String ecoName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 4),
      color: _bgCanvas,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('FIELD CANVAS', style: TextStyle(
                fontFamily: 'Avenir', fontSize: 10, fontWeight: FontWeight.w700,
                color: _teal, letterSpacing: 1.5)),
              SizedBox(height: 3),
              Text('Anything can enter here.', style: TextStyle(
                fontFamily: 'GoudyHeavyface', fontSize: 18,
                fontWeight: FontWeight.w400, color: _cream)),
            ],
          ),
          const Spacer(),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(
              color: _teal, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text('CONTEXT · ${ecoName.toUpperCase()}', style: TextStyle(
              fontFamily: 'Avenir', fontSize: 10, fontWeight: FontWeight.w600,
              color: _teal.withValues(alpha: 0.7), letterSpacing: 0.8)),
          ]),
        ],
      ),
    );
  }
}

// ── Kai bar ──────────────────────────────────────────────────────────

class _KaiBar extends ConsumerWidget {
  const _KaiBar({required this.chatState, required this.allyState,
    required this.composer, required this.onSend, required this.ecoName});

  final dynamic chatState;
  final dynamic allyState;
  final TextEditingController composer;
  final VoidCallback onSend;
  final String ecoName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streaming = chatState.isStreaming as bool;
    final ooB = chatState.outOfBalance as bool;
    final blocked = ref.watch(chatBlockedProvider) as bool;
    final kc = ref.read(kiChatControllerProvider.notifier);

    return Container(
      decoration: const BoxDecoration(color: _barBg,
        border: Border(top: BorderSide(color: _barBorder)),
        boxShadow: [BoxShadow(offset: Offset(0, -4), blurRadius: 20,
          color: Color(0x40000000))]),
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!ooB && !blocked)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final l in const [
                        "show me what's already moving",
                        'i want to help people find a place to contribute',
                        'create something new',
                      ]) ...[
                        _Chip(label: l, onTap: () => kc.sendMessage(l)),
                        const SizedBox(width: 8),
                      ],
                    ]),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(
                    color: _greenDot, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _greenDot, blurRadius: 4)])),
                  const SizedBox(width: 8),
                  Text('ENTERING ${ecoName.toUpperCase()}', style: TextStyle(
                    fontFamily: 'Avenir', fontSize: 9, fontWeight: FontWeight.w700,
                    color: _muted.withValues(alpha: 0.5), letterSpacing: 1.0)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ooB || blocked
                  ? _OutOfKiduna(ref: ref)
                  : Row(children: [
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _teal.withValues(alpha: 0.2)),
                          boxShadow: [BoxShadow(color: _teal.withValues(alpha: 0.06), blurRadius: 8)],
                        ),
                        child: ClipOval(child: ColoredBox(color: const Color(0xFF111518),
                          child: Center(child: SvgPicture.asset(AppAssets.kidunaMark, width: 18, height: 18)))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: KiComposer(
                        controller: composer, onSend: onSend,
                        enabled: !streaming && !(chatState.isLoading as bool) && allyState.ally != null,
                      )),
                    ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatefulWidget {
  const _Chip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override State<_Chip> createState() => _ChipState();
}
class _ChipState extends State<_Chip> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _h ? _teal.withValues(alpha: 0.06) : Colors.transparent,
            border: Border.all(color: _h ? _chipHover : _chipBorder),
            borderRadius: BorderRadius.circular(999)),
          child: Text(widget.label, style: TextStyle(fontFamily: 'Avenir',
            fontSize: 12, color: _h ? _teal : _cream.withValues(alpha: 0.5))))));
  }
}

class _OutOfKiduna extends StatelessWidget {
  const _OutOfKiduna({required this.ref});
  final WidgetRef ref;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _goldWarn.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _goldWarn.withValues(alpha: 0.25))),
      child: Row(children: [
        const Icon(Icons.bolt_outlined, size: 16, color: _goldWarn),
        const SizedBox(width: 8),
        const Expanded(child: Text('Out of KIDUNA. Top up to keep chatting.',
          style: TextStyle(fontFamily: 'Avenir', fontSize: 11, color: _muted))),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            await openBuyKidunaPage(context);
            if (!context.mounted) return;
            await ref.read(computeControllerProvider.notifier).refresh();
            if (!context.mounted) return;
            if (ref.read(computeControllerProvider).balance > 0)
              ref.read(kiChatControllerProvider.notifier).clearOutOfBalance();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _goldWarn.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _goldWarn.withValues(alpha: 0.4))),
            child: const Text('Buy KIDUNA', style: TextStyle(fontFamily: 'Avenir',
              fontSize: 11, fontWeight: FontWeight.w700, color: _goldWarn)))),
      ]));
  }
}
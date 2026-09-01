import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../config/assets.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/ki_composer.dart';
import '../../alliance/screens/alliance_list_screen.dart';
import '../../blocks/widgets/blocks_layout.dart';
import '../../compute/controllers/compute_controller.dart';
import '../../compute/open_buy_kiduna.dart';
import '../../field/controllers/field_controller.dart';
import '../../field/data/field_fixtures.dart';
import '../../field/widgets/invite_panel.dart';
import '../../field/widgets/realm_panel.dart';
import '../../game/screens/game_screen.dart';
import '../../ki_chat/controllers/ally_controller.dart';
import '../../ki_chat/controllers/ki_chat_controller.dart';
import '../controllers/ecosystem_controller.dart';

const Color _bgCanvas = Color(0xFF0C0914);
const Color _teal = Color(0xFF03C7D5);
const Color _cream = Color(0xFFE8E0D4);
const Color _muted = Color(0xFF8A7E72);
const Color _quiet = Color(0xFF4A4440);
const Color _chipBorder = Color(0xFF2A2235);
const Color _greenDot = Color(0xFF4CAF50);
const Color _goldWarn = Color(0xFFEDC169);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({
    super.key, this.initialTab = 0, this.startGameInLobby = false,
    this.cellRealmId, this.joinTicket,
  });
  final int initialTab; final bool startGameInLobby;
  final String? cellRealmId; final Object? joinTicket;
  @override ConsumerState<DashboardScreen> createState() => _State();
}

class _State extends ConsumerState<DashboardScreen> {
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

  @override void dispose() { _composer.dispose(); super.dispose(); }

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

  void _openWrapped(String title, Widget child) {
    Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => _WrappedScreen(title: title, child: child)));
  }

  void _openPanel(Widget panel) {
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true,
      backgroundColor: const Color(0xFF15121D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7, maxChildSize: 0.9, minChildSize: 0.4, expand: false,
        builder: (ctx, sc) => SingleChildScrollView(
          controller: sc, padding: const EdgeInsets.all(24), child: panel)));
  }

  /// Returns the next child type based on current realm type.
  String _childType(String parentType) {
    switch (parentType) {
      case 'Ecosystem': return 'Organization';
      case 'Organization': return 'Program';
      case 'Program': return 'Cell';
      default: return 'Organization';
    }
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
    final realmName = realm.name.isNotEmpty ? realm.name : ecoName;
    final realmType = realm.type;
    final isRoot = realmName == 'Kinship Duna' || realmName == ecoName;
    final isCell = realmType == 'Cell';
    final childType = _childType(realmType);
    final actions = FieldFixtures.actions;

    // ── Build contextual blocks ──────────────────────────────────────

    final List<BlockItem> items = [];

    // ── ALWAYS: Welcome card (only at root/ecosystem level) ──────────
    if (isRoot) {
      items.add(BlockItem(
        id: 'welcome', priority: 9,
        tealLabel: 'PERSONAL WELCOME · FROM KI',
        title: "There's a place for\nthe way you work.",
        description: 'Ki has opened a way into $ecoName — not a blank '
            'account, but living work you can see before choosing where to stand.',
        quoteText: 'Welcome to $ecoName. This is your space to build, '
            'connect, and create something meaningful.',
        quoteFrom: 'KI · TO YOU',
        buttons: [
          BlockButton(label: 'Step into the Field', primary: true,
            onTap: () => ctrl.toggleInspect()),
          BlockButton(label: 'Ask Ki',
            onTap: () => _composer.text = 'What can I do here?'),
        ],
      ));
    }

    // ── ALWAYS: Current realm info card ──────────────────────────────
    items.add(BlockItem(
      id: 'realm', priority: isRoot ? 7 : 9,
      tealLabel: realmType.toUpperCase(),
      title: realmName,
      description: _realmDescription(realmType, realmName),
      activityText: 'Conversation active now',
      bottomButtonLabel: 'Enter',
      onBottomButtonTap: () => ctrl.toggleInspect(),
    ));

    // ── ALWAYS: Invite ───────────────────────────────────────────────
    items.add(BlockItem(
      id: 'invite', priority: 6,
      tealLabel: 'INVITATION',
      title: 'Invite people to\njoin $realmName',
      description: 'Prepare a Kiduna Invitation and bring '
          'someone into ${isRoot ? 'your field' : realmName}.',
      bottomButtonLabel: 'Create Invitation',
      onBottomButtonTap: () => _openPanel(InvitePanel(askAbout: ctrl.askAbout)),
    ));

    // ── ALWAYS (except Cell): Create next level ──────────────────────
    if (!isCell) {
      items.add(BlockItem(
        id: 'create', priority: 6,
        tealLabel: 'CREATE',
        title: 'Form a New\n$childType',
        description: _createDescription(childType),
        bottomButtonLabel: 'Create $childType',
        onBottomButtonTap: () => _openPanel(const RealmPanel()),
      ));
    }

    // ── ONLY when inside a real realm (not root): Shape ──────────────
    if (!isRoot) {
      items.add(BlockItem(
        id: 'shape', priority: 4,
        tealLabel: 'CONFIGURE',
        title: 'Shape $realmName',
        description: 'Adjust capacities, presence, and connections for $realmName.',
        bottomButtonLabel: 'Configure',
        onBottomButtonTap: () {
          final a = actions.firstWhere((a) => a.id == 'shape');
          ctrl.chooseAction(a);
        },
      ));
    }

    // ── ONLY when inside a real realm: Present ───────────────────────
    if (!isRoot) {
      items.add(BlockItem(
        id: 'present', priority: 3,
        tealLabel: 'SHARE',
        title: 'Present $realmName',
        description: 'Share $realmName with the world and attract new members.',
        bottomButtonLabel: 'Present',
        onBottomButtonTap: () {
          final a = actions.firstWhere((a) => a.id == 'present');
          ctrl.chooseAction(a);
        },
      ));
    }

    // ── ONLY when inside a realm: Game ───────────────────────────────
    if (!isRoot) {
      items.add(BlockItem(
        id: 'game', priority: 5,
        tealLabel: 'GAME',
        title: 'Royals & Rogues',
        description: 'Medieval poker with power cards, streaks, and class abilities.',
        activityText: 'Play alone or invite others',
        bottomButtonLabel: 'Play',
        onBottomButtonTap: () => _openWrapped('Royals & Rogues', GameScreen(
          startInLobby: widget.startGameInLobby,
          cellRealmId: widget.cellRealmId,
          joinTicket: widget.joinTicket)),
      ));
    }

    // ── ONLY when inside a realm: Alliance ───────────────────────────
    if (!isRoot) {
      items.add(BlockItem(
        id: 'alliance', priority: 4,
        tealLabel: 'COMMUNITY',
        title: 'Alliances',
        description: 'Form or join alliances with shared wallets and governance.',
        bottomButtonLabel: 'Explore',
        onBottomButtonTap: () => _openWrapped('Alliances', const AllianceListScreen()),
      ));
    }

    items.sort((a, b) => b.priority.compareTo(a.priority));

    // ── Breadcrumb for navigation ────────────────────────────────────
    final showBack = fieldState.enteredRealmId != null;

    return Scaffold(
      backgroundColor: _bgCanvas,
      body: Column(children: [
        const AppHeader(),
        _ContextHeader(
          realmName: realmName,
          realmType: realmType,
          showBack: showBack,
          onBack: () => ctrl.exitEnteredRealm(),
        ),
        Expanded(child: BlocksCanvasLayout(items: items)),
        _KaiSection(chatState: chatState, allyState: allyState,
          composer: _composer, onSend: _send, realmName: realmName),
      ]),
    );
  }

  String _realmDescription(String type, String name) {
    switch (type) {
      case 'Ecosystem':
        return 'Your root ecosystem. All organizations, programs, and cells exist within this field.';
      case 'Organization':
        return 'People are shaping $name into a place where real work happens and new members find their place.';
      case 'Program':
        return '$name is a focused initiative with tasks, members, and resources working toward a shared goal.';
      case 'Cell':
        return 'A small, trusted group working closely together on a shared objective within $name.';
      default:
        return 'Explore $name and see what\'s happening.';
    }
  }

  String _createDescription(String childType) {
    switch (childType) {
      case 'Organization':
        return 'Create an organization within your ecosystem — a team, community, or alliance.';
      case 'Program':
        return 'Start a focused program — a project, initiative, or workstream.';
      case 'Cell':
        return 'Form a small trusted group to work closely on a specific task.';
      default:
        return 'Start something new.';
    }
  }
}

// ── Wrapped screen with back button ──────────────────────────────────

class _WrappedScreen extends StatelessWidget {
  const _WrappedScreen({required this.title, required this.child});
  final String title; final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCanvas,
      appBar: AppBar(
        backgroundColor: _bgCanvas, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _cream),
          onPressed: () => Navigator.of(context).pop()),
        title: Text(title, style: const TextStyle(
          fontFamily: 'Avenir', fontSize: 16, fontWeight: FontWeight.w600, color: _cream)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _quiet.withValues(alpha: 0.15))),
      ),
      body: child,
    );
  }
}

// ── Context header with breadcrumb ───────────────────────────────────

class _ContextHeader extends StatelessWidget {
  const _ContextHeader({
    required this.realmName, required this.realmType,
    required this.showBack, required this.onBack,
  });
  final String realmName, realmType;
  final bool showBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 24, 6),
      color: _bgCanvas,
      child: Row(children: [
        // Back button when inside a sub-realm.
        if (showBack) ...[
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _cream.withValues(alpha: 0.04)),
              child: Icon(Icons.arrow_back_rounded, size: 18,
                color: _cream.withValues(alpha: 0.6))),
          ),
          const SizedBox(width: 8),
        ] else
          const SizedBox(width: 12),

        // Left: label + title.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              showBack ? '${realmType.toUpperCase()} CANVAS' : 'FIELD CANVAS',
              style: const TextStyle(fontFamily: 'Avenir', fontSize: 10,
                fontWeight: FontWeight.w700, color: _teal, letterSpacing: 1.5)),
            const SizedBox(height: 2),
            Text(
              showBack ? realmName : 'Anything can enter here.',
              style: TextStyle(
                fontFamily: 'GoudyHeavyface',
                fontSize: showBack ? 16 : 20,
                fontWeight: FontWeight.w400, color: _cream)),
          ],
        ),
        const Spacer(),
        // Right: context badge.
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(
            color: _teal, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('${realmType.toUpperCase()} · ${realmName.toUpperCase()}',
            style: TextStyle(fontFamily: 'Avenir', fontSize: 9,
              fontWeight: FontWeight.w600,
              color: _teal.withValues(alpha: 0.5), letterSpacing: 0.8)),
        ]),
      ]),
    );
  }
}

// ── Ki section ───────────────────────────────────────────────────────

class _KaiSection extends ConsumerWidget {
  const _KaiSection({required this.chatState, required this.allyState,
    required this.composer, required this.onSend, required this.realmName});
  final dynamic chatState, allyState;
  final TextEditingController composer;
  final VoidCallback onSend;
  final String realmName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streaming = chatState.isStreaming as bool;
    final ooB = chatState.outOfBalance as bool;
    final blocked = ref.watch(chatBlockedProvider) as bool;
    final kc = ref.read(kiChatControllerProvider.notifier);
    final msgs = chatState.messages as List<ChatMessageModel>;

    String preview;
    if (streaming && (chatState.streamingBuffer as String).isNotEmpty) {
      preview = chatState.streamingBuffer as String;
    } else if (msgs.isNotEmpty) { preview = msgs.last.content; }
    else { preview = 'Welcome to $realmName. What would you like to change today?'; }
    if (preview.length > 150) preview = '${preview.substring(0, 147)}…';

    return Container(
      decoration: BoxDecoration(
        color: _bgCanvas,
        border: Border(top: BorderSide(color: _teal.withValues(alpha: 0.1), width: 1)),
        boxShadow: [BoxShadow(offset: const Offset(0, -8), blurRadius: 24,
          color: Colors.black.withValues(alpha: 0.4))]),
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ki message.
              Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 34, height: 34, margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      border: Border.all(color: _teal.withValues(alpha: 0.15)),
                      boxShadow: [BoxShadow(color: _teal.withValues(alpha: 0.05), blurRadius: 10)]),
                    child: ClipOval(child: ColoredBox(color: const Color(0xFF13101B),
                      child: Center(child: SvgPicture.asset(AppAssets.kidunaMark, width: 18, height: 18))))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Text('Ki', style: TextStyle(fontFamily: 'Avenir', fontSize: 14,
                        fontWeight: FontWeight.w700, color: _cream)),
                      const SizedBox(width: 8),
                      if (streaming) Text('typing…', style: TextStyle(fontFamily: 'Avenir',
                        fontSize: 11, color: _teal.withValues(alpha: 0.5))),
                    ]),
                    const SizedBox(height: 4),
                    Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'Avenir', fontSize: 14,
                        color: _muted.withValues(alpha: 0.85), height: 1.5)),
                  ])),
                ])),

              // Chips.
              if (!ooB && !blocked)
                Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: SingleChildScrollView(scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final l in const [
                        "show me what's already moving",
                        'i want to help people find a place to contribute',
                        'create something new',
                      ]) ...[_Chip(label: l, onTap: () => kc.sendMessage(l)), const SizedBox(width: 8)],
                    ]))),

              // Context badge.
              Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Row(children: [
                  Container(width: 7, height: 7, decoration: const BoxDecoration(
                    color: _greenDot, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _greenDot, blurRadius: 5)])),
                  const SizedBox(width: 9),
                  Text('ENTERING ${realmName.toUpperCase()}', style: TextStyle(fontFamily: 'Avenir',
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: _muted.withValues(alpha: 0.4), letterSpacing: 1.0)),
                ])),

              // Input.
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ooB || blocked
                  ? _OutOfKiduna(ref: ref)
                  : KiComposer(controller: composer, onSend: onSend,
                      enabled: !streaming && !(chatState.isLoading as bool) && allyState.ally != null)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatefulWidget {
  const _Chip({required this.label, required this.onTap});
  final String label; final VoidCallback onTap;
  @override State<_Chip> createState() => _ChipState();
}
class _ChipState extends State<_Chip> {
  bool _h = false;
  @override Widget build(BuildContext context) {
    return MouseRegion(cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true), onExit: (_) => setState(() => _h = false),
      child: GestureDetector(onTap: widget.onTap,
        child: AnimatedContainer(duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _h ? _teal.withValues(alpha: 0.05) : Colors.transparent,
            border: Border.all(color: _h ? _teal.withValues(alpha: 0.35) : _chipBorder),
            borderRadius: BorderRadius.circular(999)),
          child: Text(widget.label, style: TextStyle(fontFamily: 'Avenir',
            fontSize: 12, color: _h ? _teal : _cream.withValues(alpha: 0.4))))));
  }
}

class _OutOfKiduna extends StatelessWidget {
  const _OutOfKiduna({required this.ref}); final WidgetRef ref;
  @override Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: _goldWarn.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
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
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: _goldWarn.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _goldWarn.withValues(alpha: 0.4))),
            child: const Text('Buy KIDUNA', style: TextStyle(fontFamily: 'Avenir',
              fontSize: 11, fontWeight: FontWeight.w700, color: _goldWarn)))),
      ]));
  }
}

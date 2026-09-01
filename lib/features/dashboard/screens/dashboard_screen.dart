import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../config/assets.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/models/ki_topic.dart';
import '../../../data/models/realm_model.dart';
import '../../../data/services/realm_service.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/ki_composer.dart';
import '../../alliance/screens/alliance_list_screen.dart';
import '../../blocks/widgets/blocks_layout.dart';
import '../../compute/controllers/compute_controller.dart';
import '../../compute/open_buy_kiduna.dart';
import '../../field/controllers/field_controller.dart';
import '../../field/widgets/invite_panel.dart';
import '../../field/widgets/realm_panel.dart';
import '../../game/screens/game_screen.dart';
import '../../ki_chat/controllers/ally_controller.dart';
import '../../ki_chat/controllers/ki_chat_controller.dart';
import '../controllers/ecosystem_controller.dart';

// ── PDF palette ──────────────────────────────────────────────────────

const Color _bg = Color(0xFF0C0914);
const Color _teal = Color(0xFF03C7D5);
const Color _cardTop = Color(0xFF1D1725);
const Color _cream = Color(0xFFE8E0D4);
const Color _muted = Color(0xFF8A7E72);
const Color _quiet = Color(0xFF4A4440);
const Color _chipBorder = Color(0xFF2A2235);
const Color _greenDot = Color(0xFF4CAF50);
const Color _goldWarn = Color(0xFFEDC169);

// ═════════════════════════════════════════════════════════════════════

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({
    super.key,
    this.initialTab = 0,
    this.startGameInLobby = false,
    this.cellRealmId,
    this.joinTicket,
  });
  final int initialTab;
  final bool startGameInLobby;
  final String? cellRealmId;
  final Object? joinTicket;

  @override
  ConsumerState<DashboardScreen> createState() => _State();
}

class _State extends ConsumerState<DashboardScreen> {
  final TextEditingController _composer = TextEditingController();
  bool _historyRequested = false;

  // Navigation stack.
  final List<_NavEntry> _navStack = [];
  List<RealmModel> _children = [];
  bool _loadingChildren = false;

  // Transition key — forces rebuild for animation on enter/back.
  int _transitionKey = 0;

  bool get _isAtRoot => _navStack.isEmpty;
  _NavEntry? get _currentNav => _navStack.isEmpty ? null : _navStack.last;

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
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

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

  // ── Navigation ─────────────────────────────────────────────────────

  Future<void> _enter(String id, String name, String type) async {
    _navStack.add(_NavEntry(id: id, name: name, type: type));
    ref.read(fieldControllerProvider.notifier).enterRealm(id, name);
    setState(() {
      _loadingChildren = true;
      _transitionKey++;
    });
    try {
      final children = await RealmService.instance.fetchRealmChildren(id);
      if (mounted) {
        setState(() {
          _children = children;
          _loadingChildren = false;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to load children', tag: 'Dashboard', error: e);
      if (mounted) {
        setState(() {
          _children = [];
          _loadingChildren = false;
        });
      }
    }
  }

  void _goBack() {
    if (_navStack.isEmpty) return;
    _navStack.removeLast();
    _transitionKey++;

    if (_navStack.isEmpty) {
      ref.read(fieldControllerProvider.notifier).exitEnteredRealm();
      setState(() {
        _children = [];
        _loadingChildren = false;
      });
    } else {
      final prev = _navStack.last;
      ref.read(fieldControllerProvider.notifier).enterRealm(prev.id, prev.name);
      _fetchChildren(prev.id);
    }
  }

  Future<void> _fetchChildren(String id) async {
    setState(() => _loadingChildren = true);
    try {
      final children = await RealmService.instance.fetchRealmChildren(id);
      if (mounted) {
        setState(() {
          _children = children;
          _loadingChildren = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _children = [];
          _loadingChildren = false;
        });
      }
    }
  }

  // ── + Menu ─────────────────────────────────────────────────────────

  void _showPlusMenu() {
    final realmType = _currentNav?.type ?? 'Ecosystem';
    final realmName = _currentNav?.name ?? 'Kinship Duna';
    final isCell = realmType.toLowerCase() == 'cell';
    final ctrl = ref.read(fieldControllerProvider.notifier);
    final currentId = _currentNav?.id ??
        ref.read(fieldControllerProvider).currentRealmId;

    final actions = <_PlusAction>[];

    // Create next level (contextual label).
    if (!isCell) {
      final child = _childType(realmType);
      actions.add(_PlusAction(
        icon: Icons.add_circle_outline_rounded,
        label: 'Create $child',
        subtitle: _createSubtitle(child),
        onTap: () => _openLargePanel(
          RealmPanel(
            initialType: child,
            initialParentId: currentId,
            onCreated: () {
              _fetchChildren(currentId);
            },
          ),
        ),
      ));
    }

    // Invite.
    actions.add(_PlusAction(
      icon: Icons.mail_outline_rounded,
      label: 'Invite to $realmName',
      subtitle: 'Send an invitation',
      onTap: () => _openSmallPanel(InvitePanel(askAbout: ctrl.askAbout)),
    ));

    // Shape (not at root).
    if (!_isAtRoot) {
      actions.add(_PlusAction(
        icon: Icons.tune_rounded,
        label: 'Shape $realmName',
        subtitle: 'Configure capacities',
        onTap: () {
          ctrl.askAbout(KiTopic(body: 'Shape and configure $realmName.'));
        },
      ));
    }

    // Game.
    if (!_isAtRoot && !isCell) {
      actions.add(_PlusAction(
        icon: Icons.sports_esports_outlined,
        label: 'Play a Game',
        subtitle: 'Royals & Rogues',
        onTap: () => _openWrapped(
          'Royals & Rogues',
          GameScreen(
            startInLobby: widget.startGameInLobby,
            cellRealmId: widget.cellRealmId,
            joinTicket: widget.joinTicket,
          ),
        ),
      ));
    }

    // Alliance.
    if (!_isAtRoot && !isCell) {
      actions.add(_PlusAction(
        icon: Icons.people_outline_rounded,
        label: 'Explore Alliances',
        subtitle: 'Form or join',
        onTap: () => _openWrapped(
          'Alliances',
          const AllianceListScreen(),
        ),
      ));
    }

    // Show bottom sheet.
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: _cardTop,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _teal.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle.
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _quiet.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            for (final a in actions)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    a.onTap();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            color: _teal.withValues(alpha: 0.07),
                            border: Border.all(
                                color: _teal.withValues(alpha: 0.12)),
                          ),
                          child: Icon(a.icon, size: 18, color: _teal),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.label,
                                style: const TextStyle(
                                  fontFamily: 'Avenir',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _cream,
                                ),
                              ),
                              if (a.subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  a.subtitle!,
                                  style: TextStyle(
                                    fontFamily: 'Avenir',
                                    fontSize: 12,
                                    color: _muted.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: _quiet.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  void _openWrapped(String title, Widget child) {
    Navigator.of(context).push<void>(
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => _WrappedScreen(title: title, child: child),
        transitionsBuilder: (context, anim, secondAnim, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _openSmallPanel(Widget panel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF15121D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: panel,
        ),
      ),
    );
  }

  void _openLargePanel(Widget panel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF15121D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, sc) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            controller: sc,
            padding: const EdgeInsets.all(24),
            child: panel,
          ),
        ),
      ),
    );
  }

  String _childType(String parentType) {
    switch (parentType.toLowerCase()) {
      case 'ecosystem':
        return 'Organization';
      case 'organization':
        return 'Program';
      case 'program':
        return 'Cell';
      default:
        return 'Organization';
    }
  }

  String _createSubtitle(String childType) {
    switch (childType) {
      case 'Organization':
        return 'Start a team, community, or alliance';
      case 'Program':
        return 'Start a focused initiative';
      case 'Cell':
        return 'Form a small trusted group';
      default:
        return 'Start something new';
    }
  }

  String _realmDesc(String type, String name) {
    switch (type.toLowerCase()) {
      case 'ecosystem':
        return 'Your root ecosystem. All organizations, programs, and cells live here.';
      case 'organization':
        return 'People are shaping $name into a place where real work happens.';
      case 'program':
        return 'A focused initiative with tasks, members, and shared goals.';
      case 'cell':
        return 'A small, trusted group working closely on a shared objective.';
      default:
        return 'Explore $name.';
    }
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final allyState = ref.watch(allyControllerProvider);
    final chatState = ref.watch(kiChatControllerProvider);
    final ecoState = ref.watch(ecosystemControllerProvider);

    if (allyState.ally != null && !_historyRequested) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onAllyReady());
    }

    final ecoName = ecoState.ecosystem?.name ?? 'Kinship Duna';
    final navName = _currentNav?.name ?? ecoName;
    final navType = _currentNav?.type ?? 'Ecosystem';

    // ── Build block items ────────────────────────────────────────────

    final List<BlockItem> items = [];

    if (_isAtRoot) {
      // Root: single Ecosystem card.
      items.add(BlockItem(
        id: 'ecosystem',
        tealLabel: 'ECOSYSTEM',
        title: ecoName,
        description: _realmDesc('Ecosystem', ecoName),
        activityText: 'Conversation active now',
        bottomButtonLabel: 'Enter',
        onBottomButtonTap: () {
          final id = ecoState.ecosystem?.id;
          if (id != null) _enter(id, ecoName, 'Ecosystem');
        },
      ));
    } else if (_loadingChildren) {
      // Loading state.
      items.add(const BlockItem(
        id: 'loading',
        tealLabel: 'LOADING',
        title: 'Loading…',
        description: 'Fetching content…',
      ));
    } else {
      // Filter hierarchy types only.
      final hierarchyTypes = {'organization', 'program', 'cell'};
      final filtered = _children
          .where((c) => hierarchyTypes.contains(c.type.toLowerCase()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (filtered.isEmpty) {
        // Empty state.
        final child = _childType(navType);
        items.add(BlockItem(
          id: 'empty',
          tealLabel: navType.toUpperCase(),
          title: navName,
          description:
              'Nothing here yet.\nTap + to create your first ${child.toLowerCase()}.',
          activityText: 'Ready for you to begin',
        ));
      } else {
        for (final c in filtered) {
          items.add(BlockItem(
            id: 'child-${c.id}',
            tealLabel: c.type.toUpperCase(),
            title: c.name,
            description:
                c.purpose ?? c.description ?? _realmDesc(c.type, c.name),
            activityText: c.status == 'active' ? 'Active now' : null,
            bottomButtonLabel: 'Enter',
            onBottomButtonTap: () => _enter(c.id, c.name, c.type),
          ));
        }
      }
    }

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          const AppHeader(),
          _Header(
            name: navName,
            type: navType,
            showBack: !_isAtRoot,
            onBack: _goBack,
          ),
          // Animated content swap.
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: BlocksCanvasLayout(
                key: ValueKey(_transitionKey),
                items: items,
              ),
            ),
          ),
          _KaiSection(
            chatState: chatState,
            allyState: allyState,
            composer: _composer,
            onSend: _send,
            realmName: navName,
            onPlus: _showPlusMenu,
          ),
        ],
      ),
    );
  }
}

// ── Models ───────────────────────────────────────────────────────────

class _NavEntry {
  const _NavEntry(
      {required this.id, required this.name, required this.type});
  final String id, name, type;
}

class _PlusAction {
  const _PlusAction(
      {required this.icon,
      required this.label,
      this.subtitle,
      required this.onTap});
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
}

// ── Wrapped screen ───────────────────────────────────────────────────

class _WrappedScreen extends StatelessWidget {
  const _WrappedScreen({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _cream),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Avenir',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _cream,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1, color: _quiet.withValues(alpha: 0.12)),
        ),
      ),
      body: child,
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.type,
    required this.showBack,
    required this.onBack,
  });
  final String name, type;
  final bool showBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 24, 10),
      decoration: BoxDecoration(
        color: _bg,
        border: Border(
          bottom: BorderSide(color: _quiet.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          if (showBack) ...[
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _cream.withValues(alpha: 0.04),
                  border:
                      Border.all(color: _quiet.withValues(alpha: 0.12)),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: _cream.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(width: 14),
          ] else
            const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  showBack
                      ? '${type.toUpperCase()} CANVAS'
                      : 'FIELD CANVAS',
                  style: const TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _teal,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  showBack ? name : 'Anything can enter here.',
                  style: TextStyle(
                    fontFamily: 'GoudyHeavyface',
                    fontSize: showBack ? 17 : 20,
                    fontWeight: FontWeight.w400,
                    color: _cream,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _teal,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${type.toUpperCase()} · ${name.toUpperCase()}',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _teal.withValues(alpha: 0.45),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Ki section ───────────────────────────────────────────────────────

class _KaiSection extends ConsumerWidget {
  const _KaiSection({
    required this.chatState,
    required this.allyState,
    required this.composer,
    required this.onSend,
    required this.realmName,
    required this.onPlus,
  });
  final dynamic chatState, allyState;
  final TextEditingController composer;
  final VoidCallback onSend, onPlus;
  final String realmName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streaming = chatState.isStreaming as bool;
    final ooB = chatState.outOfBalance as bool;
    final blocked = ref.watch(chatBlockedProvider);
    final kc = ref.read(kiChatControllerProvider.notifier);
    final msgs = chatState.messages as List<ChatMessageModel>;

    String preview;
    if (streaming && (chatState.streamingBuffer as String).isNotEmpty) {
      preview = chatState.streamingBuffer as String;
    } else if (msgs.isNotEmpty) {
      preview = msgs.last.content;
    } else {
      preview = 'Welcome to $realmName. What would you like to change today?';
    }
    if (preview.length > 150) {
      preview = '${preview.substring(0, 147)}…';
    }

    return Container(
      decoration: BoxDecoration(
        color: _bg,
        border: Border(
          top: BorderSide(color: _teal.withValues(alpha: 0.1)),
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -8),
            blurRadius: 24,
            color: Colors.black.withValues(alpha: 0.4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ki message.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _teal.withValues(alpha: 0.15)),
                        boxShadow: [
                          BoxShadow(
                            color: _teal.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: ColoredBox(
                          color: const Color(0xFF13101B),
                          child: Center(
                            child: SvgPicture.asset(
                              AppAssets.kidunaMark,
                              width: 18,
                              height: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Ki',
                                style: TextStyle(
                                  fontFamily: 'Avenir',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _cream,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (streaming)
                                Text(
                                  'typing…',
                                  style: TextStyle(
                                    fontFamily: 'Avenir',
                                    fontSize: 11,
                                    color: _teal.withValues(alpha: 0.5),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Avenir',
                              fontSize: 14,
                              color: _muted.withValues(alpha: 0.85),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Chips.
              if (!ooB && !blocked)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final l in const [
                          "show me what's already moving",
                          'i want to help people find a place to contribute',
                          'create something new',
                        ]) ...[
                          _Chip(label: l, onTap: () => kc.sendMessage(l)),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ),

              // Badge.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: _greenDot,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: _greenDot, blurRadius: 5),
                        ],
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      'ENTERING ${realmName.toUpperCase()}',
                      style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _muted.withValues(alpha: 0.4),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),

              // Input.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ooB || blocked
                    ? _OutOfKiduna(ref: ref)
                    : KiComposer(
                        controller: composer,
                        onSend: onSend,
                        onPlus: onPlus,
                        enabled: !streaming &&
                            !(chatState.isLoading as bool) &&
                            allyState.ally != null,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small widgets ────────────────────────────────────────────────────

class _Chip extends StatefulWidget {
  const _Chip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _h ? _teal.withValues(alpha: 0.05) : Colors.transparent,
            border: Border.all(
                color: _h
                    ? _teal.withValues(alpha: 0.35)
                    : _chipBorder),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 12,
              color: _h ? _teal : _cream.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
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
        color: _goldWarn.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _goldWarn.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_outlined, size: 16, color: _goldWarn),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Out of KIDUNA. Top up to keep chatting.',
              style: TextStyle(
                  fontFamily: 'Avenir', fontSize: 11, color: _muted),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              await openBuyKidunaPage(context);
              if (!context.mounted) return;
              await ref
                  .read(computeControllerProvider.notifier)
                  .refresh();
              if (!context.mounted) return;
              if (ref.read(computeControllerProvider).balance > 0) {
                ref
                    .read(kiChatControllerProvider.notifier)
                    .clearOutOfBalance();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _goldWarn.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: _goldWarn.withValues(alpha: 0.4)),
              ),
              child: const Text(
                'Buy KIDUNA',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _goldWarn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
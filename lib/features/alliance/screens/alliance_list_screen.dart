import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/realm_model.dart';
import '../../../data/services/realm_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../field/controllers/field_controller.dart';
import '../../field/game/field_game.dart';
import '../../field/widgets/field_inputs.dart';
import '../../field/widgets/field_panel.dart';
import '../../field/widgets/invite_panel.dart';
import '../../field/widgets/realm_panel.dart';
import '../controllers/alliance_controller.dart';
import '../widgets/proposal_list.dart';
import '../widgets/proposal_panel.dart';

const _kAllRoles = <String>[
  'visitor', 'guest', 'member', 'mage',
  'catalyst', 'organizer', 'creator', 'builder', 'luminary',
];
const _kSignerRoles = <String>{
  'catalyst', 'organizer', 'creator', 'builder', 'luminary',
};
const _kPerPage = 5;

class AllianceListScreen extends ConsumerStatefulWidget {
  const AllianceListScreen({super.key});

  @override
  ConsumerState<AllianceListScreen> createState() => _AllianceListScreenState();
}

class _AllianceListScreenState extends ConsumerState<AllianceListScreen> {
  RealmModel? _selected;
  String? _editingWallet;
  String? _openPanel;
  FieldGame? _bgGame;

  // Pagination
  int _alliancePage = 0;
  int _memberPage = 0;
  int _proposalPage = 0;

  // Join
  final _joinCode = TextEditingController();
  bool _joining = false;
  String? _joinMsg;
  bool _joinIsError = false;

  @override
  void initState() {
    super.initState();
    // Refresh alliances every time this tab is shown.
    Future.microtask(() {
      if (mounted) ref.read(allianceControllerProvider.notifier).refresh();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bgGame ??= FieldGame(
      palette: context.kiduna,
      reduceMotion: MediaQuery.maybeOf(context)?.disableAnimations ?? false,
      source: null,
      hideStars: false,
    );
  }

  @override
  void dispose() {
    _joinCode.dispose();
    super.dispose();
  }

  // ── Actions ──

  Future<void> _openDetail(RealmModel a) async {
    setState(() {
      _selected = a;
      _editingWallet = null;
      _openPanel = null;
      _memberPage = 0;
      _proposalPage = 0;
    });
    try {
      final auth = ref.read(authControllerProvider);
      final fresh = await RealmService.instance.fetchRealmById(a.id, authToken: auth.token);
      if (!mounted) return;
      setState(() => _selected = fresh);
    } catch (e) {
      AppLogger.warning('Alliance refresh: $e', tag: 'Alliance');
    }

    if (a.walletEnabled) {
      ref.read(allianceControllerProvider.notifier).loadProposals(a.id);
      ref.read(allianceControllerProvider.notifier).loadWalletBalance(a.id);
      ref.read(allianceControllerProvider.notifier).loadWalletTransactions(a.id);
    }
  }

  Future<void> _changeRole(String wallet, String role) async {
    if (_selected == null) return;
    final ok = await ref.read(allianceControllerProvider.notifier)
        .updateMemberRole(_selected!.id, wallet, role);
    if (ok && mounted) _openDetail(_selected!);
  }

  Future<void> _handleJoin() async {
    final code = _joinCode.text.trim();
    if (code.isEmpty) {
      setState(() { _joinMsg = 'Please enter an invitation code.'; _joinIsError = true; });
      return;
    }
    setState(() { _joining = true; _joinMsg = null; });
    try {
      final auth = ref.read(authControllerProvider);
      await RealmService.instance.joinWithCode(code: code, authToken: auth.token);
      if (!mounted) return;
      ref.read(allianceControllerProvider.notifier).refresh();
      setState(() { _joining = false; _joinMsg = 'Successfully joined!'; _joinIsError = false; _joinCode.clear(); });
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _openPanel = null);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _joining = false; _joinMsg = '$e'; _joinIsError = true; });
    }
  }

  void _closePanel() => setState(() { _openPanel = null; _joinMsg = null; });

  @override
  Widget build(BuildContext context) {
    if (_selected != null) return _detailView(context);
    return _listView(context);
  }

  // ═══════════════════════════════════════════════════════════════
  // LIST VIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _listView(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final state = ref.watch(allianceControllerProvider);
    final ctrl = ref.read(allianceControllerProvider.notifier);

    return LayoutBuilder(builder: (context, constraints) {
      final bounds = Size(constraints.maxWidth, constraints.maxHeight);
      return Stack(
        children: [
          if (_bgGame != null) Positioned.fill(child: RepaintBoundary(child: GameWidget(game: _bgGame!))),
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: state.isLoading
                      ? Center(child: CircularProgressIndicator(strokeWidth: 2.0, color: colors.gold))
                      : state.error != null
                          ? _centerMsg(state.error!, colors, text, onRetry: ctrl.refresh)
                          : state.alliances.isEmpty
                              ? _emptyState(colors, text)
                              : _allianceListContent(state.alliances, colors, text),
                ),
                _bottomBar(colors, text, [
                  _barButton('Create Alliance', Icons.add, 'create', colors, text),
                  const SizedBox(width: 12),
                  _barButton('Join Alliance', Icons.vpn_key_outlined, 'join', colors, text),
                ]),
              ],
            ),
          ),
          if (_openPanel == 'create')
            FieldPanel(key: const ValueKey('create-alliance'), label: 'Create Alliance', bounds: bounds,
              width: 620, initialOffset: Offset((bounds.width * 0.5 - 310).clamp(8.0, double.infinity), bounds.height * 0.15),
              onClose: () {
                _closePanel();
                ref.read(allianceControllerProvider.notifier).refresh();
              }, child: RealmPanel(initialType: 'Alliance', onCreated: () {
                _closePanel();
                ref.read(allianceControllerProvider.notifier).refresh();
              })),
          if (_openPanel == 'join')
            FieldPanel(key: const ValueKey('join-alliance'), label: 'Join Alliance', bounds: bounds,
              width: 480, initialOffset: Offset((bounds.width * 0.5 - 240).clamp(8.0, double.infinity), bounds.height * 0.25),
              onClose: _closePanel, child: _joinForm(colors, text)),
        ],
      );
    });
  }

  Widget _allianceListContent(List<RealmModel> alliances, dynamic colors, dynamic text) {
    final totalPages = (alliances.length / _kPerPage).ceil();
    final page = _alliancePage.clamp(0, totalPages - 1);
    final start = page * _kPerPage;
    final end = (start + _kPerPage).clamp(0, alliances.length);
    final visible = alliances.sublist(start, end);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Text('Your Alliances', style: text.h4.copyWith(color: colors.cream)),
            const Spacer(),
            if (totalPages > 1) _paginator(page, totalPages, (p) => setState(() => _alliancePage = p), colors, text),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => ref.read(allianceControllerProvider.notifier).refresh(),
              child: Icon(Icons.refresh, size: 18.0, color: colors.sky),
            ),
          ]),
          const SizedBox(height: 16),
          ...visible.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _allianceCard(a, colors, text),
          )),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DETAIL VIEW — Full-width stacked cards
  // ═══════════════════════════════════════════════════════════════

  Widget _detailView(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final a = _selected!;
    final currentWallet = ref.read(authControllerProvider).user?.wallet ?? '';
    final isCreator = a.wallet == currentWallet;

    return LayoutBuilder(builder: (context, constraints) {
      final bounds = Size(constraints.maxWidth, constraints.maxHeight);
      return Stack(
        children: [
          if (_bgGame != null) Positioned.fill(child: RepaintBoundary(child: GameWidget(game: _bgGame!))),
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _backBar(a.name, colors, text),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Info pills
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          _pill('@${a.handle}', colors.gold),
                          _pill(a.status, a.status == 'active' ? colors.gold : (a.status == 'failed' ? const Color(0xFFE57373) : colors.quiet)),
                          _pill(a.visibility, colors.quiet),
                          if (a.walletEnabled) _pill('wallet', colors.sky),
                        ]),
                        if (a.description != null && a.description!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(a.description!, style: text.bodyBase.copyWith(color: colors.cream)),
                        ],
                        const SizedBox(height: 20),

                        // ── Members ──
                        _section(
                          icon: Icons.people,
                          title: 'Members',
                          count: a.members.length,
                          page: _memberPage,
                          totalItems: a.members.length,
                          onPageChange: (p) => setState(() => _memberPage = p),
                          action: _sectionBtn('Invite', Icons.person_add, 'invite'),
                          colors: colors, text: text,
                          emptyMsg: 'No members yet.',
                          emptyIcon: Icons.person_outline,
                          items: a.members,
                          itemBuilder: (m) => _memberRow(m as RealmMemberModel, isCreator, colors, text),
                        ),

                        // ── Cells ──
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: colors.surface.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors.camel.withValues(alpha: 0.12))),
                          child: Row(children: [
                            Icon(Icons.grid_view_rounded, size: 16, color: colors.gold),
                            const SizedBox(width: 8),
                            Text('Cells', style: text.h5.copyWith(color: colors.cream)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setState(() => _openPanel = 'newcell'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: colors.gold.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: colors.gold.withValues(alpha: 0.25))),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.add, size: 14, color: colors.gold),
                                  const SizedBox(width: 4),
                                  Text('New', style: text.caption.copyWith(
                                    color: colors.gold, fontWeight: FontWeight.w600, fontSize: 11.0)),
                                ]),
                              ),
                            ),
                          ]),
                        ),

                        // ── Wallet + Proposals (2-column grid) ──
                        if (a.walletEnabled) ...[
                          const SizedBox(height: 14),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _walletCard(a, colors, text)),
                                const SizedBox(width: 14),
                                Expanded(child: _section(
                                  icon: Icons.how_to_vote,
                                  title: 'Proposals',
                                  count: ref.watch(allianceControllerProvider).proposals.length,
                                  page: _proposalPage,
                                  totalItems: ref.watch(allianceControllerProvider).proposals.length,
                                  onPageChange: (p) => setState(() => _proposalPage = p),
                                  action: _sectionBtn('Create', Icons.add, 'proposal'),
                                  colors: colors, text: text,
                                  emptyMsg: 'No proposals yet.',
                                  emptyIcon: Icons.how_to_vote_outlined,
                                  items: ref.watch(allianceControllerProvider).proposals,
                                  itemBuilder: (p) => const SizedBox.shrink(),
                                  useCustomChild: true,
                                  customChild: ref.watch(allianceControllerProvider).proposals.isEmpty ? null : ProposalList(realmId: a.id),
                                )),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating panels
          if (_openPanel == 'invite')
            FieldPanel(key: const ValueKey('invite'), label: 'Invite Member', bounds: bounds,
              width: 620, initialOffset: Offset((bounds.width * 0.5 - 310).clamp(8.0, double.infinity), bounds.height * 0.2),
              onClose: () { _closePanel(); ref.read(fieldControllerProvider.notifier).exitEnteredRealm(); },
              child: const SingleChildScrollView(child: InvitePanel())),
          if (_openPanel == 'proposal')
            FieldPanel(key: const ValueKey('proposal'), label: 'Create Proposal', bounds: bounds,
              width: 620, initialOffset: Offset((bounds.width * 0.5 - 310).clamp(8.0, double.infinity), bounds.height * 0.2),
              onClose: _closePanel, child: ProposalForm(realmId: a.id)),
          if (_openPanel == 'newcell')
            FieldPanel(key: const ValueKey('newcell'), label: 'New Cell', bounds: bounds,
              width: 560, initialOffset: Offset((bounds.width * 0.5 - 280).clamp(8.0, double.infinity), bounds.height * 0.02),
              onClose: _closePanel, child: RealmPanel(
                initialType: 'Cell',
                initialParentId: a.id,
                lockType: true,
                onCreated: () => _closePanel(),
              )),
        ],
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // Section card with pagination
  // ═══════════════════════════════════════════════════════════════

  Widget _section({
    required IconData icon, required String title, required int count,
    required int page, required int totalItems,
    required ValueChanged<int> onPageChange,
    Widget? action, required dynamic colors, required dynamic text,
    String? emptyMsg, IconData? emptyIcon, bool isLoading = false,
    List<dynamic> items = const [], Widget Function(dynamic)? itemBuilder,
    bool useCustomChild = false, Widget? customChild,
  }) {
    final totalPages = totalItems == 0 ? 1 : (totalItems / _kPerPage).ceil();
    final p = page.clamp(0, totalPages - 1);
    final start = p * _kPerPage;
    final end = (start + _kPerPage).clamp(0, totalItems);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: colors.camel.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(children: [
            Container(width: 30.0, height: 30.0, alignment: Alignment.center,
              decoration: BoxDecoration(color: colors.gold.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8.0)),
              child: Icon(icon, size: 16.0, color: colors.gold)),
            const SizedBox(width: 10),
            Text(title, style: text.h5.copyWith(color: colors.cream)),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: colors.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10.0)),
              child: Text('$count', style: text.body.copyWith(color: colors.gold))),
            const Spacer(),
            if (totalPages > 1) _paginator(p, totalPages, onPageChange, colors, text),
            if (action != null) ...[const SizedBox(width: 8), action],
          ]),
          const SizedBox(height: 14),

          // Content
          if (isLoading)
            Padding(padding: const EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(strokeWidth: 2.0, color: colors.gold)))
          else if (items.isEmpty)
            _sectionEmpty(emptyMsg ?? '', emptyIcon ?? Icons.info_outline, colors, text)
          else if (useCustomChild && customChild != null)
            customChild
          else
            ...items.sublist(start, end).map((item) => itemBuilder!(item)),
        ],
      ),
    );
  }

  Widget _sectionEmpty(String msg, IconData icon, dynamic colors, dynamic text) {
    return Expanded(
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 32.0, color: colors.gold.withValues(alpha: 0.15)),
          const SizedBox(height: 10),
          Text(msg, style: text.bodySm.copyWith(color: colors.quiet), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Wallet card (read-only with transaction history)
  // ═══════════════════════════════════════════════════════════════

  Widget _walletCard(RealmModel a, dynamic colors, dynamic text) {
    final signers = a.members.where((m) => m.isSigner).length;
    final allianceState = ref.watch(allianceControllerProvider);
    final balance = allianceState.walletBalance;
    final txns = allianceState.walletTransactions;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: colors.camel.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Container(width: 30.0, height: 30.0, alignment: Alignment.center,
              decoration: BoxDecoration(color: colors.gold.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8.0)),
              child: Icon(Icons.account_balance_wallet, size: 16.0, color: colors.gold)),
            const SizedBox(width: 10),
            Text('Shared Wallet', style: text.h5.copyWith(color: colors.cream)),
          ]),
          const SizedBox(height: 14),

          // Balance
          if (balance != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.gold.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: colors.gold.withValues(alpha: 0.15)),
              ),
              child: Row(children: [
                Icon(Icons.monetization_on, size: 18.0, color: colors.gold),
                const SizedBox(width: 8),
                Text(
                  _balText(balance, 'usdc', 2, 'USDC'),
                  style: text.h5.copyWith(color: colors.gold),
                ),
                const SizedBox(width: 12),
                Text(
                  _balText(balance, 'sol', 4, 'SOL'),
                  style: text.bodySm.copyWith(color: colors.quiet),
                ),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // Wallet info
          _copyableRow('Multisig', a.multisigPda ?? '', colors, text),
          _copyableRow('Vault', a.vaultPda ?? '', colors, text),
          if (a.multisigPda == null) Text('Wallet pending setup\u2026', style: text.bodySm.copyWith(color: colors.quiet)),
          const SizedBox(height: 10),
          _pill('${a.threshold}-of-$signers signers required', colors.gold),

          // Transaction history
          const SizedBox(height: 18),
          Text('Recent Activity', style: text.bodyBase.copyWith(color: colors.cream, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (txns.isEmpty)
            _sectionEmpty('No transactions yet.', Icons.receipt_long_outlined, colors, text)
          else
            ...txns.take(5).map((tx) => _txRow(tx, colors, text)),
        ],
      ),
    );
  }

  Widget _txRow(Map<String, dynamic> tx, dynamic colors, dynamic text) {
    final date = tx['date'] as String?;
    final type = tx['type'] as String? ?? 'transfer';
    final err = tx['err'] as bool? ?? false;
    final sig = tx['signature'] as String? ?? '';
    final shortSig = sig.length > 12 ? '${sig.substring(0, 8)}...' : sig;
    final dateStr = date != null ? date.substring(0, 10) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.deep.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(children: [
        Icon(
          err ? Icons.error_outline : Icons.check_circle_outline,
          size: 14.0,
          color: err ? const Color(0xFFE57373) : colors.gold,
        ),
        const SizedBox(width: 8),
        Text(dateStr, style: text.body.copyWith(color: colors.quiet)),
        const SizedBox(width: 8),
        _pill(type, colors.sky),
        const Spacer(),
        Text(shortSig, style: text.body.copyWith(color: colors.quiet)),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Join form
  // ═══════════════════════════════════════════════════════════════

  Widget _joinForm(dynamic colors, dynamic text) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Icon(Icons.vpn_key, size: 40.0, color: colors.gold.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Enter the invitation code shared\nby the alliance organizer.',
            style: text.bodyBase.copyWith(color: colors.cream), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FieldTextInput(label: 'Invitation Code', controller: _joinCode, hint: 'RLM-XXXXXX'),
          const SizedBox(height: 20),
          if (_joinMsg != null) ...[
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: (_joinIsError ? const Color(0xFFE57373) : colors.gold).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8.0)),
              child: Text(_joinMsg!, style: text.bodyBase.copyWith(color: _joinIsError ? const Color(0xFFE57373) : colors.gold))),
            const SizedBox(height: 16),
          ],
          FieldPrimaryButton(label: _joining ? 'Joining...' : 'Join Alliance', onPressed: _joining ? null : _handleJoin),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Shared widgets
  // ═══════════════════════════════════════════════════════════════

  Widget _backBar(String title, dynamic colors, dynamic text) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      decoration: BoxDecoration(color: colors.deep.withValues(alpha: 0.95),
        border: Border(bottom: BorderSide(color: colors.camel.withValues(alpha: 0.12)))),
      child: Row(children: [
        GestureDetector(
          onTap: () => setState(() { _selected = null; _editingWallet = null; _openPanel = null; }),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.arrow_back, size: 18.0, color: colors.sky),
            const SizedBox(width: 6),
            Text('Back', style: text.bodySm.copyWith(color: colors.sky)),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(title, style: text.h4.copyWith(color: colors.cream), overflow: TextOverflow.ellipsis)),
        GestureDetector(onTap: () { if (_selected != null) _openDetail(_selected!); },
          child: Icon(Icons.refresh, size: 18.0, color: colors.sky)),
      ]),
    );
  }

  Widget _bottomBar(dynamic colors, dynamic text, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(color: colors.deep.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: colors.camel.withValues(alpha: 0.12)))),
      child: Row(children: children),
    );
  }

  Widget _barButton(String label, IconData icon, String panelId, dynamic colors, dynamic text) {
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _openPanel = _openPanel == panelId ? null : panelId),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: colors.sky, borderRadius: BorderRadius.circular(10.0)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18.0, color: colors.skyButtonInk),
          const SizedBox(width: 8),
          Text(label, style: text.bodySm.copyWith(color: colors.skyButtonInk, fontWeight: FontWeight.w700)),
        ]),
      ),
    ));
  }

  Widget _sectionBtn(String label, IconData icon, String panelId) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return GestureDetector(
      onTap: () {
        if (panelId == 'invite' && _selected != null) {
          ref.read(fieldControllerProvider.notifier).enterRealm(_selected!.id, _selected!.name);
        }
        setState(() => _openPanel = _openPanel == panelId ? null : panelId);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: colors.sky, borderRadius: BorderRadius.circular(6.0)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14.0, color: colors.skyButtonInk),
          const SizedBox(width: 4),
          Text(label, style: text.body.copyWith(color: colors.skyButtonInk, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _paginator(int page, int totalPages, ValueChanged<int> onPage, dynamic colors, dynamic text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTap: page > 0 ? () => onPage(page - 1) : null,
        child: Icon(Icons.chevron_left, size: 18.0, color: page > 0 ? colors.sky : colors.quiet.withValues(alpha: 0.3)),
      ),
      const SizedBox(width: 4),
      Text('${page + 1}/$totalPages', style: text.body.copyWith(color: colors.quiet)),
      const SizedBox(width: 4),
      GestureDetector(
        onTap: page < totalPages - 1 ? () => onPage(page + 1) : null,
        child: Icon(Icons.chevron_right, size: 18.0, color: page < totalPages - 1 ? colors.sky : colors.quiet.withValues(alpha: 0.3)),
      ),
    ]);
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Text(label, style: context.kidunaText.body.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _emptyState(dynamic colors, dynamic text) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.shield_outlined, size: 56.0, color: colors.gold.withValues(alpha: 0.2)),
      const SizedBox(height: 16),
      Text('No Alliances Yet', style: text.h5.copyWith(color: colors.cream.withValues(alpha: 0.5))),
      const SizedBox(height: 8),
      Text('Create a new alliance or join one\nusing the buttons below.', textAlign: TextAlign.center, style: text.bodySm.copyWith(color: colors.quiet)),
    ]));
  }

  Widget _centerMsg(String msg, dynamic colors, dynamic text, {VoidCallback? onRetry}) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(msg, style: text.bodySm.copyWith(color: colors.quiet)),
      if (onRetry != null) ...[const SizedBox(height: 12), GestureDetector(onTap: onRetry, child: Text('Retry', style: text.bodySm.copyWith(color: colors.sky)))],
    ]));
  }

  Widget _allianceCard(RealmModel a, dynamic colors, dynamic text) {
    final sc = a.status == 'active' ? colors.gold : (a.status == 'failed' ? const Color(0xFFE57373) : colors.quiet);
    return GestureDetector(
      onTap: () => _openDetail(a),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.surface.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: colors.camel.withValues(alpha: 0.12))),
        child: Row(children: [
          Container(width: 44.0, height: 44.0, alignment: Alignment.center,
            decoration: BoxDecoration(color: colors.gold.withValues(alpha: 0.06), border: Border.all(color: colors.gold.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(10.0)),
            child: Icon(Icons.shield, size: 22.0, color: colors.gold)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.name, style: text.bodyBase.copyWith(color: colors.cream, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('@${a.handle}  ·  ${a.members.length} members', style: text.bodySm.copyWith(color: colors.quiet)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6.0),
              border: Border.all(color: sc.withValues(alpha: 0.25))),
            child: Text(a.status, style: text.body.copyWith(color: sc, fontWeight: FontWeight.w600))),
          const SizedBox(width: 10),
          Icon(Icons.chevron_right, size: 20.0, color: colors.sky),
        ]),
      ),
    );
  }

  Widget _memberRow(RealmMemberModel m, bool isCreator, dynamic colors, dynamic text) {
    final w = m.wallet;
    final short = w.length > 12 ? '${w.substring(0, 6)}...${w.substring(w.length - 4)}' : w;
    final signer = _kSignerRoles.contains(m.role);
    final editing = _editingWallet == w;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.deep.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: editing ? colors.gold.withValues(alpha: 0.3) : colors.camel.withValues(alpha: 0.08))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 32.0, height: 32.0, alignment: Alignment.center,
            decoration: BoxDecoration(color: (signer ? colors.gold : colors.quiet).withValues(alpha: 0.06),
              border: Border.all(color: (signer ? colors.gold : colors.quiet).withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(8.0)),
            child: Icon(Icons.person, size: 16.0, color: signer ? colors.gold : colors.quiet)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(short, style: text.bodyBase.copyWith(color: colors.cream)),
            Text('${m.role[0].toUpperCase()}${m.role.substring(1)}${signer ? '  ·  Signer' : ''}',
              style: text.bodySm.copyWith(color: signer ? colors.gold : colors.quiet, fontWeight: FontWeight.w600)),
          ])),
          if (signer) Text('👑', style: TextStyle(fontSize: 16.0)),
          if (isCreator) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _editingWallet = editing ? null : w),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: editing ? colors.gold.withValues(alpha: 0.1) : colors.sky.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6.0), border: Border.all(color: editing ? colors.gold.withValues(alpha: 0.3) : colors.sky.withValues(alpha: 0.2))),
                child: Text(editing ? 'Cancel' : 'Role', style: text.body.copyWith(color: editing ? colors.gold : colors.sky))),
            ),
          ],
        ]),
        if (editing) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: _kAllRoles.map((role) {
            final sel = role == m.role;
            final rs = _kSignerRoles.contains(role);
            return GestureDetector(
              onTap: sel ? null : () => _changeRole(w, role),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: sel ? colors.gold.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6.0), border: Border.all(color: sel ? colors.gold : colors.camel.withValues(alpha: 0.2))),
                child: Text('${role[0].toUpperCase()}${role.substring(1)}${rs ? ' 👑' : ''}',
                  style: text.body.copyWith(color: sel ? colors.gold : colors.cream, fontWeight: sel ? FontWeight.w700 : FontWeight.w400))),
            );
          }).toList()),
        ],
      ]),
    );
  }

  Widget _infoRow(String label, String value, dynamic colors, dynamic text) {
    return Padding(padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(width: 70.0, child: Text(label, style: text.bodySm.copyWith(color: colors.muted))),
        Expanded(child: Text(value, style: text.bodySm.copyWith(color: colors.quiet))),
      ]));
  }

  Widget _copyableRow(String label, String fullAddress, dynamic colors, dynamic text) {
    if (fullAddress.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(width: 70.0, child: Text(label, style: text.bodySm.copyWith(color: colors.muted))),
        Expanded(child: Text(_shortenAddr(fullAddress), style: text.bodySm.copyWith(color: colors.quiet))),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: fullAddress));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label address copied!'), duration: const Duration(seconds: 2)));
          },
          child: Icon(Icons.copy, size: 14, color: colors.quiet),
        ),
      ]));
  }

  String _balText(Map<String, dynamic> bal, String key, int decimals, String suffix) {
    final val = bal[key] as num?;
    return '${val?.toStringAsFixed(decimals) ?? "0"} $suffix';
  }

  String _shortenAddr(String addr) {
    return addr.length > 20 ? '${addr.substring(0, 10)}...${addr.substring(addr.length - 6)}' : addr;
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/realm_model.dart';
import '../../../data/services/realm_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/alliance_controller.dart';

const _allRoles = [
  'visitor', 'guest', 'member', 'mage',
  'catalyst', 'organizer', 'creator', 'builder', 'luminary',
];
const _signerRoles = {'catalyst', 'organizer', 'creator', 'builder', 'luminary'};

/// Alliance detail — members, cells, roles, wallet info.
/// Opens as a full page via Navigator.push (replaces left panel content).
class AllianceDetailScreen extends ConsumerStatefulWidget {
  const AllianceDetailScreen({super.key, required this.alliance});
  final RealmModel alliance;

  @override
  ConsumerState<AllianceDetailScreen> createState() => _AllianceDetailState();
}

class _AllianceDetailState extends ConsumerState<AllianceDetailScreen> {
  late RealmModel _alliance;
  List<RealmModel> _cells = [];
  bool _loadingCells = true;
  String? _editingMemberId;

  @override
  void initState() {
    super.initState();
    _alliance = widget.alliance;
    _loadCells();
    _refreshAlliance();
  }

  Future<void> _refreshAlliance() async {
    try {
      final auth = ref.read(authControllerProvider);
      final fresh = await RealmService.instance.fetchRealmById(
        _alliance.id, authToken: auth.token,
      );
      if (mounted) setState(() => _alliance = fresh);
    } catch (_) {}
  }

  Future<void> _loadCells() async {
    try {
      final cells = await ref.read(allianceControllerProvider.notifier).fetchCells(_alliance.id);
      if (mounted) setState(() { _cells = cells; _loadingCells = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingCells = false);
    }
  }

  Future<void> _changeRole(String memberId, String newRole) async {
    final ok = await ref.read(allianceControllerProvider.notifier)
        .updateMemberRole(_alliance.id, memberId, newRole);
    if (ok) {
      await _refreshAlliance();
      setState(() => _editingMemberId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final currentWallet = ref.read(authControllerProvider).user?.wallet ?? '';
    final isCreator = _alliance.wallet == currentWallet;

    return Scaffold(
      backgroundColor: colors.field,
      appBar: AppBar(
        backgroundColor: colors.deep,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.cream, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Icon(Icons.shield, color: colors.gold, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_alliance.name,
                style: text.h4.copyWith(color: colors.cream),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colors.quiet, size: 20),
            onPressed: () { _refreshAlliance(); _loadCells(); },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Info ──
          _buildInfo(colors, text),
          const SizedBox(height: 16),

          // ── Members ──
          _buildSection(colors, text, 'Members', _alliance.members.length),
          const SizedBox(height: 6),
          ..._alliance.members.map((m) => _buildMemberTile(m, isCreator, colors, text)),

          const SizedBox(height: 16),

          // ── Cells ──
          _buildSection(colors, text, 'Cells', _cells.length),
          const SizedBox(height: 6),
          if (_loadingCells)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: colors.gold)),
            )
          else if (_cells.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No cells yet.', style: text.caption.copyWith(color: colors.quiet), textAlign: TextAlign.center),
            )
          else
            ..._cells.map((c) => _buildCellTile(c, colors, text)),

          // ── Wallet ──
          if (_alliance.walletEnabled) ...[
            const SizedBox(height: 16),
            _buildSection(colors, text, 'Shared Wallet', null),
            const SizedBox(height: 6),
            _buildWallet(colors, text),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfo(dynamic colors, dynamic text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.deep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.camel.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('@${_alliance.handle}', style: text.caption.copyWith(color: colors.gold)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(_alliance.status, style: text.caption.copyWith(color: colors.gold, fontSize: 11.0)),
              ),
              const SizedBox(width: 10),
              Text('${_alliance.visibility}', style: text.caption.copyWith(color: colors.quiet)),
            ],
          ),
          if (_alliance.description != null && _alliance.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_alliance.description!, style: text.body.copyWith(color: colors.cream)),
          ],
          if (_alliance.purpose != null && _alliance.purpose!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_alliance.purpose!, style: text.caption.copyWith(color: colors.quiet)),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(dynamic colors, dynamic text, String title, int? count) {
    return Row(
      children: [
        Text(title, style: text.h5.copyWith(color: colors.cream)),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(color: colors.gold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Text('$count', style: text.caption.copyWith(color: colors.gold, fontSize: 11.0)),
          ),
        ],
      ],
    );
  }

  Widget _buildMemberTile(RealmMemberModel m, bool isCreator, dynamic colors, dynamic text) {
    final short = m.wallet.length > 12 ? '${m.wallet.substring(0, 6)}...${m.wallet.substring(m.wallet.length - 4)}' : m.wallet;
    final isEditing = _editingMemberId == m.wallet;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.deep,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.camel.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, size: 18, color: colors.quiet),
              const SizedBox(width: 8),
              Expanded(child: Text(short, style: text.body.copyWith(color: colors.cream, fontSize: 13.0))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _signerRoles.contains(m.role) ? colors.gold.withValues(alpha: 0.12) : colors.quiet.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '${m.role[0].toUpperCase()}${m.role.substring(1)}${m.isSigner ? ' 👑' : ''}',
                  style: text.caption.copyWith(
                    color: _signerRoles.contains(m.role) ? colors.gold : colors.quiet,
                    fontSize: 11.0,
                  ),
                ),
              ),
              if (isCreator) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _editingMemberId = isEditing ? null : m.wallet),
                  child: Icon(Icons.edit, size: 14, color: isEditing ? colors.gold : colors.quiet),
                ),
              ],
            ],
          ),
          // ── Inline role selector ──
          if (isEditing) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: _allRoles.map((role) {
                final selected = role == m.role;
                return GestureDetector(
                  onTap: selected ? null : () => _changeRole(m.wallet, role),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: selected ? colors.gold.withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: selected ? colors.gold : colors.camel.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${role[0].toUpperCase()}${role.substring(1)}${_signerRoles.contains(role) ? ' 👑' : ''}',
                      style: text.caption.copyWith(
                        color: selected ? colors.gold : colors.quiet,
                        fontSize: 11.0,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCellTile(RealmModel c, dynamic colors, dynamic text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.deep,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.camel.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.games_outlined, size: 18, color: colors.gold),
          const SizedBox(width: 8),
          Expanded(child: Text(c.name, style: text.body.copyWith(color: colors.cream, fontSize: 13.0))),
          Text('${c.members.length} members', style: text.caption.copyWith(color: colors.quiet, fontSize: 11.0)),
        ],
      ),
    );
  }

  Widget _buildWallet(dynamic colors, dynamic text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.deep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 18, color: colors.gold),
              const SizedBox(width: 8),
              Text('Squads Multisig', style: text.body.copyWith(color: colors.cream, fontSize: 13.0)),
            ],
          ),
          const SizedBox(height: 6),
          if (_alliance.multisigPda != null)
            Text('Multisig: ${_alliance.multisigPda}', style: text.caption.copyWith(color: colors.quiet, fontSize: 11.0)),
          if (_alliance.vaultPda != null)
            Text('Vault: ${_alliance.vaultPda}', style: text.caption.copyWith(color: colors.quiet, fontSize: 11.0)),
          if (_alliance.multisigPda == null)
            Text('Wallet pending setup...', style: text.caption.copyWith(color: colors.quiet)),
          const SizedBox(height: 6),
          Text('Threshold: ${_alliance.threshold}-of-${_alliance.members.where((m) => m.isSigner).length} signers',
            style: text.caption.copyWith(color: colors.gold, fontSize: 11.0)),
        ],
      ),
    );
  }
}

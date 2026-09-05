import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/realm_model.dart';
import '../../../data/services/realm_service.dart';
import '../../../games/medieval_poker/session/lobby_client.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../field/controllers/field_controller.dart';
import '../../field/widgets/field_panel.dart';
import '../../field/widgets/invite_panel.dart';

const _gold = Color(0xFFC8A24B);
const _darkBg = Color(0xFF1A1A16);
const _green = Color(0xFF22C55E);

class CellDetailScreen extends ConsumerStatefulWidget {
  const CellDetailScreen({super.key, required this.realmId, this.realmName});

  final String realmId;
  final String? realmName;

  @override
  ConsumerState<CellDetailScreen> createState() => _CellDetailScreenState();
}

class _CellDetailScreenState extends ConsumerState<CellDetailScreen> {
  bool _showInvitePanel = false;
  RealmModel? _realm;
  List<LobbyRoom> _games = const [];
  bool _gamesLoading = true;
  Timer? _refreshTimer;

  String get _displayName => _realm?.name ?? widget.realmName ?? '';

  @override
  void initState() {
    super.initState();
    _loadRealm();
    _loadGames();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _loadGames(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRealm() async {
    try {
      final realm = await RealmService.instance.fetchRealmById(widget.realmId);
      if (mounted) {
        setState(() => _realm = realm);
      }
    } catch (_) {}
  }

  Future<void> _loadGames() async {
    try {
      final lobby = LobbyClient();
      final games = await lobby.realmGames(widget.realmId);
      if (mounted) {
        setState(() {
          _games = games;
          _gamesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _gamesLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = context.l10n;
    final userId = ref.watch(
      authControllerProvider.select((s) => s.user?.id),
    );
    final currentWallet = ref.watch(
      authControllerProvider.select((s) => s.user?.wallet),
    );
    final isCreator = currentWallet != null &&
        _realm?.wallet == currentWallet;
    final currentMember = currentWallet == null
        ? null
        : _realm?.members.where((m) => m.wallet == currentWallet).firstOrNull;
    final isPlayer = currentMember != null &&
        currentMember.role != 'guest' &&
        currentMember.role != 'visitor';

    return LayoutBuilder(
      builder: (context, bounds) {
        return Container(
          color: colors.deep,
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: colors.camel.withValues(alpha: 0.16)),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: colors.cream, size: 20),
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const DashboardScreen()),
                              (route) => false,
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _displayName,
                          style: text.h5.copyWith(color: colors.cream, fontSize: 17),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeaderCard(
                            colors: colors,
                            text: text,
                            l10n: l10n,
                            cellName: _displayName,
                            isPermanent: _realm?.isPermanentCell ?? true,
                            members: _realm?.members ?? const [],
                            isPlayer: isPlayer,
                            onInvite: () {
                              ref.read(fieldControllerProvider.notifier).enterRealm(widget.realmId, _displayName);
                              setState(() => _showInvitePanel = true);
                            },
                          ),
                          const SizedBox(height: 20),
                          _MembersSection(
                            colors: colors,
                            l10n: l10n,
                            members: _realm?.members ?? const [],
                            isCreator: isCreator,
                            realmId: widget.realmId,
                            onMemberRemoved: _loadRealm,
                          ),
                          const SizedBox(height: 20),
                          _GamesSection(
                            colors: colors,
                            l10n: l10n,
                            games: _games,
                            loading: _gamesLoading,
                            currentUserId: userId,
                            realmId: widget.realmId,
                            isPlayer: isPlayer,
                            isMember: currentMember != null,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  if (isPlayer)
                    _BottomActionBar(colors: colors, l10n: l10n, realmId: widget.realmId),
                ],
              ),
              if (_showInvitePanel)
                FieldPanel(
                  key: const ValueKey('invite'),
                  label: 'Prepare a Kiduna Invitation',
                  bounds: Size(bounds.maxWidth, bounds.maxHeight),
                  width: 620,
                  initialOffset: Offset(
                    (bounds.maxWidth * 0.5 - 310).clamp(8.0, double.infinity),
                    bounds.maxHeight * 0.2,
                  ),
                  onClose: () {
                    ref.read(fieldControllerProvider.notifier).exitEnteredRealm();
                    setState(() => _showInvitePanel = false);
                  },
                  child: const SingleChildScrollView(child: InvitePanel()),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.colors,
    required this.text,
    required this.l10n,
    required this.cellName,
    required this.isPermanent,
    required this.members,
    required this.isPlayer,
    required this.onInvite,
  });
  final dynamic colors;
  final dynamic text;
  final dynamic l10n;
  final String cellName;
  final bool isPermanent;
  final List<RealmMemberModel> members;
  final bool isPlayer;
  final VoidCallback onInvite;

  String get _subtitleText {
    final playerCount = members.where((m) => m.role != 'guest' && m.role != 'visitor').length;
    final guestCount = members.where((m) => m.role == 'guest' || m.role == 'visitor').length;
    final playerLabel = '$playerCount ${playerCount == 1 ? 'Player' : 'Players'}';
    if (guestCount == 0) return playerLabel;
    final guestLabel = '$guestCount ${guestCount == 1 ? 'Guest' : 'Guests'}';
    return '$playerLabel · $guestLabel';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gold.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _darkBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.groups_rounded, color: _gold, size: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        cellName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.cream as Color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPermanent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l10n.permanentCell.toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _gold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitleText,
                  style: TextStyle(fontSize: 13, color: colors.muted as Color),
                ),
              ],
            ),
          ),
          if (isPlayer) ...[
          const SizedBox(width: 10),
          SizedBox(
            height: 34,
            child: OutlinedButton.icon(
              onPressed: onInvite,
              icon: Icon(Icons.person_add_outlined, size: 15, color: colors.sky as Color),
              label: Text(
                l10n.inviteMembers.toString(),
                style: TextStyle(fontSize: 11, color: colors.sky as Color),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: (colors.sky as Color).withValues(alpha: 0.50)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MembersSection extends StatefulWidget {
  const _MembersSection({
    required this.colors,
    required this.l10n,
    required this.members,
    required this.isCreator,
    required this.realmId,
    required this.onMemberRemoved,
  });
  final dynamic colors;
  final dynamic l10n;
  final List<RealmMemberModel> members;
  final bool isCreator;
  final String realmId;
  final VoidCallback onMemberRemoved;

  @override
  State<_MembersSection> createState() => _MembersSectionState();
}

class _MembersSectionState extends State<_MembersSection> {
  int _selectedTab = 0;

  List<RealmMemberModel> get _players =>
      widget.members.where((m) => m.role != 'guest' && m.role != 'visitor').toList();

  List<RealmMemberModel> get _guests =>
      widget.members.where((m) => m.role == 'guest' || m.role == 'visitor').toList();

  Future<void> _confirmRemove(RealmMemberModel member) async {
    final colors = widget.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface as Color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Remove Member',
          style: TextStyle(color: colors.cream as Color, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Remove ${member.label} from this cell?',
          style: TextStyle(color: colors.muted as Color, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: colors.quiet as Color)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFC8A24B)),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await RealmService.instance.removeMember(
        realmId: widget.realmId,
        memberId: member.id!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.label} removed')),
      );
      widget.onMemberRemoved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is AppException ? (e.message ?? 'Failed to remove member') : 'Failed to remove member')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final players = _players;
    final guests = _guests;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: widget.l10n.cellMembers.toString(), color: colors.quiet as Color),
        Row(
          children: [
            _TabButton(
              label: 'Players (${players.length})',
              isActive: _selectedTab == 0,
              colors: colors,
              onTap: () => setState(() => _selectedTab = 0),
            ),
            const SizedBox(width: 16),
            _TabButton(
              label: 'Guests (${guests.length})',
              isActive: _selectedTab == 1,
              colors: colors,
              onTap: () => setState(() => _selectedTab = 1),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedTab == 0)
          _PlayersGrid(
            colors: colors,
            players: players,
            isCreator: widget.isCreator,
            onRemove: _confirmRemove,
          )
        else
          _GuestsList(
            colors: colors,
            guests: guests,
            isCreator: widget.isCreator,
            onRemove: _confirmRemove,
          ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isActive,
    required this.colors,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final dynamic colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? _gold : colors.muted as Color,
              ),
            ),
          ),
          Container(
            height: 2,
            width: label.length * 7.5,
            color: isActive ? _gold : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _PlayersGrid extends StatelessWidget {
  const _PlayersGrid({
    required this.colors,
    required this.players,
    required this.isCreator,
    required this.onRemove,
  });
  final dynamic colors;
  final List<RealmMemberModel> players;
  final bool isCreator;
  final Future<void> Function(RealmMemberModel) onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final member in players)
              SizedBox(
                width: cardWidth,
                child: _PlayerCard(
                  colors: colors,
                  member: member,
                  showRemove: isCreator && member.role != 'catalyst',
                  onRemove: (isCreator && member.role != 'catalyst' && member.id != null)
                      ? () => onRemove(member)
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.colors,
    required this.member,
    this.showRemove = false,
    this.onRemove,
  });
  final dynamic colors;
  final RealmMemberModel member;
  final bool showRemove;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isCatalyst = member.role == 'catalyst';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface as Color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (colors.camel as Color).withValues(alpha: 0.18),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gold.withValues(alpha: 0.20),
            ),
            child: Center(
              child: Text(
                member.label[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _gold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.cream as Color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  member.role,
                  style: TextStyle(
                    fontSize: 11,
                    color: isCatalyst ? _gold : colors.muted as Color,
                  ),
                ),
              ],
            ),
          ),
          if (showRemove)
            GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.redAccent),
              ),
            ),
        ],
      ),
    );
  }
}

class _GuestsList extends StatelessWidget {
  const _GuestsList({
    required this.colors,
    required this.guests,
    required this.isCreator,
    required this.onRemove,
  });
  final dynamic colors;
  final List<RealmMemberModel> guests;
  final bool isCreator;
  final Future<void> Function(RealmMemberModel) onRemove;

  @override
  Widget build(BuildContext context) {
    if (guests.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface as Color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: (colors.camel as Color).withValues(alpha: 0.16)),
        ),
        child: Center(
          child: Text(
            'No guests yet',
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: colors.muted as Color,
            ),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final member in guests)
              SizedBox(
                width: cardWidth,
                child: _PlayerCard(
                  colors: colors,
                  member: member,
                  showRemove: isCreator,
                  onRemove: (isCreator && member.id != null)
                      ? () => onRemove(member)
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GamesSection extends StatelessWidget {
  const _GamesSection({
    required this.colors,
    required this.l10n,
    required this.games,
    required this.loading,
    required this.currentUserId,
    required this.realmId,
    required this.isPlayer,
    required this.isMember,
  });
  final dynamic colors;
  final dynamic l10n;
  final List<LobbyRoom> games;
  final bool loading;
  final String? currentUserId;
  final String realmId;
  final bool isPlayer;
  final bool isMember;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: l10n.cellGames.toString(), color: colors.quiet as Color),
        if (loading)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surface as Color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: (colors.camel as Color).withValues(alpha: 0.16)),
            ),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.muted as Color,
                ),
              ),
            ),
          )
        else if (games.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surface as Color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: (colors.camel as Color).withValues(alpha: 0.16)),
            ),
            child: Center(
              child: Text(
                l10n.noGamesYet.toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: colors.muted as Color,
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              for (final room in games) ...[
                if (room.isFinished)
                  _FinishedGameCard(colors: colors, l10n: l10n, room: room)
                else
                  _ActiveGameCard(
                    colors: colors,
                    l10n: l10n,
                    room: room,
                    currentUserId: currentUserId,
                    realmId: realmId,
                    isPlayer: isPlayer,
                    isMember: isMember,
                  ),
                const SizedBox(height: 8),
              ],
            ],
          ),
      ],
    );
  }
}

class _ActiveGameCard extends StatefulWidget {
  const _ActiveGameCard({
    required this.colors,
    required this.l10n,
    required this.room,
    required this.currentUserId,
    required this.realmId,
    required this.isPlayer,
    required this.isMember,
  });
  final dynamic colors;
  final dynamic l10n;
  final LobbyRoom room;
  final String? currentUserId;
  final String realmId;
  final bool isPlayer;
  final bool isMember;

  @override
  State<_ActiveGameCard> createState() => _ActiveGameCardState();
}

class _ActiveGameCardState extends State<_ActiveGameCard> {
  bool _busy = false;

  bool get _userInRoom =>
      widget.currentUserId != null &&
      widget.room.seats.any((s) => s.userId == widget.currentUserId);

  String get _hostLabel {
    final hostSeat = widget.room.seats.where((s) => s.seat == 0).firstOrNull;
    return hostSeat?.label ?? 'Host';
  }

  Future<void> _watch() async {
    setState(() => _busy = true);
    try {
      final lobby = LobbyClient();
      final ticket = await lobby.watchRoom(widget.room.code);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            initialTab: 1,
            startGameInLobby: true,
            cellRealmId: widget.realmId,
            joinTicket: ticket,
          ),
        ),
      );
      if (mounted) setState(() => _busy = false);
    } on LobbyException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot watch: $e')),
      );
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinOrRejoin() async {
    setState(() => _busy = true);
    try {
      final lobby = LobbyClient();
      final ticket = await lobby.joinRoom(widget.room.code);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            initialTab: 1,
            startGameInLobby: true,
            cellRealmId: widget.realmId,
            joinTicket: ticket,
          ),
        ),
      );
      if (mounted) setState(() => _busy = false);
    } on LobbyException {
      if (mounted) setState(() => _busy = false);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final l10n = widget.l10n;
    final room = widget.room;
    final occupied = room.seats.where((s) => s.userId != null || s.isAi).length;
    final statusLabel = room.isLobby ? 'LOBBY' : 'ACTIVE';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface as Color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _gold.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _green,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      room.code,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.cream as Color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: room.isLobby
                            ? const Color(0xFF2A6B4F)
                            : const Color(0xFF6B4F2A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: colors.cream as Color,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$occupied/${room.seatCount} players · Started by $_hostLabel',
                  style: TextStyle(fontSize: 11, color: colors.muted as Color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (widget.isPlayer && widget.room.isLobby)
            SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: _busy ? null : _joinOrRejoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.sky as Color,
                  foregroundColor: colors.skyButtonInk as Color,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: _busy
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.skyButtonInk as Color,
                        ),
                      )
                    : Text(
                        _userInRoom
                            ? l10n.rejoinGame.toString()
                            : l10n.joinGame.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
              ),
            )
          else if (widget.isMember && widget.room.isActive)
            SizedBox(
              height: 32,
              child: OutlinedButton(
                onPressed: _busy ? null : _watch,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: (colors.muted as Color).withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: _busy
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.muted as Color,
                        ),
                      )
                    : Text(
                        'Watch',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: colors.muted as Color,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FinishedGameCard extends StatelessWidget {
  const _FinishedGameCard({
    required this.colors,
    required this.l10n,
    required this.room,
  });
  final dynamic colors;
  final dynamic l10n;
  final LobbyRoom room;

  @override
  Widget build(BuildContext context) {
    final result = room.result;
    final hasWinner = result?.winnerName != null;
    final winnerLabel = result?.winnerName ?? '';
    final endedAt = result?.endedAt;
    final dateStr = endedAt != null ? DateFormat.yMMMd().format(endedAt) : '';
    final playerCount = room.seats.where((s) => s.userId != null || s.isAi).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface as Color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (colors.camel as Color).withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: _gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasWinner ? '$winnerLabel ${l10n.won}' : 'Game ended',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.cream as Color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateStr · $playerCount players',
                  style: TextStyle(fontSize: 11, color: colors.muted as Color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatefulWidget {
  const _BottomActionBar({required this.colors, required this.l10n, required this.realmId});
  final dynamic colors;
  final dynamic l10n;
  final String realmId;

  @override
  State<_BottomActionBar> createState() => _BottomActionBarState();
}

class _BottomActionBarState extends State<_BottomActionBar> {
  bool _busy = false;

  Future<void> _startGame() async {
    setState(() => _busy = true);
    try {
      final lobby = LobbyClient();
      final ticket = await lobby.createRoom(realmId: widget.realmId);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            initialTab: 1,
            startGameInLobby: true,
            cellRealmId: widget.realmId,
            joinTicket: ticket,
          ),
        ),
      );
      if (mounted) setState(() => _busy = false);
    } on LobbyException {
      if (mounted) setState(() => _busy = false);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: widget.colors.deep as Color,
        border: Border(
          top: BorderSide(color: (widget.colors.camel as Color).withValues(alpha: 0.16)),
        ),
      ),
      child: SizedBox(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: _busy ? null : _startGame,
          icon: _busy
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.colors.skyButtonInk as Color,
                  ),
                )
              : const Icon(Icons.play_arrow, size: 20),
          label: Text(
            widget.l10n.startNewGame.toString(),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.colors.sky as Color,
            foregroundColor: widget.colors.skyButtonInk as Color,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }
}

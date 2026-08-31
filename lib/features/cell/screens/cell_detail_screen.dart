import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../field/controllers/field_controller.dart';
import '../../field/widgets/field_panel.dart';
import '../../field/widgets/invite_panel.dart';
import '../data/cell_mock_data.dart';

const _gold = Color(0xFFC8A24B);
const _darkBg = Color(0xFF1A1A16);
const _greenLive = Color(0xFF22C55E);

class CellDetailScreen extends ConsumerStatefulWidget {
  const CellDetailScreen({super.key, required this.realmId, this.realmName});

  final String realmId;
  final String? realmName;

  @override
  ConsumerState<CellDetailScreen> createState() => _CellDetailScreenState();
}

class _CellDetailScreenState extends ConsumerState<CellDetailScreen> {
  bool _showInvitePanel = false;

  String get _displayName => widget.realmName ?? CellMockData.cellName;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = context.l10n;

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
                            onInvite: () {
                              ref.read(fieldControllerProvider.notifier).enterRealm(widget.realmId, _displayName);
                              setState(() => _showInvitePanel = true);
                            },
                          ),
                          const SizedBox(height: 20),
                          _MembersGrid(colors: colors, l10n: l10n),
                          const SizedBox(height: 20),
                          _ActiveGamesSection(colors: colors, l10n: l10n, realmId: widget.realmId),
                          const SizedBox(height: 20),
                          _GameHistorySection(colors: colors, l10n: l10n),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
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
    required this.onInvite,
  });
  final dynamic colors;
  final dynamic text;
  final dynamic l10n;
  final String cellName;
  final VoidCallback onInvite;

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
                ),
                const SizedBox(height: 4),
                Text(
                  '${CellMockData.members.length} of ${CellMockData.maxMembers} ${l10n.cellMembers.toString().toLowerCase()}',
                  style: TextStyle(fontSize: 13, color: colors.muted as Color),
                ),
              ],
            ),
          ),
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

class _MembersGrid extends StatelessWidget {
  const _MembersGrid({required this.colors, required this.l10n});
  final dynamic colors;
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: l10n.cellMembers.toString(), color: colors.quiet as Color),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(CellMockData.maxMembers, (i) {
                final hasMember = i < CellMockData.members.length;
                final member = hasMember ? CellMockData.members[i] : null;
                return SizedBox(
                  width: cardWidth,
                  child: _MemberCard(
                    name: member?['name'],
                    role: member?['role'],
                    isEmpty: !hasMember,
                    colors: colors,
                    l10n: l10n,
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    this.name,
    this.role,
    required this.isEmpty,
    required this.colors,
    required this.l10n,
  });
  final String? name;
  final String? role;
  final bool isEmpty;
  final dynamic colors;
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    final isCreator = role == 'creator';
    return Opacity(
      opacity: isEmpty ? 0.5 : 1.0,
      child: Container(
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
            if (isEmpty)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (colors.quiet as Color).withValues(alpha: 0.3),
                    width: 1,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: Center(
                  child: Icon(Icons.add, size: 14, color: colors.quiet as Color),
                ),
              )
            else
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _gold.withValues(alpha: 0.20),
                ),
                child: Center(
                  child: Text(
                    name![0].toUpperCase(),
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
              child: isEmpty
                  ? Text(
                      l10n.cellOpenSlot.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.quiet as Color,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.cream as Color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (role != null)
                          Text(
                            role!,
                            style: TextStyle(
                              fontSize: 11,
                              color: isCreator ? _gold : colors.muted as Color,
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveGamesSection extends StatelessWidget {
  const _ActiveGamesSection({required this.colors, required this.l10n, required this.realmId});
  final dynamic colors;
  final dynamic l10n;
  final String realmId;

  @override
  Widget build(BuildContext context) {
    final games = CellMockData.activeGames;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: l10n.cellActiveGames.toString(), color: colors.quiet as Color),
        if (games.isEmpty)
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
                l10n.noActiveGames.toString(),
                style: TextStyle(fontSize: 12, color: colors.quiet as Color),
              ),
            ),
          )
        else
          ...games.map((game) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _gold.withValues(alpha: 0.30)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: _greenLive,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Room ${game['code']}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.cream as Color,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          '${game['players']}/${game['maxPlayers']} players · ${game['host']}',
                          style: TextStyle(fontSize: 11, color: colors.muted as Color),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DashboardScreen(
                            initialTab: 1,
                            startGameInLobby: true,
                            cellRealmId: realmId,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.sky as Color,
                      foregroundColor: colors.skyButtonInk as Color,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(
                      l10n.joinGame.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          )),
      ],
    );
  }
}

class _GameHistorySection extends StatelessWidget {
  const _GameHistorySection({required this.colors, required this.l10n});
  final dynamic colors;
  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    final history = CellMockData.gameHistory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: l10n.cellGameHistory.toString(), color: colors.quiet as Color),
        if (history.isEmpty)
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
                l10n.noGamesPlayedYet.toString(),
                style: TextStyle(fontSize: 12, color: colors.quiet as Color),
              ),
            ),
          )
        else
          ...history.map((game) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface as Color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: (colors.camel as Color).withValues(alpha: 0.16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _gold.withValues(alpha: 0.1),
                  ),
                  child: const Center(
                    child: Icon(Icons.emoji_events_rounded, size: 18, color: _gold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${game['winner']} won',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.cream as Color,
                        ),
                      ),
                      Text(
                        '${game['date']} · ${game['players']} · ${game['duration']}',
                        style: TextStyle(fontSize: 10, color: colors.muted as Color),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: colors.quiet as Color),
              ],
            ),
          )),
      ],
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.colors, required this.l10n, required this.realmId});
  final dynamic colors;
  final dynamic l10n;
  final String realmId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: colors.deep as Color,
        border: Border(
          top: BorderSide(color: (colors.camel as Color).withValues(alpha: 0.16)),
        ),
      ),
      child: SizedBox(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DashboardScreen(
                  initialTab: 1,
                  startGameInLobby: true,
                  cellRealmId: realmId,
                ),
              ),
            );
          },
          icon: const Icon(Icons.play_arrow, size: 20),
          label: Text(
            l10n.startNewGame.toString(),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.sky as Color,
            foregroundColor: colors.skyButtonInk as Color,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }
}

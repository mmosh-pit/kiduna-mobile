import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../games/medieval_poker/session/lobby_client.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../controllers/field_controller.dart';
import '../data/field_composition.dart';
import '../data/realm_atlas.dart';

String _gravityLabel(BuildContext context, int level) {
  final l10n = context.l10n;
  return switch (level) {
    1 => l10n.gravityQuiet,
    2 => l10n.gravityAvailable,
    3 => l10n.gravityRelevant,
    4 => l10n.gravityCentral,
    5 => l10n.gravityVital,
    _ => l10n.gravityRelevant,
  };
}

class RealmDetailPopup extends ConsumerWidget {
  const RealmDetailPopup({
    super.key,
    required this.placement,
    required this.onClose,
    required this.onEnter,
    this.onGravityChanged,
  });

  final FieldPlacement placement;
  final VoidCallback onClose;
  final ValueChanged<AtlasRealm> onEnter;
  final ValueChanged<int>? onGravityChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.kiduna;
    final realm = placement.realm;
    final accent = colors.sky;
    final level = ref.watch(
      fieldControllerProvider.select(
        (s) => s.realmGravity[realm.id] ?? 3,
      ),
    );

    return Container(
      constraints: const BoxConstraints(maxWidth: 540),
      decoration: BoxDecoration(
        color: colors.deep.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.5),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            typeName: realm.type.label,
            levelLabel: _gravityLabel(context, level),
            name: realm.name,
            accent: accent,
            onClose: onClose,
          ),
          if (placement.reason.isNotEmpty)
            _WhySection(reason: placement.reason, accent: accent),
          if (realm.type == AtlasRealmType.cell)
            if (realm.isPermanentCell)
              _ActionRow(onEnter: () {
                onClose();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => DashboardScreen(permanentCellRealmId: realm.id),
                  ),
                  (route) => false,
                );
              })
            else ...[
              _CellGameSection(
                gameStatus: realm.gameStatus,
                gameRoomCode: realm.gameRoomCode,
                gamePlayerCount: realm.gamePlayerCount,
                gameSeatCount: realm.gameSeatCount,
                onClosePopup: onClose,
              ),
            ]
          else ...[
            _ActionRow(onEnter: () => onEnter(realm)),
          ],
          _LevelFooter(
            level: level,
            realmId: realm.id,
            realmName: realm.name,
            accent: accent,
            onGravityChanged: onGravityChanged,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.typeName,
    required this.levelLabel,
    required this.name,
    required this.accent,
    required this.onClose,
  });

  final String typeName;
  final String levelLabel;
  final String name;
  final Color accent;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$typeName · $levelLabel'.toUpperCase(),
                  style: text.eyebrowSmall.copyWith(
                    color: accent,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.close, size: 16, color: colors.quiet),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: text.display.copyWith(
              color: colors.cream,
              fontSize: 22,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhySection extends StatelessWidget {
  const _WhySection({required this.reason, required this.accent});

  final String reason;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.whyIsThisHere.toUpperCase(),
            style: text.eyebrowSmall.copyWith(
              color: accent,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            reason,
            style: text.bodySmall.copyWith(color: colors.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.onEnter});

  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: _ActionBtn(
        label: l10n.enterAction,
        color: colors.sky,
        textColor: colors.skyButtonInk,
        onTap: onEnter,
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelFooter extends ConsumerWidget {
  const _LevelFooter({
    required this.level,
    required this.realmId,
    required this.realmName,
    required this.accent,
    this.onGravityChanged,
  });

  final int level;
  final String realmId;
  final String realmName;
  final Color accent;
  final ValueChanged<int>? onGravityChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.kiduna;
    final l10n = context.l10n;
    final controller = ref.read(fieldControllerProvider.notifier);
    final currentLevel = ref.watch(
      fieldControllerProvider.select(
        (s) => s.realmGravity[realmId] ?? level,
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          Text(
            l10n.setLevel.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: colors.quiet,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              height: 30,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: colors.camel.withValues(alpha: 0.18),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: currentLevel,
                  isDense: true,
                  isExpanded: true,
                  dropdownColor: colors.raised,
                  style: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 10,
                    color: colors.cream,
                  ),
                  icon: Icon(
                    Icons.expand_more,
                    size: 14,
                    color: colors.quiet,
                  ),
                  items: List.generate(5, (i) {
                    final lv = i + 1;
                    return DropdownMenuItem(
                      value: lv,
                      child: Text(_gravityLabel(context, lv)),
                    );
                  }),
                  onChanged: (v) {
                    if (v == null || v == currentLevel) return;
                    controller.setGravity(realmId, v);
                    onGravityChanged?.call(v);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CellGameSection extends StatefulWidget {
  const _CellGameSection({
    this.gameStatus,
    this.gameRoomCode,
    this.gamePlayerCount,
    this.gameSeatCount,
    this.onClosePopup,
  });

  final String? gameStatus;
  final String? gameRoomCode;
  final int? gamePlayerCount;
  final int? gameSeatCount;
  final VoidCallback? onClosePopup;

  @override
  State<_CellGameSection> createState() => _CellGameSectionState();
}

class _CellGameSectionState extends State<_CellGameSection> {
  final TextEditingController _codeController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinGame(String code) async {
    if (code.isEmpty) {
      setState(() => _error = 'Enter a room code');
      return;
    }

    setState(() { _busy = true; _error = null; });

    try {
      final lobby = LobbyClient();
      final ticket = await lobby.joinRoom(code);

      if (!mounted) return;

      widget.onClosePopup?.call();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            initialTab: 1,
            startGameInLobby: true,
            joinTicket: ticket,
          ),
        ),
      );
    } on LobbyException catch (e) {
      if (mounted) setState(() { _error = e.message; _busy = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to join'; _busy = false; });
    }
  }

  Color _statusColor(String? status) {
    return switch (status) {
      'lobby' => const Color(0xFF2A6B4F),
      'active' => const Color(0xFF6B4F2A),
      'finished' || 'ended' => const Color(0xFF4A3A3A),
      _ => const Color(0xFF3A3A4A),
    };
  }

  String _statusLabel(String? status) {
    return switch (status) {
      'lobby' => 'LOBBY',
      'active' => 'ACTIVE',
      'finished' || 'ended' => 'FINISHED',
      _ => 'NO GAME',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final status = widget.gameStatus;
    final canJoin = status == 'lobby' || status == 'active';
    final hasGame = status != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.sky.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.sky.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'GAME',
                  style: text.eyebrowSmall.copyWith(
                    color: colors.sky,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor(status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: colors.cream,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                if (hasGame &&
                    widget.gamePlayerCount != null &&
                    widget.gameSeatCount != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '${widget.gamePlayerCount}/${widget.gameSeatCount}',
                    style: TextStyle(fontSize: 10, color: colors.muted),
                  ),
                ],
              ],
            ),
            if (canJoin) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(
                        color: colors.cream,
                        fontSize: 16,
                        letterSpacing: 3,
                      ),
                      decoration: InputDecoration(
                        hintText: 'ABC123',
                        hintStyle: TextStyle(
                          color: colors.muted.withValues(alpha: 0.4),
                          letterSpacing: 3,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: colors.camel.withValues(alpha: 0.24),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: colors.camel.withValues(alpha: 0.24),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: colors.sky),
                        ),
                        filled: true,
                        fillColor: const Color.fromRGBO(6, 3, 4, 0.66),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _busy
                          ? null
                          : () => _joinGame(
                              _codeController.text.trim().toUpperCase(),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.sky,
                        foregroundColor: colors.skyButtonInk,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _busy
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.skyButtonInk,
                              ),
                            )
                          : const Text('Join',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: colors.orange, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


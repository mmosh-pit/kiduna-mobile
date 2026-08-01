import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../config/assets.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/saved_tool_model.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../controllers/field_controller.dart';
import 'capacity_header.dart';

/// Connections capacity workspace — expand/collapse tool rows with
/// multi-account support. Auto-refreshes when the browser tab regains
/// focus (e.g. after completing Google OAuth in another tab).
class ConnectionsPanel extends ConsumerStatefulWidget {
  const ConnectionsPanel({super.key, required this.realmName});

  final String realmName;

  @override
  ConsumerState<ConnectionsPanel> createState() => _ConnectionsPanelState();
}

class _ConnectionsPanelState extends ConsumerState<ConnectionsPanel>
    with WidgetsBindingObserver {
  String? _expandedTool;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(
      ref.read(fieldControllerProvider.notifier).fetchSavedTools,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On web: fires when user switches back to this browser tab.
    // After Google OAuth completes in another tab, this refreshes
    // the tool list instantly.
    if (state == AppLifecycleState.resumed) {
      ref.read(fieldControllerProvider.notifier).fetchSavedTools();
    }
  }

  static const List<_ToolDef> _toolDefs = [
    _ToolDef(
      id: 'bluesky',
      name: 'Bluesky',
      detail: 'One verified social account',
      color: Color(0xFF38BDF8),
      singleAccount: false,
    ),
    _ToolDef(
      id: 'google',
      name: 'Google',
      detail: 'Docs, Drive, and selected account permissions',
      color: Color(0xFF34D399),
      singleAccount: false,
    ),
    _ToolDef(
      id: 'telegram',
      name: 'Telegram',
      detail: 'One verified messaging account',
      color: Color(0xFF60A5FA),
      singleAccount: false,
    ),
    _ToolDef(
      id: 'solana',
      name: 'Solana wallet',
      detail: 'One external wallet and explicit signing scope',
      color: Color(0xFFA78BFA),
      singleAccount: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(fieldControllerProvider);
    final controller = ref.read(fieldControllerProvider.notifier);
    final savedTools = state.savedTools;
    final totalConnected = savedTools.where((t) => t.isActive).length;

    return Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CapacityHeader(
            eyebrow: l10n.connections,
            heading: l10n.accountsRealmMayReach(widget.realmName),
            status: '$totalConnected connected',
          ),
          const SizedBox(height: 14),
          for (final def in _toolDefs) ...[
            _ToolRow(
              def: def,
              accounts: savedTools
                  .where((t) => t.toolName == def.id && t.isActive)
                  .toList(),
              expanded: _expandedTool == def.id,
              onToggleExpand: () => setState(() {
                _expandedTool =
                    _expandedTool == def.id ? null : def.id;
              }),
              onAdd: () {
                if (def.id == 'google') {
                  controller.connectGoogleOAuth();
                } else {
                  controller.startConnectingTool(def.id);
                }
              },
              onDisconnect: controller.disconnectTool,
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _ToolDef {
  const _ToolDef({
    required this.id,
    required this.name,
    required this.detail,
    required this.color,
    required this.singleAccount,
  });

  final String id;
  final String name;
  final String detail;
  final Color color;
  final bool singleAccount;
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.def,
    required this.accounts,
    required this.expanded,
    required this.onToggleExpand,
    required this.onAdd,
    required this.onDisconnect,
  });

  final _ToolDef def;
  final List<SavedToolModel> accounts;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onAdd;
  final ValueChanged<String> onDisconnect;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final connected = accounts.isNotEmpty;
    final borderColor = expanded
        ? def.color.withValues(alpha: 0.3)
        : connected
            ? def.color.withValues(alpha: 0.18)
            : colors.camel.withValues(alpha: 0.14);

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(6, 3, 4, 0.36),
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header row ──
          GestureDetector(
            onTap: connected ? onToggleExpand : null,
            child: MouseRegion(
              cursor: connected
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: def.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SvgPicture.asset(
                        AppAssets.toolIcon(def.id),
                        colorFilter: ColorFilter.mode(
                          def.color,
                          BlendMode.srcIn,
                        ),
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
                                def.name,
                                style: text.label.copyWith(
                                  color: colors.cream,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (connected) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '${accounts.length} connected',
                                  style: text.micro.copyWith(color: def.color),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            connected
                                ? accounts
                                    .map((a) => a.externalHandle ?? 'Connected')
                                    .join(' · ')
                                : def.detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.micro.copyWith(
                              color: connected ? colors.muted : colors.quiet,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!connected)
                      _ConnectButton(onTap: onAdd)
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!def.singleAccount)
                            _AddButton(onTap: onAdd, color: def.color),
                          const SizedBox(width: 6),
                          Icon(
                            expanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 18,
                            color: colors.muted,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          // ── Expanded: account sub-rows ──
          if (expanded && connected)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colors.camel.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final account in accounts)
                    _AccountSubRow(
                      account: account,
                      color: def.color,
                      onDisconnect: () => onDisconnect(account.id),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  const _ConnectButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.kiduna;
    final t = context.kidunaText;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 28),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        foregroundColor: c.skyButtonInk,
        backgroundColor: c.sky,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        textStyle: t.label.copyWith(fontWeight: FontWeight.w700),
      ),
      child: const Text('Connect'),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap, required this.color});

  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            border: Border.all(color: color.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            '+ Add',
            style: context.kidunaText.micro.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountSubRow extends StatefulWidget {
  const _AccountSubRow({
    required this.account,
    required this.color,
    required this.onDisconnect,
  });

  final SavedToolModel account;
  final Color color;
  final VoidCallback onDisconnect;

  @override
  State<_AccountSubRow> createState() => _AccountSubRowState();
}

class _AccountSubRowState extends State<_AccountSubRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final handle = widget.account.externalHandle ?? 'Connected';
    final chatInfo = widget.account.ownerChatId != null
        ? ' · Chat ${widget.account.ownerChatId}'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$handle$chatInfo',
              style: text.caption.copyWith(color: colors.cream),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final handle = widget.account.externalHandle ?? 'this account';
              final confirmed = await ConfirmDialog.show(
                context: context,
                title: 'Disconnect Account',
                message: 'Disconnect $handle? Skills using this '
                    'connection will stop working.',
                confirmLabel: 'Disconnect',
                isDestructive: true,
              );
              if (confirmed == true) {
                widget.onDisconnect();
              }
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: _hovered
                      ? const Color(0x33E25C5C)
                      : const Color(0x1AE25C5C),
                  border: Border.all(
                    color: _hovered
                        ? const Color(0x80E25C5C)
                        : const Color(0x40E25C5C),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Disconnect',
                  style: text.micro.copyWith(
                    color: _hovered
                        ? const Color(0xFFE25C5C)
                        : const Color(0xCCE25C5C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
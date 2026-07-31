import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import 'capacity_header.dart';

/// Connections capacity workspace — account list with connect/disconnect toggles.
class ConnectionsPanel extends StatefulWidget {
  const ConnectionsPanel({super.key, required this.realmName});

  final String realmName;

  @override
  State<ConnectionsPanel> createState() => _ConnectionsPanelState();
}

class _ConnectionsPanelState extends State<ConnectionsPanel> {
  final Set<String> _connected = {'Google'};

  static const List<(String, String)> _accounts = [
    ('Google', 'Docs, Drive, and selected account permissions'),
    ('Bluesky', 'One verified social account'),
    ('Telegram', 'One verified messaging account'),
    ('Solana wallet', 'One external wallet and explicit signing scope'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CapacityHeader(
            eyebrow: l10n.connections,
            heading: l10n.accountsRealmMayReach(widget.realmName),
            status: l10n.everyAccountSpecificAndVerified,
          ),
          const SizedBox(height: 14),
          for (final (name, detail) in _accounts) ...[
            _ConnectionRow(
              name: name,
              detail: detail,
              connected: _connected.contains(name),
              onToggle: () => setState(() {
                if (_connected.contains(name)) {
                  _connected.remove(name);
                } else {
                  _connected.add(name);
                }
              }),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ConnectionRow extends StatelessWidget {
  const _ConnectionRow({
    required this.name,
    required this.detail,
    required this.connected,
    required this.onToggle,
  });

  final String name;
  final String detail;
  final bool connected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(6, 3, 4, 0.36),
        border: Border.all(color: colors.camel.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: text.label.copyWith(
                    color: colors.cream,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(detail, style: text.micro.copyWith(color: colors.quiet)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          connected
              ? OutlinedButton(
                  onPressed: onToggle,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: colors.mint,
                    backgroundColor: colors.sky.withValues(alpha: 0.045),
                    side: BorderSide(
                      color: colors.mint.withValues(alpha: 0.28),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    textStyle: text.micro,
                  ),
                  child: Text(l10n.connectedDisconnect),
                )
              : OutlinedButton(
                  onPressed: onToggle,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    foregroundColor: colors.skyButtonInk,
                    backgroundColor: colors.sky,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    textStyle: text.label.copyWith(fontWeight: FontWeight.w700),
                  ),
                  child: Text(l10n.connect),
                ),
        ],
      ),
    );
  }
}

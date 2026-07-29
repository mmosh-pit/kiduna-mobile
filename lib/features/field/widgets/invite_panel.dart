import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/context_extensions.dart';
import '../data/field_fixtures.dart';
import 'field_inputs.dart';

/// The Invite working panel: a form to prepare a one-person invitation, which
/// swaps to a review of the personal message, unique link, and Kinship Code.
class InvitePanel extends StatefulWidget {
  const InvitePanel({super.key});

  @override
  State<InvitePanel> createState() => _InvitePanelState();
}

class _InvitePanelState extends State<InvitePanel> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  final Set<String> _roles = {'Member'};
  String _expiration = '7 days';
  bool _prepared = false;

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  String get _message {
    final name = _name.text.trim().isEmpty ? 'Friend' : _name.text.trim();
    final roles = _roles.isEmpty ? 'Member' : _roles.join(' and ');
    return '$name, Alice has invited you to join Kinship Duna as $roles. '
        'Open your personal invitation: ${FieldFixtures.invitationLink}\n'
        'Or enter Kinship Code: ${FieldFixtures.invitationCode}\n\n'
        'This invitation expires in $_expiration.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: _prepared ? _review(context) : _form(context),
    );
  }

  Widget _form(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldTextInput(
          label: '${l10n.nameYouUseForThem} *',
          controller: _name,
          hint: 'What you most commonly call them',
        ),
        const SizedBox(height: 12),
        FieldDropdown(
          label: l10n.expiration,
          value: _expiration,
          options: FieldFixtures.expirations,
          onChanged: (value) => setState(() => _expiration = value),
        ),
        const SizedBox(height: 12),
        FieldLabel(text: l10n.proposedRole),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final role in FieldFixtures.roles)
              FilterChip(
                label: Text(role),
                selected: _roles.contains(role),
                onSelected: (on) =>
                    setState(() => on ? _roles.add(role) : _roles.remove(role)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        FieldTextInput(
          label: l10n.notes,
          controller: _notes,
          hint: 'Personal to you. Helps Ki welcome your guest.',
          maxLines: 3,
        ),
        const SizedBox(height: 14),
        FieldPrimaryButton(
          label: l10n.prepareInvitation,
          onPressed: () => setState(() => _prepared = true),
        ),
      ],
    );
  }

  Widget _review(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.personalInvitation.toUpperCase(),
          style: text.eyebrowSmall.copyWith(color: colors.gold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.deep.withValues(alpha: 0.55),
            border: Border.all(color: colors.camel.withValues(alpha: 0.22)),
            borderRadius: BorderRadius.circular(context.metrics.radiusMd),
          ),
          child: Text(
            _message,
            style: text.bodySmall.copyWith(color: colors.muted),
          ),
        ),
        const SizedBox(height: 12),
        _CopyRow(
          label: context.l10n.uniqueLink,
          value: FieldFixtures.invitationLink,
          action: context.l10n.copyLink,
        ),
        const SizedBox(height: 8),
        _CopyRow(
          label: context.l10n.kinshipCode,
          value: FieldFixtures.invitationCode,
          action: context.l10n.copyCode,
        ),
      ],
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({
    required this.label,
    required this.value,
    required this.action,
  });

  final String label;
  final String value;
  final String action;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: text.micro.copyWith(color: colors.quiet),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall.copyWith(color: colors.text),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
          },
          child: Text(action),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/kiduna_motion.dart';
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
  final TextEditingController _handshake = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  String _role = 'Member';
  late String _expiration;
  bool _prepared = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _expiration = context.l10n.sevenDays;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _handshake.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _buildMessage(BuildContext context) {
    final l10n = context.l10n;
    final name = _name.text.trim().isEmpty ? l10n.friend : _name.text.trim();
    return l10n.invitationMessageFor(name);
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: const EdgeInsets.all(18),
      child: AnimatedSwitcher(
        duration: reducedMotion ? Duration.zero : KidunaMotion.panelIn,
        child: _prepared ? _review(context) : _form(context),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FieldTextInput(
                label: '${l10n.nameYouUseForThem} *',
                controller: _name,
                hint: l10n.whatYouMostCommonlyCallThem,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FieldDropdown(
                label: l10n.expiration,
                value: _expiration,
                options: FieldFixtures.expirations,
                onChanged: (value) => setState(() => _expiration = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FieldDropdown(
                label: l10n.proposedRole,
                value: _role,
                options: FieldFixtures.roles,
                onChanged: (value) => setState(() => _role = value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FieldTextInput(
                label: l10n.privateHandshakeOptional,
                controller: _handshake,
                hint: l10n.shareASecretWordOrPhrase,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FieldTextInput(
          label: l10n.notes,
          controller: _notes,
          hint: l10n.invitationNotesHint,
          maxLines: 5,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.requiredField,
          style: context.kidunaText.micro.copyWith(color: context.kiduna.quiet),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: FieldPrimaryButton(
            label: l10n.prepareInvitation,
            onPressed: () => setState(() => _prepared = true),
          ),
        ),
      ],
    );
  }

  Widget _review(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Column(
      key: const ValueKey('review'),
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
            _buildMessage(context),
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
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.copiedToClipboard)),
              );
            }
          },
          child: Text(action),
        ),
      ],
    );
  }
}

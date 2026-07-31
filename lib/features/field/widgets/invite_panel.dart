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
  TextEditingController? _message;
  String _role = 'Member';
  late String _expiration;
  bool _prepared = false;
  bool _initialized = false;
  bool _editing = false;
  String? _copyStatus;

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
    _message?.dispose();
    super.dispose();
  }

  void _prepare() {
    final l10n = context.l10n;
    final name = _name.text.trim().isEmpty ? l10n.friend : _name.text.trim();
    _message = TextEditingController(text: l10n.invitationMessageFor(name));
    setState(() => _prepared = true);
  }

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }
    setState(() => _copyStatus = label);
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
          style: context.kidunaText.label.copyWith(color: context.kiduna.cream),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: FieldPrimaryButton(
            label: l10n.prepareInvitation,
            onPressed: _prepare,
          ),
        ),
      ],
    );
  }

  Widget _review(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.kiduna;
    final text = context.kidunaText;
    final name = _name.text.trim().isEmpty ? l10n.friend : _name.text.trim();
    return Column(
      key: const ValueKey('review'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.invitationIntendedOnlyFor(name),
          style: text.caption.copyWith(color: colors.cream, height: 1.5),
        ),
        const SizedBox(height: 14),
        // _prepared guarantees _message was initialised in _prepare()
        _InvitationEditor(
          message: _message!,
          editing: _editing,
          onToggleEdit: () => setState(() => _editing = !_editing),
          onCopy: () => _copy(l10n.invitationCopied, _message!.text),
        ),
        const SizedBox(height: 14),
        _InvitationPartRow(
          label: l10n.uniqueLink,
          value: FieldFixtures.invitationLink,
          action: l10n.copyLink,
          onCopy: () => _copy(l10n.linkCopied, FieldFixtures.invitationLink),
        ),
        const SizedBox(height: 8),
        _InvitationPartRow(
          label: l10n.kinshipCode,
          value: FieldFixtures.invitationCode,
          action: l10n.copyCode,
          onCopy: () => _copy(l10n.codeCopied, FieldFixtures.invitationCode),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: FieldPrimaryButton(
            label: l10n.sendThroughKi,
            onPressed: () {},
          ),
        ),
        if (_copyStatus != null) ...[
          const SizedBox(height: 8),
          Text(_copyStatus!, style: text.micro.copyWith(color: colors.mint)),
        ],
      ],
    );
  }
}

class _InvitationEditor extends StatelessWidget {
  const _InvitationEditor({
    required this.message,
    required this.editing,
    required this.onToggleEdit,
    required this.onCopy,
  });

  final TextEditingController message;
  final bool editing;
  final VoidCallback onToggleEdit;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(6, 3, 4, 0.55),
        border: Border.all(color: colors.camel.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(11, 7, 8, 7),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.camel.withValues(alpha: 0.14)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.personalInvitation.toUpperCase(),
                    style: text.micro.copyWith(
                      color: colors.gold,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08 * 10,
                    ),
                  ),
                ),
                _EditorIconButton(
                  icon: Icons.edit_outlined,
                  onPressed: onToggleEdit,
                ),
                const SizedBox(width: 5),
                _EditorIconButton(icon: Icons.copy_outlined, onPressed: onCopy),
              ],
            ),
          ),
          TextField(
            controller: message,
            readOnly: !editing,
            maxLines: null,
            minLines: 7,
            style: text.bodySmall.copyWith(
              color: editing ? colors.text : colors.muted,
              height: 1.6,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(13),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorIconButton extends StatelessWidget {
  const _EditorIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        iconSize: 14,
        style: IconButton.styleFrom(
          backgroundColor: colors.sky.withValues(alpha: 0.05),
          side: BorderSide(color: colors.sky.withValues(alpha: 0.24)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        icon: Icon(icon, color: colors.sky),
      ),
    );
  }
}

class _InvitationPartRow extends StatelessWidget {
  const _InvitationPartRow({
    required this.label,
    required this.value,
    required this.action,
    required this.onCopy,
  });

  final String label;
  final String value;
  final String action;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(6, 3, 4, 0.4),
        border: Border.all(color: colors.camel.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(label, style: text.micro.copyWith(color: colors.muted)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.micro.copyWith(
                color: colors.cream,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: onCopy,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 30),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              foregroundColor: colors.sky,
              backgroundColor: colors.sky.withValues(alpha: 0.05),
              side: BorderSide(color: colors.sky.withValues(alpha: 0.24)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              textStyle: text.label,
            ),
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

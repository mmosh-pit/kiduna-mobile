import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/kiduna_motion.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/ki_topic.dart';
import '../controllers/field_controller.dart';
import '../data/field_fixtures.dart';
import 'field_inputs.dart';

/// The Invite working panel: a form to prepare a one-person invitation, which
/// calls the backend API and then swaps to a review of the personal message,
/// unique link, and Kinship Code.
class InvitePanel extends ConsumerStatefulWidget {
  const InvitePanel({super.key, this.askAbout});

  final ValueChanged<KiTopic>? askAbout;

  @override
  ConsumerState<InvitePanel> createState() => _InvitePanelState();
}

class _InvitePanelState extends ConsumerState<InvitePanel> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _expirationAmount = TextEditingController(
    text: '7',
  );
  TextEditingController? _message;
  String _role = 'Member';
  bool _expirationEnabled = false;
  String _expirationUnit = 'days';
  bool _prepared = false;
  bool _editing = false;
  String? _copyStatus;

  String get _expirationValue {
    if (!_expirationEnabled) return 'never';
    if (_expirationUnit == 'never') return 'never';
    final amount = _expirationAmount.text.trim();
    if (amount.isEmpty) return 'never';
    return '$amount $_expirationUnit';
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _expirationAmount.dispose();
    _message?.dispose();
    super.dispose();
  }

  String? _nameError;
  String? _expirationError;

  bool _validate() {
    final name = _name.text.trim();
    String? nameErr;
    String? expErr;

    if (name.isEmpty) {
      nameErr = 'Name is required';
    }

    if (_expirationEnabled && _expirationUnit != 'never') {
      final raw = _expirationAmount.text.trim();
      final amount = int.tryParse(raw);
      if (raw.isEmpty || amount == null || amount <= 0) {
        expErr = 'Enter a valid number';
      }
    }

    setState(() {
      _nameError = nameErr;
      _expirationError = expErr;
    });

    return nameErr == null && expErr == null;
  }

  Future<void> _prepare() async {
    if (!_validate()) return;

    final controller = ref.read(fieldControllerProvider.notifier);
    await controller.prepareInvitation(
      recipientName: _name.text.trim(),
      role: _role,
      expiration: _expirationValue,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    if (!mounted) {
      return;
    }

    // Check if API succeeded — read fresh state.
    final state = ref.read(fieldControllerProvider);
    if (state.invitationResponse != null) {
      _message = TextEditingController(
        text: state.invitationResponse!.invitationMessage,
      );
      setState(() => _prepared = true);
    }
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
    final invLoading = ref.watch(
      fieldControllerProvider.select((s) => s.invitationLoading),
    );
    final invError = ref.watch(
      fieldControllerProvider.select((s) => s.invitationError),
    );
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: const EdgeInsets.all(18),
      child: AnimatedSwitcher(
        duration: reducedMotion ? Duration.zero : KidunaMotion.panelIn,
        child: _prepared
            ? _review(context)
            : _form(context, isLoading: invLoading, error: invError),
      ),
    );
  }

  Widget _form(BuildContext context, {bool isLoading = false, String? error}) {
    final l10n = context.l10n;
    final colors = context.kiduna;
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _FormGrid(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FieldTextInput(
                  label: '${l10n.nameYouUseForThem} *',
                  controller: _name,
                  hint: l10n.whatYouMostCommonlyCallThem,
                ),
                if (_nameError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _nameError!,
                    style: TextStyle(color: colors.orange, fontSize: 11),
                  ),
                ],
              ],
            ),
            _ExpirationInput(
              enabled: _expirationEnabled,
              amount: _expirationAmount,
              unit: _expirationUnit,
              error: _expirationError,
              onEnabledChanged: (v) => setState(() => _expirationEnabled = v),
              onUnitChanged: (v) => setState(() => _expirationUnit = v),
            ),
            FieldDropdown(
              label: l10n.proposedRole,
              value: _role,
              options: FieldFixtures.roles,
              onChanged: (v) => setState(() => _role = v),
            ),
            _FullWidth(
              child: FieldTextInput(
                label: l10n.notes,
                controller: _notes,
                hint: l10n.invitationNotesHint,
                maxLines: 5,
                minHeight: 104,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 2, 0, 9),
          child: Text(
            l10n.requiredField,
            style: context.kidunaText.label.copyWith(
              color: context.kiduna.cream,
            ),
          ),
        ),
        if (error != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, size: 16, color: colors.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error,
                    style: context.kidunaText.bodySmall.copyWith(
                      color: colors.gold,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colors.sky,
                  ),
                )
              : FieldPrimaryButton(
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
    final invitation = ref.read(fieldControllerProvider).invitationResponse;
    final name =
        invitation?.recipientName ??
        (_name.text.trim().isEmpty ? l10n.friend : _name.text.trim());
    final link = invitation?.invitationLink ?? '';
    final code = invitation?.code ?? '';
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
        _InvitationEditor(
          message: _message!,
          editing: _editing,
          onToggleEdit: () => setState(() => _editing = !_editing),
          onCopy: () => _copy(l10n.invitationCopied, _message!.text),
        ),
        const SizedBox(height: 14),
        _InvitationPartRow(
          label: l10n.uniqueLink,
          value: link,
          action: l10n.copyLink,
          onCopy: () => _copy(l10n.linkCopied, link),
        ),
        const SizedBox(height: 8),
        _InvitationPartRow(
          label: l10n.kinshipCode,
          value: code,
          action: l10n.copyCode,
          onCopy: () => _copy(l10n.codeCopied, code),
        ),
        if (_copyStatus != null) ...[
          const SizedBox(height: 8),
          Text(_copyStatus!, style: text.label.copyWith(color: colors.mint)),
        ],
      ],
    );
  }
}

/// CSS `.formGrid` — 2-column grid with 12px gap.
class _FormGrid extends StatelessWidget {
  const _FormGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    var i = 0;
    while (i < children.length) {
      final child = children[i];
      if (child is _FullWidth) {
        rows.add(child.child);
        i++;
      } else if (i + 1 < children.length && children[i + 1] is! _FullWidth) {
        rows.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: children[i]),
              const SizedBox(width: 12),
              Expanded(child: children[i + 1]),
            ],
          ),
        );
        i += 2;
      } else {
        rows.add(child);
        i++;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 12),
          rows[r],
        ],
      ],
    );
  }
}

class _FullWidth extends StatelessWidget {
  const _FullWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Expiration toggle: checkbox + number input + unit dropdown on one row.
class _ExpirationInput extends StatelessWidget {
  const _ExpirationInput({
    required this.enabled,
    required this.amount,
    required this.unit,
    required this.onEnabledChanged,
    required this.onUnitChanged,
    this.error,
  });

  final bool enabled;
  final TextEditingController amount;
  final String unit;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<String> onUnitChanged;
  final String? error;

  static const _units = ['minutes', 'hours', 'days', 'never'];

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(text: context.l10n.expiration),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: 18,
              height: 16,
              child: Checkbox(
                value: enabled,
                onChanged: (v) => onEnabledChanged(v ?? false),
                activeColor: colors.sky,
                side: BorderSide(color: colors.camel.withValues(alpha: 0.4)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            if (!enabled)
              Text(
                'Never expires',
                style: text.caption.copyWith(color: colors.muted, height: 1.4),
              ),
            if (enabled && unit != 'never') ...[
              SizedBox(
                width: 56,
                height: 37,
                child: TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: text.caption.copyWith(color: colors.text, height: 1.4),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
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
                    filled: true,
                    fillColor: const Color.fromRGBO(6, 3, 4, 0.66),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (enabled)
              Container(
                height: 37,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(6, 3, 4, 0.66),
                  border: Border.all(
                    color: colors.camel.withValues(alpha: 0.24),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: unit,
                    dropdownColor: const Color.fromRGBO(30, 20, 12, 0.99),
                    style: text.caption.copyWith(
                      color: colors.text,
                      height: 1.4,
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: colors.muted,
                      size: 18,
                    ),
                    items: [
                      for (final u in _units)
                        DropdownMenuItem(value: u, child: Text(u)),
                    ],
                    onChanged: (v) {
                      if (v != null) onUnitChanged(v);
                    },
                  ),
                ),
              ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error!, style: TextStyle(color: colors.orange, fontSize: 11)),
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
                    style: text.label.copyWith(
                      color: colors.gold,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
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
            style: text.caption.copyWith(
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
            child: Text(label, style: text.label.copyWith(color: colors.muted)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.label.copyWith(
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

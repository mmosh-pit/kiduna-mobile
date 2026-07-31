import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/kiduna_colors.dart';
import '../../../config/kiduna_motion.dart';
import '../../../config/kiduna_text.dart';
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
  final TextEditingController _handshake = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  TextEditingController? _message;
  List<String> _roles = const ['Member'];
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

  void _askField(String label, String question) {
    widget.askAbout?.call(
      KiTopic(
        title: label,
        body: question,
        invitation:
            'Ki can explain this field or help Alice decide what belongs here.',
      ),
    );
  }

  Future<void> _prepare() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() {});
      return;
    }

    final controller = ref.read(fieldControllerProvider.notifier);
    await controller.prepareInvitation(
      recipientName: name,
      role: _roles.join(', '),
      expiration: _expiration,
      handshake: _handshake.text.trim().isEmpty ? null : _handshake.text.trim(),
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
            FieldTextInput(
              label: '${l10n.nameYouUseForThem} *',
              controller: _name,
              hint: l10n.whatYouMostCommonlyCallThem,
              onAskKi: () => _askField(
                '${l10n.nameYouUseForThem} *',
                'Use the name Alice naturally uses for this person so the '
                    'invitation feels unmistakably personal.',
              ),
            ),
            FieldDropdown(
              label: l10n.expiration,
              value: _expiration,
              options: FieldFixtures.expirations,
              onChanged: (value) => setState(() => _expiration = value),
              onAskKi: () => _askField(
                l10n.expiration,
                'Expiration limits how long this one-person invitation can '
                'be used.',
              ),
            ),
            _RoleMultiSelect(
              roles: _roles,
              onChanged: (next) => setState(() => _roles = next),
              onAskKi: () => _askField(
                l10n.proposedRole,
                'A proposed role describes the access and responsibility '
                'Alice intends to offer. It is not active until the '
                'invitation is accepted.',
              ),
              onAskRole: (role) => widget.askAbout?.call(
                KiTopic(
                  title: '$role in this Realm',
                  body:
                      'Ki can explain what the $role role may see and do in the '
                      'current Realm before Alice includes it.',
                  invitation:
                      'Ask Ki to compare $role with another role or explain its '
                      'authority in this context.',
                ),
              ),
            ),
            FieldTextInput(
              label: l10n.privateHandshakeOptional,
              controller: _handshake,
              hint: l10n.shareASecretWordOrPhrase,
              onAskKi: () => _askField(
                l10n.privateHandshakeOptional,
                'A handshake is a secret Alice and the invited person already '
                'share, helping them recognize each other at the threshold.',
              ),
            ),
            _FullWidth(
              child: FieldTextInput(
                label: l10n.notes,
                controller: _notes,
                hint: l10n.invitationNotesHint,
                maxLines: 5,
                minHeight: 104,
                onAskKi: () => _askField(
                  l10n.notes,
                  'Notes help Ki welcome this person appropriately. They '
                  'remain Personal to Alice unless she deliberately '
                  'shares them.',
                ),
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

/// CSS `.roleField` — multi-select role dropdown with checkboxes.
class _RoleMultiSelect extends StatefulWidget {
  const _RoleMultiSelect({
    required this.roles,
    required this.onChanged,
    this.onAskKi,
    this.onAskRole,
  });

  final List<String> roles;
  final ValueChanged<List<String>> onChanged;
  final VoidCallback? onAskKi;
  final ValueChanged<String>? onAskRole;

  @override
  State<_RoleMultiSelect> createState() => _RoleMultiSelectState();
}

class _RoleMultiSelectState extends State<_RoleMultiSelect> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _overlay;

  void _toggle() {
    if (_overlay != null) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    final overlay = Overlay.of(context);
    final box = context.findRenderObject()! as RenderBox;
    final width = box.size.width;
    _overlay = OverlayEntry(
      builder: (_) => _RoleDropdownOverlay(
        link: _link,
        width: width,
        roles: widget.roles,
        onChanged: widget.onChanged,
        onAskRole: widget.onAskRole,
        onClose: _close,
      ),
    );
    overlay.insert(_overlay!);
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(text: context.l10n.proposedRole, onAskKi: widget.onAskKi),
        const SizedBox(height: 6),
        CompositedTransformTarget(
          link: _link,
          child: GestureDetector(
            onTap: _toggle,
            child: Container(
              height: 37,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(6, 3, 4, 0.66),
                border: Border.all(color: colors.camel.withValues(alpha: 0.24)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.roles.isEmpty
                    ? context.l10n.chooseRoles
                    : widget.roles.join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.caption.copyWith(color: colors.text, height: 1.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleDropdownOverlay extends StatefulWidget {
  const _RoleDropdownOverlay({
    required this.link,
    required this.width,
    required this.roles,
    required this.onChanged,
    required this.onClose,
    this.onAskRole,
  });

  final LayerLink link;
  final double width;
  final List<String> roles;
  final ValueChanged<List<String>> onChanged;
  final ValueChanged<String>? onAskRole;
  final VoidCallback onClose;

  @override
  State<_RoleDropdownOverlay> createState() => _RoleDropdownOverlayState();
}

class _RoleDropdownOverlayState extends State<_RoleDropdownOverlay> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.of(widget.roles);
  }

  void _toggleRole(String role) {
    setState(() {
      if (_selected.contains(role)) {
        _selected.remove(role);
      } else {
        _selected.add(role);
      }
    });
    widget.onChanged(_selected);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            behavior: HitTestBehavior.opaque,
          ),
        ),
        CompositedTransformFollower(
          link: widget.link,
          offset: const Offset(0, 42),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: widget.width,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(30, 20, 12, 0.99),
                border: Border.all(color: colors.camel.withValues(alpha: 0.36)),
                borderRadius: BorderRadius.circular(7),
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(0, 18),
                    blurRadius: 40,
                    color: Color.fromRGBO(0, 0, 0, 0.58),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final role in FieldFixtures.roles)
                    _RoleRow(
                      role: role,
                      checked: _selected.contains(role),
                      onToggle: () => _toggleRole(role),
                      onAsk: widget.onAskRole != null
                          ? () => widget.onAskRole!(role)
                          : null,
                      text: text,
                      colors: colors,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.role,
    required this.checked,
    required this.onToggle,
    required this.onAsk,
    required this.text,
    required this.colors,
  });

  final String role;
  final bool checked;
  final VoidCallback onToggle;
  final VoidCallback? onAsk;
  final KidunaText text;
  final KidunaColors colors;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(4),
      hoverColor: colors.sky.withValues(alpha: 0.055),
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 16,
              child: Checkbox(
                value: checked,
                onChanged: (_) => onToggle(),
                activeColor: colors.sky,
                side: BorderSide(color: colors.camel.withValues(alpha: 0.4)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                role,
                style: text.caption.copyWith(color: colors.text, height: 1.4),
              ),
            ),
            if (onAsk != null)
              GestureDetector(
                onTap: onAsk,
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.sky.withValues(alpha: 0.06),
                    border: Border.all(
                      color: colors.sky.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    '→',
                    style: text.micro.copyWith(color: colors.sky, height: 1),
                  ),
                ),
              ),
          ],
        ),
      ),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/kiduna_motion.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/invitation_response.dart';
import '../../../data/models/ki_topic.dart';
import '../../ki_chat/controllers/ki_chat_controller.dart';
import '../controllers/field_controller.dart';
import '../data/field_fixtures.dart';
import 'field_inputs.dart';

/// The Invite working panel: a form to prepare a realm invitation with
/// optional KIDUNA sponsorship. After creation, swaps to a review showing
/// the invite link, code, and a summary.
class InvitePanel extends ConsumerStatefulWidget {
  const InvitePanel({super.key, this.askAbout});

  final ValueChanged<KiTopic>? askAbout;

  @override
  ConsumerState<InvitePanel> createState() => _InvitePanelState();
}

class _InvitePanelState extends ConsumerState<InvitePanel> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _label = TextEditingController();
  final TextEditingController _maxUses = TextEditingController(text: '1');
  final TextEditingController _expirationAmount = TextEditingController(
    text: '7',
  );
  final TextEditingController _kidunaPerPerson = TextEditingController();
  String _role = 'Member';
  String _expirationUnit = 'days';
  bool _prepared = false;
  String? _copyStatus;

  // Validation errors
  String? _maxUsesError;
  String? _expirationError;
  String? _kidunaError;

  String get _expirationValue {
    final amount = _expirationAmount.text.trim();
    if (amount.isEmpty) return '7 days';
    return '$amount $_expirationUnit';
  }

  double get _kidunaAmount {
    return double.tryParse(_kidunaPerPerson.text.trim()) ?? 0;
  }

  int get _maxUsesValue {
    return int.tryParse(_maxUses.text.trim()) ?? 1;
  }

  double get _totalKidunaLock => _kidunaAmount * _maxUsesValue;

  @override
  void dispose() {
    _name.dispose();
    _label.dispose();
    _maxUses.dispose();
    _expirationAmount.dispose();
    _kidunaPerPerson.dispose();
    super.dispose();
  }

  bool _validate() {
    String? maxErr;
    String? expErr;
    String? kidErr;

    final uses = int.tryParse(_maxUses.text.trim());
    if (uses == null || uses <= 0) {
      maxErr = 'Enter a number greater than 0';
    }

    final expAmt = int.tryParse(_expirationAmount.text.trim());
    if (expAmt == null || expAmt <= 0) {
      expErr = 'Enter a valid number';
    }

    final kiduna = _kidunaAmount;
    if (_kidunaPerPerson.text.trim().isNotEmpty && kiduna < 0) {
      kidErr = 'Must be 0 or more';
    }

    // If sponsoring, require max_uses
    if (kiduna > 0 && (uses == null || uses <= 0)) {
      maxErr = 'Required for sponsored invites';
    }

    setState(() {
      _maxUsesError = maxErr;
      _expirationError = expErr;
      _kidunaError = kidErr;
    });

    return maxErr == null && expErr == null && kidErr == null;
  }

  Future<void> _prepare() async {
    if (!_validate()) return;

    final controller = ref.read(fieldControllerProvider.notifier);
    await controller.prepareInvitation(
      role: _role,
      expiration: _expirationValue,
      maxUses: _maxUsesValue,
      recipientName:
          _name.text.trim().isEmpty ? null : _name.text.trim(),
      label: _label.text.trim().isEmpty ? null : _label.text.trim(),
      kidunaPerPerson: _kidunaAmount,
    );

    if (!mounted) return;

    final state = ref.read(fieldControllerProvider);
    if (state.invitationResponse != null) {
      setState(() => _prepared = true);
    }
  }

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    setState(() => _copyStatus = label);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copyStatus = null);
    });
  }

  Future<void> _downloadQr(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
            // Row 1: Name (optional) | Role
            FieldTextInput(
              label: l10n.nameYouUseForThem,
              controller: _name,
              hint: 'Optional — for named invites',
            ),
            FieldDropdown(
              label: l10n.proposedRole,
              value: _role,
              options: FieldFixtures.roles,
              onChanged: (v) => setState(() => _role = v),
            ),

            // Row 2: Number of People | Expiration
            _ValidatedInput(
              label: 'Number of People *',
              controller: _maxUses,
              error: _maxUsesError,
              hint: '1',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            _ExpirationInput(
              amount: _expirationAmount,
              unit: _expirationUnit,
              error: _expirationError,
              onUnitChanged: (v) => setState(() => _expirationUnit = v),
            ),

            // Row 3: KIDUNA per Person | Label
            _ValidatedInput(
              label: 'KIDUNA per Person',
              controller: _kidunaPerPerson,
              error: _kidunaError,
              hint: '0 — no sponsorship',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              onChanged: (_) => setState(() {}),
            ),
            FieldTextInput(
              label: 'Label',
              controller: _label,
              hint: 'e.g. ETH Denver 2026',
            ),

            // Total KIDUNA lock — directly below sponsor row
            if (_kidunaAmount > 0 && _maxUsesValue > 0)
              _FullWidth(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.gold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: colors.gold.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    'Total KIDUNA to lock: ${_formatNumber(_totalKidunaLock)}'
                    ' (${_formatNumber(_kidunaAmount)} × $_maxUsesValue people)',
                    style: context.kidunaText.caption.copyWith(
                      color: colors.gold,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),
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
    final colors = context.kiduna;
    final text = context.kidunaText;
    final invitation = ref.read(fieldControllerProvider).invitationResponse;
    if (invitation == null) return const SizedBox.shrink();

    final link = invitation.invitationLink;
    final code = invitation.code;

    return Column(
      key: const ValueKey('review'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Summary line
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: colors.gold.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: colors.gold.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            invitation.summary,
            style: text.caption.copyWith(
              color: colors.gold,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Invite URL
        _InvitationPartRow(
          label: 'Invite URL',
          value: link,
          action: 'Copy Link',
          onCopy: () => _copy('Link copied', link),
        ),
        const SizedBox(height: 8),

        // Code
        _InvitationPartRow(
          label: 'Code',
          value: code,
          action: 'Copy Code',
          onCopy: () => _copy('Code copied', code),
        ),
        const SizedBox(height: 14),

        // QR Code
        if (invitation.qrCodeUrl.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(6, 3, 4, 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colors.camel.withValues(alpha: 0.14),
              ),
            ),
            child: Column(
              children: [
                // QR image
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Image.network(
                    invitation.qrCodeUrl,
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return SizedBox(
                        width: 140,
                        height: 140,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.sky,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stack) {
                      return SizedBox(
                        width: 140,
                        height: 140,
                        child: Center(
                          child: Text(
                            'QR unavailable',
                            style: text.caption.copyWith(color: colors.muted),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Download + Copy QR link row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _copy(
                        'QR link copied',
                        invitation.qrCodeUrl,
                      ),
                      icon: Icon(Icons.link, size: 16, color: colors.sky),
                      label: Text('Copy QR Link',
                          style: text.caption.copyWith(color: colors.sky)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        side: BorderSide(
                            color: colors.sky.withValues(alpha: 0.24)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _downloadQr(invitation.qrCodeUrl),
                      icon: Icon(Icons.download, size: 16, color: colors.sky),
                      label: Text('Download',
                          style: text.caption.copyWith(color: colors.sky)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        side: BorderSide(
                            color: colors.sky.withValues(alpha: 0.24)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Copy invite text button
        Align(
          alignment: Alignment.centerLeft,
          child: FieldPrimaryButton(
            label: 'Copy Invite Text',
            onPressed: () => _copy('Invite text copied', invitation.shareText),
          ),
        ),
        const SizedBox(height: 14),

        // ── Send via Email ──
        _EmailSendSection(
          invitation: invitation,
          onCopyStatus: (msg) {
            setState(() => _copyStatus = msg);
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) setState(() => _copyStatus = null);
            });
          },
        ),

        if (_copyStatus != null) ...[
          const SizedBox(height: 8),
          Text(
            _copyStatus!,
            style: text.caption.copyWith(color: colors.mint),
          ),
        ],
      ],
    );
  }

  String _formatNumber(double n) {
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1)}M';
    }
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    }
    return n.toStringAsFixed(n == n.roundToDouble() ? 0 : 2);
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

/// A text input with an optional validation error below it.
class _ValidatedInput extends StatelessWidget {
  const _ValidatedInput({
    required this.label,
    required this.controller,
    this.error,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? error;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(text: label),
        const SizedBox(height: 6),
        SizedBox(
          height: 37,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            style: text.caption.copyWith(color: colors.text, height: 1.4),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: text.caption.copyWith(
                color: colors.muted.withValues(alpha: 0.5),
                height: 1.4,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
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
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error!, style: TextStyle(color: colors.orange, fontSize: 11)),
        ],
      ],
    );
  }
}

/// Expiration input: number + unit dropdown (always visible, no checkbox).
class _ExpirationInput extends StatelessWidget {
  const _ExpirationInput({
    required this.amount,
    required this.unit,
    required this.onUnitChanged,
    this.error,
  });

  final TextEditingController amount;
  final String unit;
  final ValueChanged<String> onUnitChanged;
  final String? error;

  static const _units = ['minutes', 'hours', 'days'];

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(text: 'Expiration *'),
        const SizedBox(height: 6),
        Row(
          children: [
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
            width: 72,
            child: Text(
              label,
              style: text.caption.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.caption.copyWith(
                color: colors.cream,
                fontFamily: 'monospace',
                fontSize: 13,
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
              textStyle: text.caption,
            ),
            child: Text(action),
          ),
        ],
      ),
    );
  }
}


/// Send invite via email using connected Google account.
/// If Google is not connected, shows a "Connect Google" prompt.
class _EmailSendSection extends ConsumerStatefulWidget {
  const _EmailSendSection({
    required this.invitation,
    required this.onCopyStatus,
  });

  final InvitationResponse invitation;
  final ValueChanged<String> onCopyStatus;

  @override
  ConsumerState<_EmailSendSection> createState() => _EmailSendSectionState();
}

class _EmailSendSectionState extends ConsumerState<_EmailSendSection> {
  final TextEditingController _emailController = TextEditingController();
  bool _sending = false;
  String? _sendResult;
  bool _sendSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool get _isGoogleConnected {
    final tools = ref.read(fieldControllerProvider).savedTools;
    return tools.any((t) => t.toolName == 'google' && t.isActive);
  }

  Future<void> _sendEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _sendResult = 'Please enter a valid email address.';
        _sendSuccess = false;
      });
      return;
    }

    setState(() {
      _sending = true;
      _sendResult = null;
    });

    try {
      final invitation = widget.invitation;
      final kiChat = ref.read(kiChatControllerProvider.notifier);

      // Compose a message for Ki to send the invite email
      final message =
          'Send an invitation email to $email. '
          'Subject: You\'re invited to join ${invitation.realmName} on Kiduna. '
          'Body: You have been invited to join ${invitation.realmName} on Kiduna! '
          'Your role: ${invitation.role}. '
          '${invitation.kidunaPerPerson > 0 ? '${InvitationResponse.formatKiduna(invitation.kidunaPerPerson)} KIDUNA has been sponsored for you. ' : ''}'
          'Use this link to join: ${invitation.invitationLink} '
          'Or use invitation code: ${invitation.code}';

      kiChat.sendMessage(message);

      if (!mounted) return;
      setState(() {
        _sending = false;
        _sendResult = 'Email request sent to Ki. Check the chat for confirmation.';
        _sendSuccess = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sendResult = 'Failed to send. Please try again.';
        _sendSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    // Watch tools to react to connection changes
    ref.watch(fieldControllerProvider.select((s) => s.savedTools));

    final connected = _isGoogleConnected;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(6, 3, 4, 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.camel.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.email_outlined, size: 16, color: colors.gold),
              const SizedBox(width: 8),
              Text(
                'Send via Email',
                style: text.caption.copyWith(
                  color: colors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (!connected) ...[
            // Google not connected — show connect prompt
            Text(
              'Connect your Google account to send invitations via email.',
              style: text.caption.copyWith(color: colors.muted, height: 1.4),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(fieldControllerProvider.notifier).connectGoogleOAuth();
              },
              icon: Icon(Icons.link, size: 16, color: colors.sky),
              label: Text('Connect Google',
                  style: text.caption.copyWith(color: colors.sky)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                side: BorderSide(color: colors.sky.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ] else ...[
            // Google connected — show email input + send
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 37,
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: text.caption.copyWith(
                          color: colors.text, height: 1.4),
                      decoration: InputDecoration(
                        hintText: 'Recipient email address',
                        hintStyle: text.caption.copyWith(
                          color: colors.muted.withValues(alpha: 0.5),
                          height: 1.4,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
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
                ),
                const SizedBox(width: 8),
                _sending
                    ? SizedBox(
                        width: 34,
                        height: 34,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.sky,
                            ),
                          ),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: _sendEmail,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 37),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          foregroundColor: colors.skyButtonInk,
                          backgroundColor: colors.sky,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                          textStyle: text.caption
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        child: const Text('Send'),
                      ),
              ],
            ),

            if (_sendResult != null) ...[
              const SizedBox(height: 8),
              Text(
                _sendResult!,
                style: text.caption.copyWith(
                  color: _sendSuccess ? colors.mint : colors.orange,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

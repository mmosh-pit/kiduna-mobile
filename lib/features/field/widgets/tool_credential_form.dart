import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/logger.dart';
import 'field_inputs.dart';

/// Callback when credentials are submitted for verification.
typedef OnCredentialsSubmit = void Function(Map<String, String> credentials);

/// Per-tool credential input form. Each tool requires different fields.
///
/// - Bluesky: handle + app password
/// - Telegram: bot token
/// - Google: opens OAuth in browser tab
/// - Solana: auto-connect with default RPC
class ToolCredentialForm extends StatefulWidget {
  const ToolCredentialForm({
    super.key,
    required this.toolName,
    required this.onSubmit,
    required this.onCancel,
    this.isVerifying = false,
    this.error,
  });

  final String toolName;
  final OnCredentialsSubmit onSubmit;
  final VoidCallback onCancel;
  final bool isVerifying;
  final String? error;

  @override
  State<ToolCredentialForm> createState() => _ToolCredentialFormState();
}

class _ToolCredentialFormState extends State<ToolCredentialForm> {
  final _ctrl1 = TextEditingController();
  final _ctrl2 = TextEditingController();
  final _ctrl3 = TextEditingController(); // Telegram owner_chat_id

  @override
  void dispose() {
    _ctrl1.dispose();
    _ctrl2.dispose();
    _ctrl3.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (widget.isVerifying) {
      return false;
    }
    switch (widget.toolName) {
      case 'bluesky':
        return _ctrl1.text.trim().isNotEmpty && _ctrl2.text.trim().isNotEmpty;
      case 'telegram':
        return _ctrl1.text.trim().isNotEmpty;
      case 'solana':
      case 'google':
        return true;
      default:
        return false;
    }
  }

  void _submit() {
    if (!_canSubmit) {
      return;
    }
    switch (widget.toolName) {
      case 'bluesky':
        widget.onSubmit({
          'handle': _ctrl1.text.trim(),
          'app_password': _ctrl2.text.trim(),
        });
      case 'telegram':
        final creds = <String, String>{
          'bot_token': _ctrl1.text.trim(),
        };
        if (_ctrl3.text.trim().isNotEmpty) {
          creds['owner_chat_id'] = _ctrl3.text.trim();
        }
        widget.onSubmit(creds);
      case 'solana':
        widget.onSubmit({
          'rpc_url': 'https://api.mainnet-beta.solana.com',
        });
      case 'google':
        _openGoogleOAuth();
      default:
        break;
    }
  }

  void _openGoogleOAuth() {
    // Google OAuth requires browser redirect — open the studio OAuth
    // initiation URL. After user completes sign-in, the callback saves
    // the token to the backend. User then returns and taps refresh.
    AppLogger.info('Google OAuth redirect requested', tag: 'ToolCredentialForm');
    // TODO: open OAuth URL via url_launcher when added to pubspec.
    // For now show guidance in the form.
    setState(() {});
  }

  String get _displayName {
    switch (widget.toolName) {
      case 'bluesky':
        return 'Bluesky';
      case 'telegram':
        return 'Telegram';
      case 'google':
        return 'Google';
      case 'solana':
        return 'Solana Wallet';
      default:
        return widget.toolName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(6, 3, 4, 0.36),
        border: Border.all(color: colors.camel.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Connect $_displayName',
                  style: text.label.copyWith(
                    color: colors.cream,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onCancel,
                child: Text(
                  '×',
                  style: text.body.copyWith(
                    color: colors.quiet,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._buildFieldsForTool(),
          if (widget.error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colors.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: colors.gold.withValues(alpha: 0.2)),
              ),
              child: Text(
                widget.error!,
                style: text.caption.copyWith(
                  color: colors.gold,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: Listenable.merge([_ctrl1, _ctrl2, _ctrl3]),
            builder: (context, _) => FieldPrimaryButton(
              label: widget.isVerifying
                  ? 'Verifying…'
                  : widget.toolName == 'google'
                      ? 'Open Google Sign-in'
                      : 'Connect',
              onPressed: _canSubmit ? _submit : null,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFieldsForTool() {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final hintStyle = text.caption.copyWith(
      color: colors.muted,
      height: 1.5,
    );

    switch (widget.toolName) {
      case 'bluesky':
        return [
          Text(
            'Enter your Bluesky handle and an App Password. '
            'Create an App Password in Bluesky → Settings → App Passwords.',
            style: hintStyle,
          ),
          const SizedBox(height: 12),
          FieldTextInput(
            label: 'Handle',
            controller: _ctrl1,
            hint: 'yourname.bsky.social',
          ),
          const SizedBox(height: 10),
          FieldTextInput(
            label: 'App password',
            controller: _ctrl2,
            hint: 'xxxx-xxxx-xxxx-xxxx',
          ),
        ];
      case 'telegram':
        return [
          Text(
            'Enter the Bot Token from @BotFather. '
            'Open Telegram, search @BotFather, create a bot, and copy the token.',
            style: hintStyle,
          ),
          const SizedBox(height: 12),
          FieldTextInput(
            label: 'Bot token',
            controller: _ctrl1,
            hint: '1234567890:ABCdefGHIjklMNOpqrSTUvwx',
          ),
          const SizedBox(height: 10),
          FieldTextInput(
            label: 'Chat ID · optional',
            controller: _ctrl3,
            hint: 'Numeric chat ID for bot messages',
          ),
          const SizedBox(height: 6),
          Text(
            'The Chat ID tells the bot which conversation to use. '
            'Send /start to your bot, then check @userinfobot for your ID.',
            style: text.micro.copyWith(color: colors.quiet),
          ),
        ];
      case 'google':
        return [
          Text(
            'Google requires OAuth sign-in through a browser window. '
            'Tapping the button below will open Google\'s consent page. '
            'After you approve, return here and the connection will appear.',
            style: hintStyle,
          ),
          const SizedBox(height: 10),
          Text(
            'Permissions requested: Gmail (read, send, search), '
            'Calendar (read, create events), Drive (file access).',
            style: text.micro.copyWith(color: colors.quiet),
          ),
        ];
      case 'solana':
        return [
          Text(
            'Connects using Solana mainnet RPC. Your wallet address '
            'enables balance checks and transfer operations.',
            style: hintStyle,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.sky.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: colors.sky.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 16, color: colors.sky),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mainnet RPC will be used automatically',
                    style: text.caption.copyWith(color: colors.sky),
                  ),
                ),
              ],
            ),
          ),
        ];
      default:
        return [];
    }
  }
}
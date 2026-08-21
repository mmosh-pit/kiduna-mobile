import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/assets.dart';
import '../../core/extensions/context_extensions.dart';
import '../../data/models/chat_message_model.dart';
import '../../features/ki_chat/controllers/ally_controller.dart';
import '../../features/ki_chat/controllers/ki_chat_controller.dart';
import 'ki_composer.dart';
import 'ki_message_bubble.dart';

const String _kWelcomeMessage =
    'Welcome to your space. I am Ki — your intelligent companion in the '
    'Kinship ecosystem. Ask me anything, and together we will shape what '
    'comes next.';

class KiAgent extends ConsumerStatefulWidget {
  const KiAgent({super.key});

  @override
  ConsumerState<KiAgent> createState() => _KiAgentState();
}

class _KiAgentState extends ConsumerState<KiAgent> {
  final TextEditingController _composerController = TextEditingController();
  bool _historyRequested = false;

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  void _onAllyReady() {
    if (_historyRequested) return;
    _historyRequested = true;
    ref.read(kiChatControllerProvider.notifier).loadHistory();
  }

  void _sendMessage() {
    final text = _composerController.text.trim();
    if (text.isEmpty) return;
    _composerController.clear();
    ref.read(kiChatControllerProvider.notifier).sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final allyState = ref.watch(allyControllerProvider);
    final chatState = ref.watch(kiChatControllerProvider);

    if (allyState.ally != null && !_historyRequested) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onAllyReady());
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F10),
        border: Border(
          left: BorderSide(color: colors.cream.withValues(alpha: 0.1)),
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(-18, 0),
            blurRadius: 50,
            color: Colors.black.withValues(alpha: 0.22),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _KiHeader(isLoading: allyState.isLoading),
            const SizedBox(height: 12),
            if (allyState.error != null && allyState.ally == null)
              Expanded(
                child: _AllyError(
                  error: allyState.error!,
                  onRetry: () =>
                      ref.read(allyControllerProvider.notifier).retry(),
                ),
              )
            else
              Expanded(
                child: _KiChatThread(
                  messages: chatState.messages,
                  isStreaming: chatState.isStreaming,
                  streamingBuffer: chatState.streamingBuffer,
                  isLoading: chatState.isLoading,
                  error: chatState.error,
                ),
              ),
            const SizedBox(height: 8),
            KiComposer(
              controller: _composerController,
              onSend: _sendMessage,
              enabled:
                  !chatState.isStreaming &&
                  !chatState.isLoading &&
                  allyState.ally != null,
            ),
          ],
        ),
      ),
    );
  }
}

class _KiHeader extends StatelessWidget {
  const _KiHeader({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.sky.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                color: colors.sky.withValues(alpha: 0.12),
              ),
            ],
          ),
          child: ClipOval(
            child: ColoredBox(
              color: colors.deep,
              child: Center(
                child: SvgPicture.asset(
                  AppAssets.kidunaMark,
                  width: 22,
                  height: 22,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('Ki', style: text.h5.copyWith(color: colors.cream)),
        const Spacer(),
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: isLoading
                  ? colors.gold.withValues(alpha: 0.18)
                  : colors.sky.withValues(alpha: 0.18),
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            isLoading ? 'CONNECTING' : 'ONLINE',
            style: text.eyebrowSmall.copyWith(
              color: isLoading ? colors.gold : colors.sky,
            ),
          ),
        ),
      ],
    );
  }
}

class _AllyError extends StatelessWidget {
  const _AllyError({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            error,
            style: text.body.copyWith(color: colors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: Text('Retry', style: text.body.copyWith(color: colors.sky)),
          ),
        ],
      ),
    );
  }
}

class _KiChatThread extends StatelessWidget {
  const _KiChatThread({
    required this.messages,
    required this.isStreaming,
    required this.streamingBuffer,
    required this.isLoading,
    this.error,
  });

  final List<ChatMessageModel> messages;
  final bool isStreaming;
  final String streamingBuffer;
  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    if (isLoading && messages.isEmpty) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: colors.sky),
        ),
      );
    }

    if (messages.isEmpty && !isStreaming) {
      return const _WelcomeContent();
    }

    final items = <Widget>[];

    for (final msg in messages) {
      items.add(
        msg.role == ChatRole.user
            ? KiUserBubble(message: msg)
            : KiAssistantBubble(text: msg.content),
      );
    }

    if (isStreaming && streamingBuffer.isNotEmpty) {
      items.add(KiStreamingBubble(text: streamingBuffer));
    } else if (isStreaming) {
      items.add(const KiTypingIndicator());
    }

    if (error != null) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            error!,
            style: text.caption.copyWith(
              color: colors.gold.withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: items[items.length - 1 - index],
        );
      },
    );
  }
}

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent();

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
      child: Container(
        padding: const EdgeInsets.only(left: 14),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: colors.gold.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WELCOME', style: text.eyebrow.copyWith(color: colors.gold)),
            const SizedBox(height: 10),
            Text(
              _kWelcomeMessage,
              style: text.bodyLarge.copyWith(color: colors.muted),
            ),
            const SizedBox(height: 14),
            Text(
              'Type a message below to start a conversation.',
              style: text.caption.copyWith(color: colors.quiet),
            ),
          ],
        ),
      ),
    );
  }
}

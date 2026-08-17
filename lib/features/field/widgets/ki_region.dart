import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/models/ki_topic.dart';
import '../controllers/ally_controller.dart';
import '../controllers/field_controller.dart';
import '../controllers/ki_chat_controller.dart';
import '../data/field_fixtures.dart';
import 'enamel_icon.dart';
import 'ki_composer.dart';

/// The Ki region — CSS `.ki`. The intelligence the Source converses with.
class KiRegion extends ConsumerStatefulWidget {
  const KiRegion({super.key});

  @override
  ConsumerState<KiRegion> createState() => _KiRegionState();
}

class _KiRegionState extends ConsumerState<KiRegion> {
  final TextEditingController _composer = TextEditingController();
  bool _historyRequested = false;
  Timer? _approvalPollTimer;

  @override
  void dispose() {
    _approvalPollTimer?.cancel();
    _composer.dispose();
    super.dispose();
  }

  void _send() {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    ref.read(kiChatControllerProvider.notifier).sendMessage(text);
    _composer.clear();
  }

  @override
  Widget build(BuildContext context) {
    final fieldState = ref.watch(fieldControllerProvider);
    final allyState = ref.watch(allyControllerProvider);
    final chatState = ref.watch(kiChatControllerProvider);

    // Load history once when ally is available.
    if (allyState.ally != null && !_historyRequested) {
      _historyRequested = true;
      Future.microtask(
        () => ref.read(kiChatControllerProvider.notifier).loadHistory(),
      );
      // Fetch pending approval count once ally is available (wallet is ready).
      Future.microtask(
        () => ref.read(fieldControllerProvider.notifier)
            .fetchPendingApprovalCount(),
      );
      // Poll approval count every 15 seconds.
      _approvalPollTimer?.cancel();
      _approvalPollTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => ref.read(fieldControllerProvider.notifier)
            .fetchPendingApprovalCount(),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F10),
        border: Border(left: BorderSide(color: Color(0x1AF2EADF))),
        boxShadow: [
          BoxShadow(
            offset: Offset(-18, 0),
            blurRadius: 50,
            color: Color(0x38000000),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _KiHeader(
              focus: fieldState.fieldFocus,
              onFocus: ref.read(fieldControllerProvider.notifier).setFieldFocus,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _KiChatThread(
                messages: chatState.messages,
                streamingBuffer: chatState.streamingBuffer,
                isStreaming: chatState.isStreaming,
                isLoading: chatState.isLoading || allyState.isLoading,
                error: chatState.error ?? allyState.error,
                onRetry: allyState.error != null
                    ? () => ref.read(allyControllerProvider.notifier).retry()
                    : null,
              ),
            ),
            const _KiChips(),
            const SizedBox(height: 8),
            KiComposer(
              controller: _composer,
              onSend: _send,
              isStreaming: chatState.isStreaming,
            ),
          ],
        ),
      ),
    );
  }
}

/// CSS `.ki header` — flex row, align-items center, gap 12px.
class _KiHeader extends ConsumerWidget {
  const _KiHeader({required this.focus, required this.onFocus});

  final double focus;
  final ValueChanged<double> onFocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalCount = ref.watch(
      fieldControllerProvider.select((s) => s.pendingApprovalCount),
    );
    return Row(
      children: [
        // CSS `.ki header img` — 46×46, border-radius 50%, shadow
        EnamelIcon(kind: EnamelKind.ki, size: context.metrics.kiEnamelIcon),
        const SizedBox(width: 12), // CSS gap: 12px
        // CSS `.ki header strong` — Goudy 18px, weight 400
        Text(
          context.l10n.ki,
          style: const TextStyle(
            fontFamily: 'GoudyHeavyface',
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Color(0xFFF2EADF), // --cream
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Approval badge
              if (approvalCount > 0)
                Flexible(
                  child: _PulsingBadge(
                    count: approvalCount,
                    onTap: () {
                      ref.read(fieldControllerProvider.notifier).openApprovals();
                    },
                  ),
                ),
              if (approvalCount > 0) const SizedBox(width: 8),
              const Flexible(child: _AlliesButton(count: 2)),
              const SizedBox(width: 12),
              _FocusControl(focus: focus, onFocus: onFocus),
            ],
          ),
        ),
      ],
    );
  }
}

/// Animated pulsing notification badge for pending approvals.
class _PulsingBadge extends StatefulWidget {
  const _PulsingBadge({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Color(0xFFF59E0B).withValues(alpha: 0.15),
                border: Border.all(
                  color: Color(0xFFF59E0B).withValues(alpha: _glow.value),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFF59E0B).withValues(alpha: _glow.value * 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.notifications_active,
                    size: 12,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.count}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// CSS `.alliesButton` — outline pill, NOT filled. Border only, transparent bg.
/// Teal text + count badge.
class _AlliesButton extends StatelessWidget {
  const _AlliesButton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    // CSS: border 1px solid rgba(155,202,208,.28), background transparent,
    // border-radius pill, color #84bac7, font-size ~9px
    return GestureDetector(
      onTap: () {},
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Colors.transparent, // NOT filled
            border: Border.all(
              color: const Color(0x479BCAD0), // rgba(155,202,208,.28)
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  context.l10n.yourAllies,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF84BAC7),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: const TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF84BAC7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CSS `.focusControl` — label text on top, slider below. Column layout.
class _FocusControl extends StatelessWidget {
  const _FocusControl({required this.focus, required this.onFocus});

  final double focus;
  final ValueChanged<double> onFocus;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // "FIELD  100%" on row 1, "FOCUS" on row 2 — right aligned
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'FIELD',
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 6,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF918B82),
                      letterSpacing: 0.84,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${focus.round()}%',
                    style: const TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 6,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF03CCD9),
                    ),
                  ),
                ],
              ),
              const Text(
                'FOCUS',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 6,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF918B82),
                  letterSpacing: 0.84,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Slider below the label — full width of container
          SizedBox(
            height: 18,
            child: SliderTheme(
              data: const SliderThemeData(
                trackHeight: 3,
                activeTrackColor: Color(0xFF03CCD9),
                inactiveTrackColor: Color(0x2E03CCD9), // sky 18%
                thumbColor: Color(0xFF03CCD9),
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
              ),
              child: Slider(value: focus, max: 100, onChanged: onFocus),
            ),
          ),
        ],
      ),
    );
  }
}

/// The chat message thread — scrollable list of user/assistant messages.
class _KiChatThread extends StatelessWidget {
  const _KiChatThread({
    required this.messages,
    required this.streamingBuffer,
    required this.isStreaming,
    required this.isLoading,
    this.error,
    this.onRetry,
  });

  final List<ChatMessageModel> messages;
  final String streamingBuffer;
  final bool isStreaming;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty && !isLoading && !isStreaming && error == null) {
      const welcome = FieldFixtures.defaultKi;
      return const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(0, 24, 0, 12),
        child: _TopicContent(topic: welcome),
      );
    }

    if (isLoading && messages.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF03CCD9),
          ),
        ),
      );
    }

    // Build a flat list then feed to a reversed ListView so newest is at bottom.
    final items = <Widget>[];

    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      items.add(
        msg.role == ChatRole.user
            ? _UserBubble(text: msg.content)
            : _AssistantBubble(text: msg.content),
      );
    }

    if (isStreaming) {
      if (streamingBuffer.isNotEmpty) {
        items.add(_AssistantBubble(text: streamingBuffer, isStreaming: true));
      } else {
        items.add(const _TypingIndicator());
      }
    }

    if (error != null && !isStreaming) {
      // If error is about missing conversation history, show welcome instead.
      final isNoHistory = error!.contains('conversation') ||
          error!.contains('404') ||
          error!.contains('Not Found') ||
          error!.contains('Unable to load');
      if (isNoHistory && messages.isEmpty) {
        return const Center(child: _WelcomeBanner());
      } else {
        items.add(_ErrorBanner(error: error!, onRetry: onRetry));
      }
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

/// Three animated dots shown while waiting for the first token.
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 14),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0x4DDAB875), width: 2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              _Dot(delay: i * 200),
            ],
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.delay});

  final int delay;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacity = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _ctrl.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFF03CCD9),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Welcome banner shown when no conversation history exists.
class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 52,
              color: colors.sky.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 14),
            Text(
              'Start a new conversation',
              style: text.heading.copyWith(
                color: colors.cream,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ask Ki anything or use the suggestions below',
              style: text.caption.copyWith(
                color: colors.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error, this.onRetry});

  final String error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x14FF6B6B),
        border: Border.all(color: const Color(0x33FF6B6B)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                fontFamily: 'Avenir',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFFFF6B6B),
                height: 1.4,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRetry,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  context.l10n.retryMessage,
                  style: const TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF03CCD9),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// User message bubble — right-aligned with subtle border.
class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x12F2EADF),
          border: Border.all(color: const Color(0x29C19A6B)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(3),
            bottomLeft: Radius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Avenir',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFFE2D9CC),
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

/// CSS `.kiMessage` — left border accent + topic content.
class _TopicContent extends StatelessWidget {
  const _TopicContent({required this.topic});

  final KiTopic topic;

  @override
  Widget build(BuildContext context) {
    // CSS: left border is subtle teal — from the screenshots it's ~3px,
    // color approx rgba(3,204,217,0.35)
    return Container(
      padding: const EdgeInsets.only(left: 14),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Color(0x4DDAB875), // warm gold/amber ~30% alpha
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CSS `.kiMessage span` — topic title, gold, uppercase, letter-spacing
          if (topic.title.isNotEmpty)
            Text(
              topic.title.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Avenir',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFFEAAA00), // gold
                letterSpacing: 1.8,
              ),
            ),
          if (topic.title.isNotEmpty) const SizedBox(height: 10),

          // CSS `.kiMessage p` — font: 400 13px/1.58 "IBM Plex Sans",Avenir
          // NOT Goudy. This is the conversational body text.
          Text(
            topic.body,
            style: const TextStyle(
              fontFamily: 'Avenir', // IBM Plex Sans fallback to Avenir
              fontSize: 19,
              fontWeight: FontWeight.w400,
              color: Color(0xFFC3BBB0), // #c3bbb0
              height: 1.58,
            ),
          ),

          // CSS `.kiMessage strong` — invitation/guidance text
          if (topic.invitation.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              topic.invitation,
              style: const TextStyle(
                fontFamily: 'Avenir',
                fontSize: 12,
                fontWeight:
                    FontWeight.w400, // CSS strong is visual, weight stays 400
                color: Color(0xFFCBBCAC), // muted
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Assistant message bubble — left-border accent, left-aligned.
/// Renders Markdown (bold, lists, links, etc.) via [MarkdownBody].
class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.text, this.isStreaming = false});

  final String text;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final textColor = isStreaming
        ? const Color(0xFFD1C9BE)
        : const Color(0xFFC3BBB0);
    return Container(
      padding: const EdgeInsets.only(left: 14),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0x4DDAB875), width: 2)),
      ),
      child: MarkdownBody(
        data: text,
        selectable: true,
        onTapLink: (text, href, title) {
          if (href != null && href.isNotEmpty) {
            launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
          }
        },
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textColor,
            height: 1.55,
          ),
          strong: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textColor,
            height: 1.55,
          ),
          em: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
            color: textColor,
            height: 1.55,
          ),
          listBullet: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textColor,
            height: 1.55,
          ),
          code: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: Color(0xFF03CCD9),
            backgroundColor: Color(0x1403CCD9),
          ),
          codeblockDecoration: BoxDecoration(
            color: const Color(0x0FFFFFFF),
            borderRadius: BorderRadius.circular(6),
          ),
          blockSpacing: 12,
          listIndent: 20,
          a: const TextStyle(
            fontFamily: 'Avenir',
            fontSize: 14,
            color: Color(0xFF03CCD9),
            decoration: TextDecoration.underline,
            decorationColor: Color(0x8003CCD9),
          ),
        ),
      ),
    );
  }
}

/// CSS `.kiChits` — horizontal inline pill chips. flex-wrap, gap 7px.
class _KiChips extends ConsumerWidget {
  const _KiChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatController = ref.read(kiChatControllerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final chip in FieldFixtures.chips)
            _KiChipButton(
              label: chip.label,
              onPressed: () => chatController.sendMessage(chip.label),
            ),
        ],
      ),
    );
  }
}

/// CSS `.kiChits button` — inline pill, border, transparent bg, cream text.
class _KiChipButton extends StatefulWidget {
  const _KiChipButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_KiChipButton> createState() => _KiChipButtonState();
}

class _KiChipButtonState extends State<_KiChipButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // CSS: border 1px solid rgba(242,234,223,.18), bg transparent,
    // color #f2eadf (cream), border-radius pill, padding ~8px 14px
    // Hover: border sky, color sky
    final borderColor = _hovered
        ? const Color(0x6103CCD9) // sky ~38%
        : const Color(0x2EC19A6B); // camel/amber ~18%

    final textColor = _hovered
        ? const Color(0xFF03CCD9) // sky
        : const Color(0xFFF2EADF); // cream

    return GestureDetector(
      onTap: widget.onPressed,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0x0D03CCD9) // sky ~5%
                : Colors.transparent,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
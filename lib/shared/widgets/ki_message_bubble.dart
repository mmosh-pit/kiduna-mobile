import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/extensions/context_extensions.dart';
import '../../data/models/chat_message_model.dart';

class KiUserBubble extends StatelessWidget {
  const KiUserBubble({super.key, required this.message});

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.cream.withValues(alpha: 0.07),
          border: Border.all(color: colors.camel.withValues(alpha: 0.16)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(3),
            bottomLeft: Radius.circular(12),
          ),
        ),
        child: Text(
          message.content,
          style: context.kidunaText.body.copyWith(
            color: colors.cream.withValues(alpha: 0.88),
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class KiAssistantBubble extends StatelessWidget {
  const KiAssistantBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final textColor = colors.muted;

    return Container(
      padding: const EdgeInsets.only(left: 14),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: colors.gold.withValues(alpha: 0.3), width: 2),
        ),
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
          code: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: colors.sky,
            backgroundColor: colors.sky.withValues(alpha: 0.08),
          ),
          codeblockDecoration: BoxDecoration(
            color: const Color(0x0FFFFFFF),
            borderRadius: BorderRadius.circular(6),
          ),
          blockSpacing: 12,
          listIndent: 20,
          a: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 14,
            color: colors.sky,
            decoration: TextDecoration.underline,
            decorationColor: colors.sky.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class KiStreamingBubble extends StatelessWidget {
  const KiStreamingBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final textColor = const Color(0xFFD1C9BE);

    return Container(
      padding: const EdgeInsets.only(left: 14),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: colors.gold.withValues(alpha: 0.3), width: 2),
        ),
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
          code: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: colors.sky,
            backgroundColor: colors.sky.withValues(alpha: 0.08),
          ),
          codeblockDecoration: BoxDecoration(
            color: const Color(0x0FFFFFFF),
            borderRadius: BorderRadius.circular(6),
          ),
          blockSpacing: 12,
          listIndent: 20,
          a: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 14,
            color: colors.sky,
            decoration: TextDecoration.underline,
            decorationColor: colors.sky.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class KiTypingIndicator extends StatefulWidget {
  const KiTypingIndicator({super.key});

  @override
  State<KiTypingIndicator> createState() => _KiTypingIndicatorState();
}

class _KiTypingIndicatorState extends State<KiTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Container(
      padding: const EdgeInsets.only(left: 14),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: colors.gold.withValues(alpha: 0.3), width: 2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: FadeTransition(
          opacity: _opacity,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors.sky,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

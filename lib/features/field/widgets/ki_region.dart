import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/kiduna_motion.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/ki_topic.dart';
import '../controllers/field_controller.dart';
import '../data/field_fixtures.dart';
import 'enamel_icon.dart';
import 'ki_composer.dart';

/// The Ki region — the intelligence the Source converses with. Shows Ki's
/// current message, the Field-focus control, suggested prompts, and a composer.
class KiRegion extends ConsumerStatefulWidget {
  const KiRegion({super.key});

  @override
  ConsumerState<KiRegion> createState() => _KiRegionState();
}

class _KiRegionState extends ConsumerState<KiRegion> {
  final TextEditingController _composer = TextEditingController();

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  void _send() {
    ref.read(fieldControllerProvider.notifier).preserveMessage(_composer.text);
    _composer.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final state = ref.watch(fieldControllerProvider);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.26, -1.0),
          end: Alignment(0.26, 1.0),
          colors: [Color(0xFF100F0B), Color(0xFF100B08), Color(0xFF0B0806)],
          stops: [0.0, 0.57, 1.0],
        ),
        border: Border(
          left: BorderSide(color: colors.sky.withValues(alpha: 0.12)),
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.96),
            radius: 0.7,
            colors: [Color(0x1503CCD9), Color(0x00000000)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _KiHeader(
              focus: state.fieldFocus,
              onFocus: ref.read(fieldControllerProvider.notifier).setFieldFocus,
            ),
            Expanded(
              child: _KiThread(
                topic: state.kiTopic,
                preserved: state.preservedMessage,
              ),
            ),
            const _KiChips(),
            KiComposer(controller: _composer, onSend: _send),
          ],
        ),
      ),
    );
  }
}

class _KiHeader extends StatelessWidget {
  const _KiHeader({required this.focus, required this.onFocus});

  final double focus;
  final ValueChanged<double> onFocus;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 21),
      constraints: const BoxConstraints(minHeight: 104),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.camel.withValues(alpha: 0.14)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showAllies = constraints.maxWidth > 320;
          return Row(
            children: [
              EnamelIcon(
                kind: EnamelKind.ki,
                size: context.metrics.kiEnamelIcon,
              ),
              const SizedBox(width: 17),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        context.l10n.ki,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.display.copyWith(color: colors.cream),
                      ),
                    ),
                    if (showAllies) ...[
                      const SizedBox(width: 12),
                      const _AlliesButton(count: 2),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _FocusControl(focus: focus, onFocus: onFocus),
            ],
          );
        },
      ),
    );
  }
}

class _AlliesButton extends StatelessWidget {
  const _AlliesButton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        foregroundColor: colors.sky,
        backgroundColor: colors.sky.withValues(alpha: 0.045),
        side: BorderSide(color: colors.sky.withValues(alpha: 0.25)),
        shape: const StadiumBorder(),
        textStyle: text.micro.copyWith(fontWeight: FontWeight.w700),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.yourAllies),
          const SizedBox(width: 7),
          Container(
            constraints: const BoxConstraints(minWidth: 18),
            height: 18,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(10, 6, 4, 0.13),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: text.micro.copyWith(fontSize: 8, color: colors.sky),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusControl extends StatelessWidget {
  const _FocusControl({required this.focus, required this.onFocus});

  final double focus;
  final ValueChanged<double> onFocus;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return SizedBox(
      width: 82,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  context.l10n.fieldFocus.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: text.micro.copyWith(
                    color: colors.muted,
                    letterSpacing: 0.48,
                  ),
                ),
              ),
              Text(
                '${focus.round()}%',
                style: text.micro.copyWith(
                  color: colors.sky,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              activeTrackColor: colors.sky,
              thumbColor: colors.sky,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Semantics(
              label: context.l10n.fieldFocus,
              child: Slider(value: focus, max: 100, onChanged: onFocus),
            ),
          ),
        ],
      ),
    );
  }
}

class _KiThread extends StatelessWidget {
  const _KiThread({required this.topic, required this.preserved});

  final KiTopic topic;
  final String? preserved;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(21, 40, 21, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (preserved != null) _PreservedBubble(text: preserved!),
          AnimatedSwitcher(
            duration: reducedMotion
                ? Duration.zero
                : KidunaMotion.panelTransition,
            child: _TopicContent(key: ValueKey(topic), topic: topic),
          ),
        ],
      ),
    );
  }
}

class _PreservedBubble extends StatelessWidget {
  const _PreservedBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Container(
      margin: const EdgeInsets.only(left: 27, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: colors.cream.withValues(alpha: 0.035),
        border: Border.all(color: colors.camel.withValues(alpha: 0.16)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(7),
          topRight: Radius.circular(7),
          bottomRight: Radius.circular(7),
          bottomLeft: Radius.circular(2),
        ),
      ),
      child: Text(
        text,
        style: context.kidunaText.body.copyWith(
          color: colors.muted,
          height: 1.45,
        ),
      ),
    );
  }
}

class _TopicContent extends StatelessWidget {
  const _TopicContent({super.key, required this.topic});

  final KiTopic topic;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Container(
      padding: const EdgeInsets.only(left: 13),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: colors.sky.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (topic.title.isNotEmpty)
            Text(
              topic.title.toUpperCase(),
              style: text.eyebrow.copyWith(color: colors.gold),
            ),
          if (topic.title.isNotEmpty) const SizedBox(height: 10),
          Text(topic.body, style: text.bodyLarge.copyWith(color: colors.text)),
          if (topic.invitation.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              topic.invitation,
              style: text.caption.copyWith(color: colors.muted, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _KiChips extends ConsumerWidget {
  const _KiChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.kiduna;
    final controller = ref.read(fieldControllerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.fromLTRB(19, 0, 19, 12),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final chip in FieldFixtures.chips)
            OutlinedButton(
              onPressed: () => controller.askAbout(chip.topic),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 35),
                padding: const EdgeInsets.symmetric(horizontal: 11),
                shape: const StadiumBorder(),
                side: BorderSide(color: colors.camel.withValues(alpha: 0.22)),
                backgroundColor: colors.raised.withValues(alpha: 0.38),
              ),
              child: Text(
                chip.label,
                style: context.kidunaText.label.copyWith(color: colors.cream),
              ),
            ),
        ],
      ),
    );
  }
}

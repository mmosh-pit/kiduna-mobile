import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/ki_topic.dart';
import '../controllers/field_controller.dart';
import '../data/field_fixtures.dart';
import 'enamel_icon.dart';

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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.surface, colors.field],
        ),
        border: Border(
          left: BorderSide(color: colors.sky.withValues(alpha: 0.12)),
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
          _KiComposer(controller: _composer, onSend: _send),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.camel.withValues(alpha: 0.14)),
        ),
      ),
      child: Row(
        children: [
          EnamelIcon(kind: EnamelKind.ki, size: context.metrics.kiEnamelIcon),
          const SizedBox(width: 17),
          Expanded(
            child: Text(
              context.l10n.ki,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.display.copyWith(color: colors.cream),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 96,
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
                        overflow: TextOverflow.ellipsis,
                        style: text.micro.copyWith(color: colors.muted),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${focus.round()}%',
                      style: text.micro.copyWith(
                        color: colors.sky,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    activeTrackColor: colors.sky,
                    thumbColor: colors.sky,
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(value: focus, max: 100, onChanged: onFocus),
                ),
              ],
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
    final colors = context.kiduna;
    final text = context.kidunaText;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(21, 40, 21, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (preserved != null)
            Container(
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
                preserved!,
                style: text.bodySmall.copyWith(color: colors.muted),
              ),
            ),
          Container(
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
                Text(
                  topic.body,
                  style: text.bodyLarge.copyWith(color: colors.text),
                ),
                if (topic.invitation.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    topic.invitation,
                    style: text.caption.copyWith(color: colors.muted),
                  ),
                ],
              ],
            ),
          ),
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

class _KiComposer extends StatelessWidget {
  const _KiComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Padding(
      padding: const EdgeInsets.fromLTRB(19, 0, 19, 17),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.deep.withValues(alpha: 0.78),
          border: Border.all(color: colors.camel.withValues(alpha: 0.23)),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onSend(),
                style: context.kidunaText.body.copyWith(color: colors.text),
                decoration: InputDecoration(
                  hintText: '${context.l10n.messageKi}…',
                  hintStyle: context.kidunaText.body.copyWith(
                    color: colors.cream.withValues(alpha: 0.58),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {},
              tooltip: context.l10n.startVoiceInput,
              icon: Icon(Icons.mic_none, size: 18, color: colors.sky),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final enabled = value.text.trim().isNotEmpty;
                return IconButton(
                  onPressed: enabled ? onSend : null,
                  tooltip: context.l10n.sendToKi,
                  style: IconButton.styleFrom(
                    backgroundColor: enabled
                        ? colors.sky
                        : colors.sky.withValues(alpha: 0.09),
                    foregroundColor: colors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: const Text('↑'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

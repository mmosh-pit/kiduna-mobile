import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/kiduna_motion.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/ki_topic.dart';
import '../controllers/field_controller.dart';
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
    final state = ref.watch(fieldControllerProvider);

    // CSS .ki: background #0d0f10, border-left 1px solid rgba(242,234,223,.1),
    // box-shadow -18px 0 50px rgba(0,0,0,.22), padding 28px 24px 22px
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F10),
        border: Border(
          left: BorderSide(color: Color(0x1AF2EADF)), // rgba(242,234,223,.1)
        ),
        boxShadow: [
          BoxShadow(
            offset: Offset(-18, 0),
            blurRadius: 50,
            color: Color(0x38000000), // rgba(0,0,0,.22)
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _KiHeader(
              focus: state.fieldFocus,
              onFocus: ref.read(fieldControllerProvider.notifier).setFieldFocus,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _KiThread(
                topic: state.kiTopic,
                preserved: state.preservedMessage,
              ),
            ),
            const _KiChips(),
            const SizedBox(height: 8),
            KiComposer(controller: _composer, onSend: _send),
          ],
        ),
      ),
    );
  }
}

/// CSS `.ki header` — flex row, align-items center, gap 12px.
class _KiHeader extends StatelessWidget {
  const _KiHeader({required this.focus, required this.onFocus});

  final double focus;
  final ValueChanged<double> onFocus;

  @override
  Widget build(BuildContext context) {
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

/// CSS `.kiThread` — scrollable message area with left border accent.
class _KiThread extends StatelessWidget {
  const _KiThread({required this.topic, required this.preserved});

  final KiTopic topic;
  final String? preserved;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    // CSS: .kiMessage margin 12px 0 18px
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
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

/// CSS `blockquote` in .kiThread — user's preserved message.
class _PreservedBubble extends StatelessWidget {
  const _PreservedBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x09F2EADF), // cream ~3.5%
        border: Border.all(color: const Color(0x29C19A6B)), // camel 16%
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(7),
          topRight: Radius.circular(7),
          bottomRight: Radius.circular(2),
          bottomLeft: Radius.circular(7),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Avenir',
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Color(0xFFCBBCAC), // muted
          height: 1.45,
        ),
      ),
    );
  }
}

/// CSS `.kiMessage` — left border accent + topic content.
class _TopicContent extends StatelessWidget {
  const _TopicContent({super.key, required this.topic});

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

/// CSS `.kiChits` — horizontal inline pill chips. flex-wrap, gap 7px.
class _KiChips extends ConsumerWidget {
  const _KiChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(fieldControllerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final chip in FieldFixtures.chips)
            _KiChipButton(
              label: chip.label,
              onPressed: () => controller.askAbout(chip.topic),
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

import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/video_duration_request_model.dart';

class VideoDurationPicker extends StatefulWidget {
  const VideoDurationPicker({
    super.key,
    required this.request,
    required this.onGenerate,
  });

  final VideoDurationRequestModel request;
  final Future<void> Function(int seconds) onGenerate;

  @override
  State<VideoDurationPicker> createState() => _VideoDurationPickerState();
}

class _VideoDurationPickerState extends State<VideoDurationPicker> {
  late int _selectedSeconds;

  @override
  void initState() {
    super.initState();
    _selectedSeconds =
        widget.request.submittedSeconds ?? widget.request.initialSeconds;
  }

  @override
  void didUpdateWidget(covariant VideoDurationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final submittedSeconds = widget.request.submittedSeconds;
    if (submittedSeconds != null &&
        submittedSeconds != oldWidget.request.submittedSeconds) {
      _selectedSeconds = submittedSeconds;
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final divisions =
        (request.maxSeconds - request.minSeconds) ~/ request.stepSeconds;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.kiduna.surface,
          borderRadius: BorderRadius.circular(context.metrics.radiusPanel),
          border: Border.all(color: context.kiduna.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DurationHeading(
                seconds: _selectedSeconds,
                estimatedUsdcCost: request.estimatedUsdcCost(_selectedSeconds),
              ),
              const SizedBox(height: 12),
              SliderTheme(
                data: _sliderTheme(context),
                child: Slider(
                  value: _selectedSeconds.toDouble(),
                  min: request.minSeconds.toDouble(),
                  max: request.maxSeconds.toDouble(),
                  divisions: divisions,
                  label: context.l10n.secondsShort(_selectedSeconds),
                  onChanged: request.isSubmitted ? null : _changeDuration,
                ),
              ),
              _RangeLabels(request: request),
              const SizedBox(height: 16),
              _GenerateButton(
                seconds: _selectedSeconds,
                isSubmitted: request.isSubmitted,
                onPressed: () => widget.onGenerate(_selectedSeconds),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliderThemeData _sliderTheme(BuildContext context) {
    return SliderTheme.of(context).copyWith(
      activeTrackColor: context.kiduna.sky,
      inactiveTrackColor: context.kiduna.borderStrong,
      thumbColor: context.kiduna.sky,
      overlayColor: context.kiduna.skySoft,
      valueIndicatorColor: context.kiduna.raisedAlt,
      valueIndicatorTextStyle: context.kidunaText.labelStrong.copyWith(
        color: context.kiduna.cream,
      ),
    );
  }

  void _changeDuration(double value) {
    setState(() => _selectedSeconds = value.round());
  }
}

class _DurationHeading extends StatelessWidget {
  const _DurationHeading({
    required this.seconds,
    required this.estimatedUsdcCost,
  });

  final int seconds;
  final double? estimatedUsdcCost;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.howLongShouldVideoBe,
          style: context.kidunaText.h6.copyWith(color: context.kiduna.cream),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.secondsShort(seconds),
          style: context.kidunaText.h2.copyWith(color: context.kiduna.sky),
        ),
        if (estimatedUsdcCost case final cost?) ...[
          const SizedBox(height: 4),
          Text(
            context.l10n.approximateVideoCost(cost.toStringAsFixed(2)),
            style: context.kidunaText.labelStrong.copyWith(
              color: context.kiduna.cream,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          context.l10n.longerVideosTakeMoreTime,
          style: context.kidunaText.caption.copyWith(
            color: context.kiduna.muted,
          ),
        ),
      ],
    );
  }
}

class _RangeLabels extends StatelessWidget {
  const _RangeLabels({required this.request});

  final VideoDurationRequestModel request;

  @override
  Widget build(BuildContext context) {
    final style = context.kidunaText.label.copyWith(
      color: context.kiduna.quiet,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(context.l10n.secondsShort(request.minSeconds), style: style),
        Text(context.l10n.secondsShort(request.maxSeconds), style: style),
      ],
    );
  }
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({
    required this.seconds,
    required this.isSubmitted,
    required this.onPressed,
  });

  final int seconds;
  final bool isSubmitted;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isSubmitted
          ? null
          : () async {
              await onPressed();
            },
      icon: Icon(isSubmitted ? Icons.check : Icons.movie_creation_outlined),
      label: Text(
        isSubmitted
            ? context.l10n.generatingSecondsVideo(seconds)
            : context.l10n.generateSecondsVideo(seconds),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: context.kiduna.sky,
        foregroundColor: context.kiduna.skyButtonInk,
        disabledBackgroundColor: context.kiduna.skySoft,
        disabledForegroundColor: context.kiduna.muted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.metrics.radiusMd),
        ),
      ),
    );
  }
}

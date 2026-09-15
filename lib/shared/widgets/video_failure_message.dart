import 'package:flutter/widgets.dart';

import '../../core/extensions/context_extensions.dart';
import '../../data/models/video_job_model.dart';

/// Localize a stable backend failure code without displaying provider output.
String videoFailureMessage(BuildContext context, VideoFailureReason? reason) {
  return switch (reason) {
    VideoFailureReason.promptBlocked => context.l10n.videoPromptBlocked,
    VideoFailureReason.providerUnavailable =>
      context.l10n.videoProviderUnavailable,
    VideoFailureReason.providerTimeout => context.l10n.videoProviderTimedOut,
    VideoFailureReason.generationFailed ||
    null => context.l10n.videoGenerationFailed,
  };
}

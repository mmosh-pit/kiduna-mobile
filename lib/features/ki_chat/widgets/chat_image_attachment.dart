import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/image_job_model.dart';

class ChatImageAttachment extends StatelessWidget {
  const ChatImageAttachment({super.key, required this.image});

  final ImageJobModel image;

  @override
  Widget build(BuildContext context) {
    if (image.isReady) {
      return _ReadyImage(imageUrl: image.imageUrl!);
    }
    return switch (image.status) {
      ImageJobStatus.generating => const _GeneratingImage(),
      ImageJobStatus.ready ||
      ImageJobStatus.failed => _FailedImage(reason: image.failureReason),
    };
  }
}

class _GeneratingImage extends StatelessWidget {
  const _GeneratingImage();

  @override
  Widget build(BuildContext context) {
    return _Frame(
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.kiduna.gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.generatingYourImage,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.kiduna.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.imageGenerationMayTakeTime,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.kiduna.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FailedImage extends StatelessWidget {
  const _FailedImage({required this.reason});

  final ImageFailureReason? reason;

  @override
  Widget build(BuildContext context) {
    final message = switch (reason) {
      ImageFailureReason.providerUnavailable =>
        context.l10n.imageProviderUnavailable,
      ImageFailureReason.modelOutOfMemory => context.l10n.imageModelOutOfMemory,
      ImageFailureReason.providerTimeout => context.l10n.imageProviderTimedOut,
      ImageFailureReason.generationFailed ||
      null => context.l10n.imageGenerationFailed,
    };
    return _Frame(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: context.textStyles.bodyMedium?.copyWith(
          color: context.kiduna.muted,
        ),
      ),
    );
  }
}

class _ReadyImage extends StatelessWidget {
  const _ReadyImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.metrics.radiusLg),
        child: AspectRatio(
          aspectRatio: 1,
          child: InteractiveViewer(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _Frame(
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.kiduna.gold,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => _Frame(
                child: Center(
                  child: Text(
                    context.l10n.imageUnavailable,
                    textAlign: TextAlign.center,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.kiduna.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.kiduna.surface,
        borderRadius: BorderRadius.circular(context.metrics.radiusMd),
        border: Border.all(color: context.kiduna.line),
      ),
      child: child,
    );
  }
}

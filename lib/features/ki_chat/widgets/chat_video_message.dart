import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/video_job_model.dart';
import '../controllers/ki_chat_controller.dart';
import 'chat_video_attachment.dart';

/// Connects [ChatVideoAttachment] to the chat controller so its Publish
/// button can reach Theater.
class ChatVideoMessage extends ConsumerStatefulWidget {
  const ChatVideoMessage({super.key, required this.video});

  final VideoJobModel video;

  @override
  ConsumerState<ChatVideoMessage> createState() => _ChatVideoMessageState();
}

class _ChatVideoMessageState extends ConsumerState<ChatVideoMessage> {
  bool _isPublishing = false;

  Future<void> _publish() async {
    setState(() => _isPublishing = true);

    final error = await ref
        .read(kiChatControllerProvider.notifier)
        .publishVideo(widget.video.jobId);

    if (!mounted) return;
    setState(() => _isPublishing = false);

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChatVideoAttachment(
      video: widget.video,
      onPublish: _publish,
      isPublishing: _isPublishing,
    );
  }
}

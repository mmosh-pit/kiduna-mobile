import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/models/sse_event.dart';
import '../../../data/models/video_job_model.dart';
import '../../../data/services/chat_service.dart';
import '../../../data/services/theater_service.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../features/auth/enums/auth_status.dart';
import '../../../features/dashboard/controllers/ecosystem_controller.dart';
import '../../../features/field/controllers/field_controller.dart';
import 'ally_controller.dart';

@immutable
class KiChatState {
  const KiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isStreaming = false,
    this.streamingBuffer = '',
    this.error,
    this.historyLoaded = false,
    this.outOfBalance = false,
    this.videoBlockedReason,
  });

  final List<ChatMessageModel> messages;
  final bool isLoading;
  final bool isStreaming;
  final String streamingBuffer;
  final String? error;
  final bool historyLoaded;

  /// True when the backend rejected the last send for lack of KIDUNA.
  final bool outOfBalance;

  /// Why the last video request could not run (usually not enough KIDUNA).
  /// Separate from [outOfBalance] because a video costs orders of magnitude
  /// more than a chat turn — the user can still chat after this is set.
  final String? videoBlockedReason;

  KiChatState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    bool? isStreaming,
    String? streamingBuffer,
    String? error,
    bool? historyLoaded,
    bool? outOfBalance,
    String? videoBlockedReason,
    bool clearError = false,
    bool clearStreamingBuffer = false,
    bool clearVideoBlockedReason = false,
  }) {
    return KiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      streamingBuffer: clearStreamingBuffer
          ? ''
          : (streamingBuffer ?? this.streamingBuffer),
      error: clearError ? null : (error ?? this.error),
      historyLoaded: historyLoaded ?? this.historyLoaded,
      outOfBalance: outOfBalance ?? this.outOfBalance,
      videoBlockedReason: clearVideoBlockedReason
          ? null
          : (videoBlockedReason ?? this.videoBlockedReason),
    );
  }
}

class KiChatController extends Notifier<KiChatState> {
  StreamSubscription<SseEvent>? _subscription;

  /// Job currently being polled, so a second generation supersedes the first.
  String? _pendingVideoJobId;

  /// A generated video waiting for this turn's assistant message to exist.
  ///
  /// `toolResult` arrives mid-stream, BEFORE the reply is appended on `done`,
  /// so attaching immediately pinned the video to the PREVIOUS assistant
  /// message — far up the thread and effectively invisible.
  VideoJobModel? _awaitingAssistantMessage;

  /// Current game context (cards, board, pot). Set by game_screen when
  /// a game is active. Cleared when the game ends or player leaves.
  String _gameContext = '';

  /// Set the current game context (called by game_screen).
  void setGameContext(String context) => _gameContext = context;

  /// Clear the game context (called when game ends or player leaves).
  void clearGameContext() => _gameContext = '';

  /// Whether a game is currently active (has card context).
  bool get hasGameContext => _gameContext.isNotEmpty;

  @override
  KiChatState build() {
    ref.onDispose(() {
      _subscription?.cancel();
      _subscription = null;
    });

    // Watch auth state — when it flips to unauthenticated (logout or token
    // expiry), Riverpod auto-rebuilds this controller and returns a fresh
    // empty KiChatState.  This is the safety net for bug #46: even if the
    // logout path forgets to invalidate this provider, the auth-state change
    // itself triggers the reset and prevents cross-account chat leakage.
    final authStatus = ref.watch(
      authControllerProvider.select((s) => s.status),
    );
    if (authStatus == AuthStatus.unauthenticated) {
      _subscription?.cancel();
      _subscription = null;
      _gameContext = '';
      return const KiChatState();
    }

    return const KiChatState();
  }

  String? get _presenceId => ref.read(allyControllerProvider).ally?.id;
  String? get _userWallet => ref.read(authControllerProvider).user?.wallet;
  String? get _userId => ref.read(authControllerProvider).user?.id;
  String? get _realmId {
    // Prefer the specific realm the user has navigated into (Field).
    // Fall back to ecosystem ID when the user hasn't entered a sub-realm.
    final fieldRealmId = ref.read(fieldControllerProvider).currentRealmId;
    final ecosystemId = ref.read(ecosystemControllerProvider).ecosystem?.id;

    // fieldRealmId defaults to 'kinship-duna' (placeholder) when not navigated.
    // Use it only when it's an actual realm ID (UUID format).
    final useField =
        fieldRealmId.isNotEmpty &&
        fieldRealmId != 'kinship-duna' &&
        fieldRealmId != ecosystemId;

    final id = useField ? fieldRealmId : ecosystemId;
    print(
      '[DashboardKiChat] _realmId = $id (field=$fieldRealmId, eco=$ecosystemId)',
    );
    return id;
  }

  Future<void> loadHistory() async {
    final presenceId = _presenceId;
    final userWallet = _userWallet;
    if (presenceId == null || userWallet == null) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final messages = await ChatService.instance.fetchHistory(
        presenceId: presenceId,
        userWallet: userWallet,
      );
      if (!ref.mounted) return;
      final withVideos = await _restoreVideoAttachments(messages);
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        messages: withVideos,
        historyLoaded: true,
      );
      AppLogger.info(
        'History loaded: ${messages.length} messages',
        tag: 'KiChat',
      );
    } on UnauthorizedException {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Session expired. Please log in again.',
      );
    } on NetworkException {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        messages: const [],
        historyLoaded: true,
      );
    } on AppException catch (e) {
      if (!ref.mounted) return;
      AppLogger.error('History load failed', tag: 'KiChat', error: e);
      state = state.copyWith(
        isLoading: false,
        messages: const [],
        historyLoaded: true,
      );
    }
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final presenceId = _presenceId;
    final userWallet = _userWallet;

    AppLogger.debug(
      'sendMessage: presenceId=$presenceId, '
      'userWallet=${userWallet != null ? 'ok' : 'null'}',
      tag: 'KiChat',
    );

    if (presenceId == null || userWallet == null) {
      AppLogger.warning(
        'sendMessage aborted: presenceId=${presenceId == null ? 'null' : 'ok'}, '
        'userWallet=${userWallet == null ? 'null' : 'ok'}',
        tag: 'KiChat',
      );
      state = state.copyWith(error: 'Not connected. Please try again.');
      return;
    }

    await _subscription?.cancel();
    _subscription = null;

    // Prepend game context if a game is active (so Ki knows the cards).
    final messageForApi = _gameContext.isNotEmpty
        ? '[Game context: $_gameContext] $trimmed'
        : trimmed;

    final userMessage = ChatMessageModel(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      role: ChatRole.user,
      content: trimmed,
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isStreaming: true,
      clearError: true,
      clearStreamingBuffer: true,
    );

    try {
      final stream = ChatService.instance.streamChat(
        presenceId: presenceId,
        message: messageForApi,
        userWallet: userWallet,
        userId: _userId,
        realmId: _realmId,
      );

      _subscription = stream.listen(
        (event) {
          if (!ref.mounted) return;
          switch (event) {
            case SseTokenEvent(:final token):
              state = state.copyWith(
                streamingBuffer: state.streamingBuffer + token,
              );
            case SseDoneEvent(:final fullResponse):
              final assistantMessage = ChatMessageModel(
                id: 'resp_${DateTime.now().millisecondsSinceEpoch}',
                role: ChatRole.assistant,
                content: fullResponse,
                video: _awaitingAssistantMessage,
              );
              _awaitingAssistantMessage = null;
              state = state.copyWith(
                messages: [...state.messages, assistantMessage],
                isStreaming: false,
                clearStreamingBuffer: true,
              );
              _subscription = null;
            case SseErrorEvent(:final error, :final code):
              AppLogger.error('SSE error: $code — $error', tag: 'KiChat');
              state = state.copyWith(
                isStreaming: false,
                error: 'SSE error ($code): $error',
                clearStreamingBuffer: true,
              );
              _subscription = null;
            case SseToolResultEvent(:final toolName, :final output):
              if (toolName == 'generate_video') {
                _handleVideoToolResult(output);
              }
            case SseInfoEvent():
              break;
          }
        },
        onError: (Object e, StackTrace st) {
          if (!ref.mounted) return;
          AppLogger.error(
            'Stream error [${e.runtimeType}]: $e',
            tag: 'KiChat',
            error: e,
            stackTrace: st,
          );
          if (e is InsufficientBalanceException) {
            _handleOutOfBalance(e, userMessage);
            return;
          }
          state = state.copyWith(
            isStreaming: false,
            error: 'Stream error: [${e.runtimeType}] $e',
            clearStreamingBuffer: true,
          );
          _subscription = null;
        },
        onDone: () {
          if (!ref.mounted) return;
          if (state.isStreaming && state.streamingBuffer.isNotEmpty) {
            final assistantMessage = ChatMessageModel(
              id: 'resp_${DateTime.now().millisecondsSinceEpoch}',
              role: ChatRole.assistant,
              content: state.streamingBuffer,
              video: _awaitingAssistantMessage,
            );
            _awaitingAssistantMessage = null;
            state = state.copyWith(
              messages: [...state.messages, assistantMessage],
              isStreaming: false,
              clearStreamingBuffer: true,
            );
          } else if (state.isStreaming) {
            state = state.copyWith(isStreaming: false);
          }
          _subscription = null;
        },
        cancelOnError: true,
      );
    } on InsufficientBalanceException catch (e) {
      if (!ref.mounted) return;
      _handleOutOfBalance(e, userMessage);
    } catch (e, st) {
      if (!ref.mounted) return;
      AppLogger.error(
        'Send failed [${e.runtimeType}]: $e',
        tag: 'KiChat',
        error: e,
        stackTrace: st,
      );
      state = state.copyWith(
        isStreaming: false,
        error: 'Send error: [${e.runtimeType}] $e',
      );
    }
  }

  /// The backend refused the send because the wallet is out of KIDUNA.
  /// Drops the optimistic user bubble — Ki never saw the message — and flags
  /// the state so the composer can offer a top-up.
  void _handleOutOfBalance(
    InsufficientBalanceException e,
    ChatMessageModel userMessage,
  ) {
    AppLogger.info('Chat blocked: out of KIDUNA', tag: 'KiChat');
    _subscription = null;
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != userMessage.id).toList(),
      isStreaming: false,
      outOfBalance: true,
      error: e.message ?? 'You have no KIDUNA left.',
      clearStreamingBuffer: true,
    );
  }

  /// Called after a successful top-up so the composer unlocks.
  void clearOutOfBalance() {
    state = state.copyWith(outOfBalance: false, clearError: true);
  }

  /// Put previously generated videos back onto reloaded chat history.
  ///
  /// The backend's conversation history has no attachment field, so a reload
  /// would otherwise lose every clip. Jobs are matched to the assistant
  /// message closest in time to when generation started — the tool runs inside
  /// that turn, so the nearest reply is the one that asked for it.
  Future<List<ChatMessageModel>> _restoreVideoAttachments(
    List<ChatMessageModel> messages,
  ) async {
    final wallet = _userWallet;
    if (wallet == null || wallet.isEmpty || messages.isEmpty) return messages;

    final List<VideoJobModel> jobs;
    try {
      jobs = await TheaterService.instance.fetchMyJobs(wallet: wallet);
    } on AppException catch (e) {
      // History is still useful without the clips — don't fail the load.
      AppLogger.warning(
        'Could not restore video attachments: ${e.message}',
        tag: 'KiChat',
      );
      return messages;
    }
    if (jobs.isEmpty) return messages;

    final restored = [...messages];
    final claimed = <int>{};

    for (final job in jobs) {
      final jobTime = job.createdAt;
      if (jobTime == null) continue;

      var bestIndex = -1;
      Duration? bestGap;
      for (var i = 0; i < restored.length; i++) {
        if (claimed.contains(i)) continue;
        final message = restored[i];
        if (message.role != ChatRole.assistant) continue;
        final stamp = DateTime.tryParse(message.timestamp ?? '');
        if (stamp == null) continue;
        final gap = stamp.difference(jobTime).abs();
        if (gap > const Duration(minutes: 10)) continue;
        if (bestGap == null || gap < bestGap) {
          bestGap = gap;
          bestIndex = i;
        }
      }

      if (bestIndex == -1) continue;
      claimed.add(bestIndex);
      restored[bestIndex] = restored[bestIndex].copyWith(video: job);
    }

    return restored;
  }

  /// Decode a tool's JSON return value from a `toolResult` payload.
  ///
  /// The backend sends the tool's raw output, but has historically wrapped it
  /// in a stringified ToolMessage — `content='{...}' name='x' tool_call_id='y'`
  /// — so a bare jsonDecode fails. This falls back to lifting the first
  /// balanced JSON object out of the string rather than dropping the event.
  @visibleForTesting
  static Map<String, dynamic>? decodeToolPayload(String output) =>
      _decodeToolPayload(output);

  static Map<String, dynamic>? _decodeToolPayload(String output) {
    final trimmed = output.trim();
    if (trimmed.isEmpty) return null;

    try {
      final direct = jsonDecode(trimmed);
      if (direct is Map<String, dynamic>) return direct;
    } on FormatException {
      // Fall through to the embedded-object scan below.
    }

    final start = trimmed.indexOf('{');
    if (start == -1) return null;

    // Walk to the matching brace so trailing repr fields are excluded.
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var i = start; i < trimmed.length; i++) {
      final char = trimmed[i];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (char == r'\') {
        escaped = true;
        continue;
      }
      if (char == '"') {
        inString = !inString;
        continue;
      }
      if (inString) continue;
      if (char == '{') depth++;
      if (char == '}') {
        depth--;
        if (depth == 0) {
          try {
            final decoded = jsonDecode(trimmed.substring(start, i + 1));
            if (decoded is Map<String, dynamic>) return decoded;
          } on FormatException {
            return null;
          }
          return null;
        }
      }
    }
    return null;
  }

  /// Ki called `generate_video`. The tool returns a job id, not a video —
  /// rendering happens in the background, so attach a placeholder and poll.
  void _handleVideoToolResult(String output) {
    final parsed = _decodeToolPayload(output);
    if (parsed == null) {
      AppLogger.warning(
        'Unparseable generate_video output (len ${output.length})',
        tag: 'KiChat',
      );
      return;
    }

    if (parsed['success'] != true) {
      final reason = parsed['message'] as String?;
      AppLogger.info(
        'Video generation refused: ${parsed['error']}',
        tag: 'KiChat',
      );
      state = state.copyWith(
        videoBlockedReason: reason ?? 'Ki could not make that video.',
      );
      return;
    }

    final job = VideoJobModel.fromToolOutput(parsed);
    if (job.jobId.isEmpty) return;

    _pendingVideoJobId = job.jobId;
    _awaitingAssistantMessage = job;
    state = state.copyWith(clearVideoBlockedReason: true);
    unawaited(_pollVideoJob(job));
  }

  /// Poll one job until it finishes, updating the message bubble in place.
  ///
  /// Veo can take minutes, so this deliberately outlives the SSE stream that
  /// started it. The message may not exist yet when the tool result arrives
  /// (the assistant's reply lands on `done`), so the placeholder is attached
  /// to the newest assistant message each tick.
  Future<void> _pollVideoJob(VideoJobModel initial) async {
    var job = initial;

    const pollInterval = Duration(seconds: 5);
    const maxAttempts = 96; // ~8 minutes, past Veo's worst case

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      await Future<void>.delayed(pollInterval);
      if (!ref.mounted) return;

      final wallet = _userWallet;
      if (wallet == null || wallet.isEmpty) return;

      try {
        job = await TheaterService.instance.fetchJob(
          jobId: job.jobId,
          wallet: wallet,
        );
      } on AppException catch (e) {
        AppLogger.warning('Video job poll failed: ${e.message}', tag: 'KiChat');
        continue;
      }

      if (!ref.mounted) return;
      _attachVideoToLatestAssistantMessage(job);

      if (job.status.isTerminal) {
        if (_pendingVideoJobId == job.jobId) _pendingVideoJobId = null;
        return;
      }
    }

    AppLogger.warning('Gave up polling video job ${job.jobId}', tag: 'KiChat');
  }

  /// Put [job] on the newest assistant message, replacing any earlier state
  /// for the same job.
  void _attachVideoToLatestAssistantMessage(VideoJobModel job) {
    final messages = [...state.messages];

    final existing = messages.lastIndexWhere(
      (m) => m.video?.jobId == job.jobId,
    );
    if (existing != -1) {
      // Already placed, so stop holding it for the next reply — otherwise a
      // later turn would receive a second copy of the same video.
      if (_awaitingAssistantMessage?.jobId == job.jobId) {
        _awaitingAssistantMessage = null;
      }
      // Keep isPublished — it's local and the server doesn't echo it back.
      final wasPublished = messages[existing].video?.isPublished ?? false;
      messages[existing] = messages[existing].copyWith(
        video: job.copyWith(isPublished: wasPublished),
      );
      state = state.copyWith(messages: messages);
      return;
    }

    // This turn's reply hasn't landed yet — keep the job parked so the `done`
    // handler attaches it, rather than pinning it to an earlier message.
    _awaitingAssistantMessage = job;
  }

  /// Publish a generated video to the Theater feed.
  ///
  /// Returns null on success, or a message to show the user when the publish
  /// was refused (most often by moderation).
  Future<String?> publishVideo(String jobId) async {
    final wallet = _userWallet;
    if (wallet == null || wallet.isEmpty) {
      return 'You need to be signed in to publish.';
    }

    try {
      await TheaterService.instance.publish(jobId: jobId, wallet: wallet);
    } on ValidationException catch (e) {
      return e.message ?? 'This video can\'t be published to Theater.';
    } on AppException catch (e) {
      AppLogger.error('Publish failed', tag: 'KiChat', error: e);
      return e.message ?? 'Unable to publish. Please try again.';
    }

    if (!ref.mounted) return null;

    final messages = [...state.messages];
    final index = messages.lastIndexWhere((m) => m.video?.jobId == jobId);
    if (index != -1) {
      messages[index] = messages[index].copyWith(
        video: messages[index].video!.copyWith(isPublished: true),
      );
      state = state.copyWith(messages: messages);
    }
    return null;
  }

  void clearVideoBlockedReason() {
    state = state.copyWith(clearVideoBlockedReason: true);
  }

  void cancelStream() {
    _subscription?.cancel();
    _subscription = null;
    if (state.isStreaming) {
      if (state.streamingBuffer.isNotEmpty) {
        final partialMessage = ChatMessageModel(
          id: 'resp_${DateTime.now().millisecondsSinceEpoch}',
          role: ChatRole.assistant,
          content: state.streamingBuffer,
        );
        state = state.copyWith(
          messages: [...state.messages, partialMessage],
          isStreaming: false,
          clearStreamingBuffer: true,
        );
      } else {
        state = state.copyWith(isStreaming: false);
      }
    }
  }

  /// Add a local game tip to the chat — no API call, instant display.
  void addLocalTip(String tip) {
    if (tip.trim().isEmpty) return;
    final tipMessage = ChatMessageModel(
      id: 'tip_${DateTime.now().millisecondsSinceEpoch}',
      role: ChatRole.assistant,
      content: tip,
    );
    state = state.copyWith(messages: [...state.messages, tipMessage]);
  }

  /// Remove all local game tips from chat. Keeps typed messages (API).
  void clearLocalTips() {
    final kept = state.messages.where((m) => !m.id.startsWith('tip_')).toList();
    state = state.copyWith(messages: kept);
  }
}

final kiChatControllerProvider =
    NotifierProvider<KiChatController, KiChatState>(KiChatController.new);

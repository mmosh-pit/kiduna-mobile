import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/models/sse_event.dart';
import '../../../data/services/chat_service.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../features/dashboard/controllers/ecosystem_controller.dart';
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
  });

  final List<ChatMessageModel> messages;
  final bool isLoading;
  final bool isStreaming;
  final String streamingBuffer;
  final String? error;
  final bool historyLoaded;

  /// True when the backend rejected the last send for lack of KIDUNA.
  final bool outOfBalance;

  KiChatState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    bool? isStreaming,
    String? streamingBuffer,
    String? error,
    bool? historyLoaded,
    bool? outOfBalance,
    bool clearError = false,
    bool clearStreamingBuffer = false,
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
    );
  }
}

class KiChatController extends Notifier<KiChatState> {
  StreamSubscription<SseEvent>? _subscription;

  @override
  KiChatState build() {
    ref.onDispose(() {
      _subscription?.cancel();
      _subscription = null;
    });
    return const KiChatState();
  }

  String? get _presenceId => ref.read(allyControllerProvider).ally?.id;
  String? get _userWallet => ref.read(authControllerProvider).user?.wallet;
  String? get _userId => ref.read(authControllerProvider).user?.id;
  String? get _realmId => ref.read(ecosystemControllerProvider).ecosystem?.id;

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
      state = state.copyWith(
        isLoading: false,
        messages: messages,
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
        error: 'Unable to load conversation history.',
        historyLoaded: true,
      );
    } on AppException catch (e) {
      if (!ref.mounted) return;
      AppLogger.error('History load failed', tag: 'KiChat', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load conversation history.',
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
        message: trimmed,
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
              );
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
            );
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
}

final kiChatControllerProvider =
    NotifierProvider<KiChatController, KiChatState>(KiChatController.new);
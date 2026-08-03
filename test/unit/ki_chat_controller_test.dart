import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/data/models/chat_message_model.dart';
import 'package:kiduna_mobile/features/field/controllers/ki_chat_controller.dart';

void main() {
  test('initial KiChatState has empty messages and no error', () {
    const state = KiChatState();
    expect(state.messages, isEmpty);
    expect(state.isLoading, isFalse);
    expect(state.isStreaming, isFalse);
    expect(state.streamingBuffer, '');
    expect(state.error, isNull);
    expect(state.historyLoaded, isFalse);
  });

  test('copyWith preserves existing error when clearError is false', () {
    const state = KiChatState(error: 'failed');
    final next = state.copyWith(isLoading: true);
    expect(next.error, 'failed');
    expect(next.isLoading, isTrue);
  });

  test('copyWith clears error when clearError is true', () {
    const state = KiChatState(error: 'failed');
    final next = state.copyWith(isLoading: true, clearError: true);
    expect(next.error, isNull);
  });

  test(
    'copyWith preserves streamingBuffer when clearStreamingBuffer is false',
    () {
      const state = KiChatState(streamingBuffer: 'Hello');
      final next = state.copyWith(isStreaming: true);
      expect(next.streamingBuffer, 'Hello');
    },
  );

  test('copyWith clears streamingBuffer when clearStreamingBuffer is true', () {
    const state = KiChatState(streamingBuffer: 'Hello');
    final next = state.copyWith(clearStreamingBuffer: true);
    expect(next.streamingBuffer, '');
  });

  test('copyWith updates messages', () {
    const state = KiChatState();
    final messages = [
      const ChatMessageModel(
        id: 'msg_1',
        role: ChatRole.user,
        content: 'Hello',
      ),
    ];
    final next = state.copyWith(messages: messages);
    expect(next.messages, hasLength(1));
    expect(next.messages[0].content, 'Hello');
  });

  test('loading state pattern: loading with clearError', () {
    const state = KiChatState(error: 'old');
    final loading = state.copyWith(isLoading: true, clearError: true);
    expect(loading.isLoading, isTrue);
    expect(loading.error, isNull);
  });

  test('streaming state pattern: streaming with buffer accumulation', () {
    const state = KiChatState(isStreaming: true);
    final withToken = state.copyWith(streamingBuffer: 'Hello');
    expect(withToken.streamingBuffer, 'Hello');
    expect(withToken.isStreaming, isTrue);

    final moreTokens = withToken.copyWith(streamingBuffer: 'Hello world');
    expect(moreTokens.streamingBuffer, 'Hello world');
  });

  test('done state pattern: streaming off, buffer cleared, message added', () {
    const streaming = KiChatState(
      isStreaming: true,
      streamingBuffer: 'Hello world',
      messages: [
        ChatMessageModel(id: 'msg_1', role: ChatRole.user, content: 'Hi'),
      ],
    );

    final done = streaming.copyWith(
      messages: [
        ...streaming.messages,
        const ChatMessageModel(
          id: 'resp_1',
          role: ChatRole.assistant,
          content: 'Hello world',
        ),
      ],
      isStreaming: false,
      clearStreamingBuffer: true,
    );

    expect(done.isStreaming, isFalse);
    expect(done.streamingBuffer, '');
    expect(done.messages, hasLength(2));
    expect(done.messages[1].role, ChatRole.assistant);
    expect(done.messages[1].content, 'Hello world');
  });

  test('error state pattern: streaming off with error', () {
    const streaming = KiChatState(isStreaming: true, streamingBuffer: 'part');
    final errored = streaming.copyWith(
      isStreaming: false,
      error: 'Unable to get a response. Please try again.',
      clearStreamingBuffer: true,
    );
    expect(errored.isStreaming, isFalse);
    expect(errored.streamingBuffer, '');
    expect(errored.error, contains('Unable to get a response'));
  });

  test('historyLoaded flag persists through other updates', () {
    const state = KiChatState(historyLoaded: true);
    final next = state.copyWith(isLoading: false);
    expect(next.historyLoaded, isTrue);
  });

  test('optimistic send pattern: user message added immediately', () {
    const state = KiChatState();
    const userMsg = ChatMessageModel(
      id: 'local_1',
      role: ChatRole.user,
      content: 'What should I do?',
    );

    final sent = state.copyWith(
      messages: [...state.messages, userMsg],
      isStreaming: true,
      clearError: true,
      clearStreamingBuffer: true,
    );

    expect(sent.messages, hasLength(1));
    expect(sent.messages[0].role, ChatRole.user);
    expect(sent.messages[0].content, 'What should I do?');
    expect(sent.isStreaming, isTrue);
    expect(sent.error, isNull);
    expect(sent.streamingBuffer, '');
  });
}

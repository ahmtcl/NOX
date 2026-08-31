import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nox/features/chat/application/chat_controller.dart';
import 'package:nox/features/chat/domain/chat_message.dart';
import 'package:nox/features/chat/domain/chat_repository.dart';
import 'package:nox/features/chat/domain/conversation.dart';

void main() {
  const session = ChatSession(
    userAUid: 'a',
    userBUid: 'b',
    currentUserUid: 'a',
  );
  const conversation = Conversation(userAUid: 'a', userBUid: 'b', matchId: 'a_b');

  late _MockChatRepository repository;
  late StreamController<List<ChatMessage>> messages;
  late ProviderContainer container;

  ChatMessage message(String id, {DateTime? createdAt}) => ChatMessage(
        messageId: id,
        conversationId: 'a_b',
        senderUid: 'a',
        text: id,
        createdAt: createdAt,
      );

  setUp(() {
    repository = _MockChatRepository();
    messages = StreamController<List<ChatMessage>>.broadcast();
    container = ProviderContainer(overrides: [
      chatRepositoryProvider.overrideWithValue(repository),
    ]);
    when(() => repository.getConversationForMatch('a', 'b'))
        .thenAnswer((_) async => conversation);
    when(() => repository.getMessages('a_b', currentUserUid: 'a'))
        .thenAnswer((_) async => const ChatMessagePage(messages: []));
    when(() => repository.watchMessages('a_b', 'a'))
        .thenAnswer((_) => messages.stream);
    when(() => repository.sendMessage('a_b', 'a', any()))
        .thenAnswer((_) async => message('sent'));
  });

  tearDown(() async {
    container.dispose();
    await messages.close();
  });

  test('loads the initial conversation and message page', () async {
    final initial = message('initial', createdAt: DateTime(2026, 1, 2));
    when(() => repository.getMessages('a_b', currentUserUid: 'a'))
        .thenAnswer((_) async => ChatMessagePage(messages: [initial]));

    await _waitFor(container, (state) => !state.isLoading);
    final state = _state(container);

    expect(state.conversation, conversation);
    expect(state.messages, [initial]);
    expect(state.error, isNull);
  });

  test('adds realtime messages once and orders equal or null timestamps by id',
      () async {
    await _waitFor(container, (state) => !state.isLoading);
    final sameTime = DateTime(2026, 1, 2);
    final newer = message('newer', createdAt: DateTime(2026, 1, 3));
    final beta = message('beta', createdAt: sameTime);
    final alpha = message('alpha', createdAt: sameTime);
    final noTime = message('none');

    messages.add([beta, noTime, newer, alpha]);
    await _waitFor(container, (state) => state.messages.length == 4);
    messages.add([beta]);
    await _waitFor(container, (state) => state.messages.length == 4);

    expect(_state(container).messages.map((item) => item.messageId),
        ['newer', 'alpha', 'beta', 'none']);
  });

  test('loadMore merges older messages without losing the current page', () async {
    final newest = message('newest', createdAt: DateTime(2026, 1, 3));
    final older = message('older', createdAt: DateTime(2026, 1, 2));
    final cursor = Object();
    when(() => repository.getMessages('a_b', currentUserUid: 'a'))
        .thenAnswer((_) async => ChatMessagePage(messages: [newest], cursor: cursor));
    when(() => repository.getMessages('a_b',
        currentUserUid: 'a', cursor: cursor)).thenAnswer(
      (_) async => ChatMessagePage(messages: [older]),
    );

    await _waitFor(container, (state) => !state.isLoading);
    await container.read(chatControllerProvider(session).notifier).loadMore();

    expect(_state(container).messages, [newest, older]);
    expect(_state(container).hasMore, isFalse);
  });

  test('sets isSending while sending and clears it after success', () async {
    final send = Completer<ChatMessage>();
    when(() => repository.sendMessage('a_b', 'a', 'hello'))
        .thenAnswer((_) => send.future);
    await _waitFor(container, (state) => !state.isLoading);

    final sending = container.read(chatControllerProvider(session).notifier).sendMessage('hello');
    expect(_state(container).isSending, isTrue);
    send.complete(message('sent'));
    await sending;

    expect(_state(container).isSending, isFalse);
    expect(_state(container).error, isNull);
  });

  test('clears isSending and exposes a send failure', () async {
    final failure = StateError('send failed');
    when(() => repository.sendMessage('a_b', 'a', 'hello'))
        .thenThrow(failure);
    await _waitFor(container, (state) => !state.isLoading);

    await container.read(chatControllerProvider(session).notifier).sendMessage('hello');

    expect(_state(container).isSending, isFalse);
    expect(_state(container).error, same(failure));
  });

  test('cancels the realtime stream subscription when disposed', () async {
    var cancelled = false;
    messages.onCancel = () => cancelled = true;
    await _waitFor(container, (state) => !state.isLoading);

    container.dispose();
    await _waitUntil(() => cancelled);
  });
}

ChatState _state(ProviderContainer container) =>
    container.read(chatControllerProvider(const ChatSession(
      userAUid: 'a',
      userBUid: 'b',
      currentUserUid: 'a',
    )));

Future<void> _waitFor(
  ProviderContainer container,
  bool Function(ChatState state) matches,
) => _waitUntil(() => matches(_state(container)));

Future<void> _waitUntil(bool Function() matches) async {
  for (var i = 0; i < 50; i++) {
    if (matches()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('condition was not met');
}

class _MockChatRepository extends Mock implements ChatRepository {}

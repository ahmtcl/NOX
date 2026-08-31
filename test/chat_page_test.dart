import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nox/app.dart';
import 'package:nox/core/routing/app_router.dart';
import 'package:nox/features/auth/application/auth_controller.dart';
import 'package:nox/features/auth/domain/auth_user.dart';
import 'package:nox/features/chat/application/chat_controller.dart';
import 'package:nox/features/chat/domain/chat_message.dart';
import 'package:nox/features/chat/domain/chat_repository.dart';
import 'package:nox/features/chat/domain/conversation.dart';
import 'package:nox/features/chat/presentation/chat_page.dart';
import 'package:nox/features/profile/application/profile_completion_provider.dart';

void main() {
  const session = ChatSession(
    userAUid: 'a',
    userBUid: 'b',
    currentUserUid: 'a',
  );
  const args = ChatRouteArgs(session: session, otherUserName: 'Deniz');

  testWidgets('chat route opens for an authenticated user', (tester) async {
    final repository = _FakeChatRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_AuthenticatedAuth.new),
        profileCompletionProvider.overrideWith((_) async => true),
        chatRepositoryProvider.overrideWithValue(repository),
      ],
      child: const NoxApp(),
    ));

    final container =
        ProviderScope.containerOf(tester.element(find.byType(NoxApp)));
    container.read(appRouterProvider).go('/chat', extra: args);
    await tester.pumpAndSettle();

    expect(find.text('Deniz'), findsOneWidget);
  });

  testWidgets('shows loading while the initial conversation is loading',
      (tester) async {
    final repository = _FakeChatRepository(conversationCompleter: Completer());
    await tester.pumpWidget(_pageApp(repository));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.conversationCompleter!.complete(_conversation);
  });

  testWidgets('renders loaded own and other messages', (tester) async {
    final repository = _FakeChatRepository(messages: [
      _message('mine', 'a'),
      _message('theirs', 'b'),
    ]);
    await tester.pumpWidget(_pageApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('mine'), findsOneWidget);
    expect(find.text('theirs'), findsOneWidget);
    expect(find.bySemanticsLabel('Benim mesajım'), findsOneWidget);
    expect(find.bySemanticsLabel('Karşı tarafın mesajı'), findsOneWidget);
  });

  testWidgets('sends trimmed composer text and clears the input',
      (tester) async {
    final repository = _FakeChatRepository();
    await tester.pumpWidget(_pageApp(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), ' hello ');
    await tester.tap(find.byKey(const ValueKey('send-message')));
    await tester.pumpAndSettle();

    expect(repository.sentTexts, ['hello']);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
  });

  testWidgets('does not send empty composer text', (tester) async {
    final repository = _FakeChatRepository();
    await tester.pumpWidget(_pageApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('send-message')));
    await tester.pump();

    expect(repository.sentTexts, isEmpty);
  });

  testWidgets('shows an error and retries the controller load', (tester) async {
    final repository = _FakeChatRepository(failLoad: true);
    await tester.pumpWidget(_pageApp(repository));
    await tester.pumpAndSettle();
    expect(find.text('Tekrar dene'), findsOneWidget);

    repository.failLoad = false;
    await tester.tap(find.text('Tekrar dene'));
    await tester.pumpAndSettle();

    expect(find.text('Henüz mesaj yok.'), findsOneWidget);
    expect(repository.conversationCalls, 2);
  });

  testWidgets('loads older messages from the explicit action', (tester) async {
    final repository = _FakeChatRepository(
      messages: [_message('newer', 'a')],
      firstCursor: Object(),
      olderMessages: [_message('older', 'b')],
    );
    await tester.pumpWidget(_pageApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Daha eski mesajları yükle'));
    await tester.pumpAndSettle();

    expect(find.text('older'), findsOneWidget);
  });
}

Widget _pageApp(_FakeChatRepository repository) => ProviderScope(
      overrides: [chatRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: ChatPage(args: args)),
    );

const _conversation = Conversation(userAUid: 'a', userBUid: 'b', matchId: 'a_b');

ChatMessage _message(String text, String senderUid) => ChatMessage(
      messageId: text,
      conversationId: 'a_b',
      senderUid: senderUid,
      text: text,
      createdAt: DateTime(2026, 1, 1),
    );

class _AuthenticatedAuth extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(
        AuthUser(id: 'a', email: null, emailVerified: true),
      );
}

class _FakeChatRepository implements ChatRepository {
  _FakeChatRepository({
    this.messages = const [],
    this.olderMessages = const [],
    this.firstCursor,
    this.conversationCompleter,
    this.failLoad = false,
  });

  final List<ChatMessage> messages;
  final List<ChatMessage> olderMessages;
  final Object? firstCursor;
  final Completer<Conversation?>? conversationCompleter;
  final sentTexts = <String>[];
  var failLoad;
  var conversationCalls = 0;

  @override
  Future<Conversation?> getConversationForMatch(String userAUid, String userBUid) {
    conversationCalls++;
    if (failLoad) return Future.error(const ChatFailure('loadFailed'));
    return conversationCompleter?.future ?? Future.value(_conversation);
  }

  @override
  Future<ChatMessagePage> getMessages(
    String conversationId, {
    required String currentUserUid,
    Object? cursor,
    int pageSize = 30,
  }) async => cursor == null
      ? ChatMessagePage(messages: messages, cursor: firstCursor)
      : ChatMessagePage(messages: olderMessages);

  @override
  Stream<List<ChatMessage>> watchMessages(
          String conversationId, String currentUserUid) =>
      const Stream.empty();

  @override
  Future<ChatMessage> sendMessage(
      String conversationId, String senderUid, String text) async {
    sentTexts.add(text);
    return _message('sent', senderUid);
  }

  @override
  Future<Conversation> createConversationIfNeeded(
          String userAUid, String userBUid) async =>
      _conversation;
}

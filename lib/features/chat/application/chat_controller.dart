import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firestore_chat_repository.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';
import '../domain/conversation.dart';

final chatRepositoryProvider =
    Provider<ChatRepository>((ref) => FirestoreChatRepository());
final chatControllerProvider = NotifierProvider.autoDispose
    .family<ChatController, ChatState, ChatSession>(ChatController.new);

class ChatSession {
  const ChatSession(
      {required this.userAUid, required this.userBUid, required this.currentUserUid});
  final String userAUid, userBUid, currentUserUid;
}

class ChatState {
  const ChatState({this.conversation, this.messages = const [], this.isLoading = true,
      this.isSending = false, this.isLoadingMore = false, this.hasMore = false, this.error});
  final Conversation? conversation;
  final List<ChatMessage> messages;
  final bool isLoading, isSending, isLoadingMore, hasMore;
  final Object? error;
  ChatState copyWith({Conversation? conversation, List<ChatMessage>? messages, bool? isLoading,
      bool? isSending, bool? isLoadingMore, bool? hasMore, Object? error, bool clearError = false}) =>
      ChatState(conversation: conversation ?? this.conversation, messages: messages ?? this.messages,
          isLoading: isLoading ?? this.isLoading, isSending: isSending ?? this.isSending,
          isLoadingMore: isLoadingMore ?? this.isLoadingMore, hasMore: hasMore ?? this.hasMore,
          error: clearError ? null : error ?? this.error);
}

class ChatController extends AutoDisposeFamilyNotifier<ChatState, ChatSession> {
  StreamSubscription<List<ChatMessage>>? _subscription;
  Object? _cursor;
  late ChatSession _session;
  ChatRepository get _repository => ref.read(chatRepositoryProvider);
  @override
  ChatState build(ChatSession arg) {
    _session = arg;
    ref.onDispose(() => _subscription?.cancel());
    _load();
    return const ChatState();
  }

  Future<void> _load() async {
    try {
      final conversation = await _repository.getConversationForMatch(_session.userAUid, _session.userBUid);
      if (conversation == null) throw const ChatFailure('conversationNotFound');
      final page = await _repository.getMessages(conversation.conversationId, currentUserUid: _session.currentUserUid);
      _cursor = page.cursor;
      state = ChatState(conversation: conversation, messages: _merge([], page.messages), isLoading: false, hasMore: page.hasMore);
      _subscription = _repository.watchMessages(conversation.conversationId, _session.currentUserUid).listen(
        (messages) => state = state.copyWith(messages: _merge(state.messages, messages), clearError: true),
        onError: (Object error, StackTrace stack) => state = state.copyWith(error: error),
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  Future<void> sendMessage(String text) async {
    final conversation = state.conversation;
    if (conversation == null || state.isSending) return;
    state = state.copyWith(isSending: true, clearError: true);
    try { await _repository.sendMessage(conversation.conversationId, _session.currentUserUid, text); }
    catch (error) { state = state.copyWith(error: error); }
    finally { state = state.copyWith(isSending: false); }
  }

  Future<void> retry() async {
    await _subscription?.cancel();
    _subscription = null;
    _cursor = null;
    state = const ChatState();
    await _load();
  }

  Future<void> loadMore() async {
    final conversation = state.conversation;
    if (conversation == null || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _repository.getMessages(conversation.conversationId, currentUserUid: _session.currentUserUid, cursor: _cursor);
      _cursor = page.cursor;
      state = state.copyWith(messages: _merge(state.messages, page.messages), hasMore: page.hasMore);
    } catch (error) { state = state.copyWith(error: error); }
    finally { state = state.copyWith(isLoadingMore: false); }
  }

  List<ChatMessage> _merge(List<ChatMessage> current, List<ChatMessage> incoming) {
    final values = {for (final message in current) message.messageId: message};
    for (final message in incoming) { values[message.messageId] = message; }
    final result = values.values.toList();
    result.sort((a, b) {
      final byTime =
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0));
      return byTime != 0 ? byTime : a.messageId.compareTo(b.messageId);
    });
    return result;
  }
}

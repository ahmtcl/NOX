import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/chat_controller.dart';
import '../domain/chat_message.dart';

class ChatRouteArgs {
  const ChatRouteArgs({
    required this.session,
    required this.otherUserName,
  });

  final ChatSession session;
  final String otherUserName;
}

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.args});

  final ChatRouteArgs args;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _send(ChatState state) async {
    final text = _textController.text.trim();
    if (text.isEmpty || state.isSending) return;
    await ref
        .read(chatControllerProvider(widget.args.session).notifier)
        .sendMessage(text);
    if (mounted &&
        ref.read(chatControllerProvider(widget.args.session)).error == null) {
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider(widget.args.session));
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(widget.args.otherUserName),
      ),
      body: Column(
        children: [
          Expanded(child: _Body(session: widget.args.session, state: state)),
          if (state.error != null && !state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Sohbet şu anda yüklenemiyor.'),
            ),
          _Composer(
            controller: _textController,
            isSending: state.isSending,
            enabled: state.conversation != null,
            onSend: () => _send(state),
          ),
        ],
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.session, required this.state});

  final ChatSession session;
  final ChatState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.error != null && state.conversation == null) {
      return Center(
        child: FilledButton(
          onPressed: () =>
              ref.read(chatControllerProvider(session).notifier).retry(),
          child: const Text('Tekrar dene'),
        ),
      );
    }
    if (state.messages.isEmpty) {
      return const Center(child: Text('Henüz mesaj yok.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.hasMore)
          Center(
            child: TextButton(
              onPressed: state.isLoadingMore
                  ? null
                  : () => ref
                      .read(chatControllerProvider(session).notifier)
                      .loadMore(),
              child: Text(state.isLoadingMore
                  ? 'Yükleniyor...'
                  : 'Daha eski mesajları yükle'),
            ),
          ),
        for (final message in state.messages)
          _MessageItem(
            message: message,
            isOwn: message.senderUid == session.currentUserUid,
          ),
      ],
    );
  }
}

class _MessageItem extends StatelessWidget {
  const _MessageItem({required this.message, required this.isOwn});

  final ChatMessage message;
  final bool isOwn;

  @override
  Widget build(BuildContext context) => Align(
        alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
        child: Semantics(
          label: isOwn ? 'Benim mesajım' : 'Karşı tarafın mesajı',
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment:
                  isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(message.text),
                if (message.createdAt != null)
                  Text(
                    TimeOfDay.fromDateTime(message.createdAt!).format(context),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
          ),
        ),
      );
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isSending,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled && !isSending,
                decoration: const InputDecoration(hintText: 'Mesaj yaz'),
                onSubmitted: (_) => onSend(),
              ),
            ),
            IconButton(
              key: const ValueKey('send-message'),
              onPressed: enabled && !isSending ? onSend : null,
              icon: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      );
}

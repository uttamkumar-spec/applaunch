import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../models/chat_message.dart';
import '../providers/message_provider.dart';

/// Shared chat UI for a single coach<->athlete thread. Which thread it shows
/// and who "mine" refers to is entirely decided by the [fetchMessages] /
/// [sendMessage] callbacks and [myRole] passed in by the caller.
class ChatThreadView extends StatefulWidget {
  const ChatThreadView({
    super.key,
    required this.title,
    required this.myRole,
    required this.fetchMessages,
    required this.sendMessage,
  });

  final String title;
  final String myRole; // 'coach' | 'athlete'
  final Future<List<ChatMessage>> Function() fetchMessages;
  final Future<void> Function(String text) sendMessage;

  @override
  State<ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends State<ChatThreadView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final messages = await widget.fetchMessages();
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      await widget.sendMessage(text);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Couldn't send. Try again shortly.")));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('No messages yet — say hello.'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          final mine = m.senderRole == widget.myRole;
                          return Align(
                            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints:
                                  BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: mine ? AppColors.primary : AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                m.text,
                                style: TextStyle(color: mine ? Colors.white : AppColors.primaryDark),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Type a message…'),
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AthleteChatScreen extends ConsumerWidget {
  const AthleteChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(messageServiceProvider);
    return ChatThreadView(
      title: 'Your coach',
      myRole: 'athlete',
      fetchMessages: service.fetchMyThread,
      sendMessage: service.sendToCoach,
    );
  }
}

class CoachChatScreen extends ConsumerWidget {
  const CoachChatScreen({super.key, required this.athleteId, required this.athleteName});

  final String athleteId;
  final String athleteName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(messageServiceProvider);
    return ChatThreadView(
      title: athleteName,
      myRole: 'coach',
      fetchMessages: () => service.fetchThreadWithAthlete(athleteId),
      sendMessage: (text) => service.sendToAthlete(athleteId, text),
    );
  }
}

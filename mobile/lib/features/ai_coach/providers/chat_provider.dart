import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

final chatServiceProvider = Provider((ref) => ChatService(ApiClient()));

class ChatState {
  const ChatState({required this.messages, this.busy = false});

  final List<ChatMessage> messages;
  final bool busy;

  ChatState copyWith({List<ChatMessage>? messages, bool? busy}) {
    return ChatState(messages: messages ?? this.messages, busy: busy ?? this.busy);
  }
}

class ChatController extends StateNotifier<ChatState> {
  ChatController(this._service)
      : super(ChatState(messages: [
          ChatMessage(
            role: ChatRole.coach,
            text: "Hi! I'm your AI coach. Ask me anything about getting "
                "started — form, motivation, what to do today, all of it. "
                "You can also attach a photo or short video for a form check.",
          ),
        ]));

  final ChatService _service;

  Future<void> send(String text) async {
    if (text.trim().isEmpty || state.busy) return;
    state = state.copyWith(messages: [...state.messages, ChatMessage(role: ChatRole.user, text: text)], busy: true);
    try {
      final reply = await _service.sendMessage(text);
      state = state.copyWith(
        messages: [...state.messages, ChatMessage(role: ChatRole.coach, text: reply)],
        busy: false,
      );
    } catch (_) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            role: ChatRole.coach,
            text: "I couldn't reach the coaching service just now. Please try again in a moment.",
          ),
        ],
        busy: false,
      );
    }
  }

  Future<void> sendMedia({
    required Uint8List bytes,
    required bool isVideo,
    String? question,
  }) async {
    if (state.busy) return;

    final caption = (question != null && question.trim().isNotEmpty)
        ? question.trim()
        : (isVideo ? 'Video attached for a form check' : 'Photo attached for a form check');

    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(role: ChatRole.user, text: caption, attachedMediaBytes: bytes, attachedMediaIsVideo: isVideo),
      ],
      busy: true,
    );

    try {
      final b64 = base64Encode(bytes);
      final result = await _service.analyseMedia(
        imageBase64: isVideo ? null : b64,
        videoBase64: isVideo ? b64 : null,
        question: question,
      );
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(role: ChatRole.coach, text: result.summary, formAnalysis: result),
        ],
        busy: false,
      );
    } catch (_) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            role: ChatRole.coach,
            text: "I couldn't analyse that just now — try a clearer photo/video, or try again shortly.",
          ),
        ],
        busy: false,
      );
    }
  }
}

final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>((ref) {
  return ChatController(ref.watch(chatServiceProvider));
});

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../widgets/form_analysis_view.dart';

const _suggestedPrompts = [
  "I'm sore today, should I still work out?",
  "What should I eat before a workout?",
  "I missed 3 days, how do I restart?",
  "How do I know if my form is right?",
];

const _maxVideoMb = 20;

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();

  Uint8List? _pendingMediaBytes;
  bool _pendingIsVideo = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    if (ref.read(chatControllerProvider).busy) return;
    final text = _controller.text;

    if (_pendingMediaBytes != null) {
      final bytes = _pendingMediaBytes!;
      final isVideo = _pendingIsVideo;
      setState(() {
        _pendingMediaBytes = null;
        _pendingIsVideo = false;
      });
      _controller.clear();
      await ref.read(chatControllerProvider.notifier).sendMedia(bytes: bytes, isVideo: isVideo, question: text);
    } else {
      if (text.trim().isEmpty) return;
      _controller.clear();
      await ref.read(chatControllerProvider.notifier).send(text);
    }
    _scrollToBottom();
  }

  Future<void> _pickMedia(ImageSource source, {required bool isVideo}) async {
    Navigator.of(context).pop();
    final XFile? file = isVideo
        ? await _picker.pickVideo(source: source, maxDuration: const Duration(seconds: 30))
        : await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;

    if (isVideo) {
      final sizeMb = (await file.length()) / (1024 * 1024);
      if (sizeMb > _maxVideoMb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('That video is ${sizeMb.toStringAsFixed(1)}MB — please use one under ${_maxVideoMb}MB.')),
          );
        }
        return;
      }
    }

    final bytes = await file.readAsBytes();
    setState(() {
      _pendingMediaBytes = bytes;
      _pendingIsVideo = isVideo;
    });
  }

  void _showAttachSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded, color: AppColors.primary),
              title: const Text('Take a photo'),
              onTap: () => _pickMedia(ImageSource.camera, isVideo: false),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: const Text('Choose a photo'),
              onTap: () => _pickMedia(ImageSource.gallery, isVideo: false),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_rounded, color: AppColors.accent),
              title: const Text('Record a short video (≤30s)'),
              onTap: () => _pickMedia(ImageSource.camera, isVideo: true),
            ),
            ListTile(
              leading: const Icon(Icons.video_library_rounded, color: AppColors.accent),
              title: const Text('Choose a video'),
              onTap: () => _pickMedia(ImageSource.gallery, isVideo: true),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);
    final messages = chatState.messages;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Coach')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (chatState.busy ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == messages.length) {
                  return const _ThinkingBubble();
                }
                return _MessageBubble(message: messages[i]);
              },
            ),
          ),
          if (messages.length <= 1)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _suggestedPrompts
                    .map((p) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ActionChip(
                            label: Text(p),
                            onPressed: chatState.busy
                                ? null
                                : () {
                                    _controller.text = p;
                                    _send();
                                  },
                          ),
                        ))
                    .toList(),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_pendingMediaBytes != null) _PendingMediaPreview(
                    bytes: _pendingMediaBytes!,
                    isVideo: _pendingIsVideo,
                    onClear: () => setState(() {
                      _pendingMediaBytes = null;
                      _pendingIsVideo = false;
                    }),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: chatState.busy ? null : _showAttachSheet,
                        icon: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          enabled: !chatState.busy,
                          decoration: InputDecoration(
                            hintText: _pendingMediaBytes != null
                                ? 'Anything specific to ask about this? (optional)'
                                : 'Ask your coach anything…',
                          ),
                          onSubmitted: (_) => _send(),
                          textInputAction: TextInputAction.send,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: chatState.busy ? null : _send,
                        icon: const Icon(Icons.arrow_upward_rounded),
                        style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                      ),
                    ],
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

class _PendingMediaPreview extends StatelessWidget {
  const _PendingMediaPreview({required this.bytes, required this.isVideo, required this.onClear});
  final Uint8List bytes;
  final bool isVideo;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isVideo
                ? Container(
                    width: 56,
                    height: 56,
                    color: AppColors.primaryLight,
                    child: const Icon(Icons.videocam_rounded, color: AppColors.primary),
                  )
                : Image.memory(bytes, width: 56, height: 56, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isVideo ? 'Video ready for a form check' : 'Photo ready for a form check',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          IconButton(icon: const Icon(Icons.close_rounded), onPressed: onClear),
        ],
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEDEFEA)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 10),
            Text('Thinking…', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser ? null : Border.all(color: const Color(0xFFEDEFEA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.attachedMediaBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: message.attachedMediaIsVideo
                    ? Container(
                        width: 160,
                        height: 100,
                        color: Colors.black.withValues(alpha: 0.2),
                        child: const Icon(Icons.videocam_rounded, color: Colors.white),
                      )
                    : Image.memory(message.attachedMediaBytes!, width: 160, height: 100, fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message.text,
              style: TextStyle(color: isUser ? Colors.white : AppColors.textPrimary),
            ),
            if (message.formAnalysis != null) ...[
              const SizedBox(height: 10),
              FormAnalysisView(result: message.formAnalysis!),
            ],
          ],
        ),
      ),
    );
  }
}

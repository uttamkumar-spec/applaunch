import 'dart:typed_data';

import 'form_analysis_result.dart';

enum ChatRole { user, coach }

class ChatMessage {
  ChatMessage({
    required this.role,
    required this.text,
    DateTime? timestamp,
    this.attachedMediaBytes,
    this.attachedMediaIsVideo = false,
    this.formAnalysis,
  }) : timestamp = timestamp ?? DateTime.now();

  final ChatRole role;
  final String text;
  final DateTime timestamp;

  /// Local-only preview of what the user attached to this message (never
  /// sent back from the server — the raw bytes just live in memory).
  final Uint8List? attachedMediaBytes;
  final bool attachedMediaIsVideo;

  /// Present on a coach message that answers a photo/video form check.
  final FormAnalysisResult? formAnalysis;
}

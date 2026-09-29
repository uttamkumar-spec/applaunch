class ChatMessage {
  ChatMessage({
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.createdAt,
  });

  final String senderId;
  final String senderRole; // 'coach' | 'athlete'
  final String text;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        senderId: j['sender_id'].toString(),
        senderRole: j['sender_role'] as String? ?? 'athlete',
        text: j['text'] as String? ?? '',
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

class MessageThread {
  MessageThread({
    required this.athleteId,
    required this.athleteName,
    required this.unread,
    this.lastMessage,
    this.lastMessageAt,
  });

  final String athleteId;
  final String athleteName;
  final bool unread;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  factory MessageThread.fromJson(Map<String, dynamic> j) => MessageThread(
        athleteId: j['athlete_id'].toString(),
        athleteName: j['athlete_name'] as String? ?? 'Athlete',
        unread: j['unread'] as bool? ?? false,
        lastMessage: j['last_message'] as String?,
        lastMessageAt:
            j['last_message_at'] != null ? DateTime.tryParse(j['last_message_at'] as String) : null,
      );
}

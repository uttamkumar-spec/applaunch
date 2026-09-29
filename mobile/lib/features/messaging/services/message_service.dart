import '../../../services/api_client.dart';
import '../models/chat_message.dart';

class MessageService {
  MessageService(this._api);
  final ApiClient _api;

  Future<List<ChatMessage>> fetchMyThread() async {
    final res = await _api.get('/messages/thread') as List;
    return res.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<void> sendToCoach(String text) async {
    await _api.post('/messages/thread', body: {'text': text});
  }

  Future<List<MessageThread>> fetchThreads() async {
    final res = await _api.get('/messages/threads') as List;
    return res.map((t) => MessageThread.fromJson(t as Map<String, dynamic>)).toList();
  }

  Future<List<ChatMessage>> fetchThreadWithAthlete(String athleteId) async {
    final res = await _api.get('/messages/thread/$athleteId') as List;
    return res.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<void> sendToAthlete(String athleteId, String text) async {
    await _api.post('/messages/thread/$athleteId', body: {'text': text});
  }

  Future<int> broadcastToGroup(String groupId, String text) async {
    final res = await _api.post('/messages/broadcast', body: {'group_id': groupId, 'text': text})
        as Map<String, dynamic>;
    return res['athlete_count'] as int? ?? 0;
  }
}

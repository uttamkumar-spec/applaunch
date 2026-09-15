import '../../../services/api_client.dart';
import '../models/chat_message.dart';
import '../models/form_analysis_result.dart';

class ChatService {
  ChatService(this._api);
  final ApiClient _api;

  /// Sends a message to `/ai/chat`. The reply may come from the AI, or be a
  /// fixed acknowledgement when the question was routed to a human coach —
  /// either way it's returned as plain reply text.
  Future<String> sendMessage(String message) async {
    final res = await _api.post('/ai/chat', body: {'message': message});
    return (res as Map<String, dynamic>)['reply'] as String;
  }

  /// Loads this athlete's persisted chat history so it survives app
  /// restarts — including a coach's reply to a routed question that may
  /// have arrived after the original request completed.
  Future<List<ChatMessage>> fetchHistory() async {
    final res = await _api.get('/ai/chat/history');
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(
          (m) => ChatMessage(
            role: m['role'] == 'user' ? ChatRole.user : ChatRole.coach,
            text: m['text'] as String,
            timestamp: DateTime.parse(m['created_at'] as String),
          ),
        )
        .toList();
  }

  /// Sends an attached photo or short video to `/ai/analyse-media` for a
  /// form/muscular-imbalance check. Video frames each get their own Gemini
  /// call server-side, so this is given a generous timeout.
  Future<FormAnalysisResult> analyseMedia({
    String? imageBase64,
    String? videoBase64,
    String? question,
  }) async {
    final res = await _api.post(
      '/ai/analyse-media',
      body: {
        'image_base64': ?imageBase64,
        'video_base64': ?videoBase64,
        'question': ?question,
      },
      timeout: const Duration(seconds: 90),
    );
    return FormAnalysisResult.fromJson(res as Map<String, dynamic>);
  }
}

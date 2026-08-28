import '../../../services/api_client.dart';
import '../models/form_analysis_result.dart';

class ChatService {
  ChatService(this._api);
  final ApiClient _api;

  /// Sends a message to the Gemini-2.5-Flash-backed `/ai/chat` endpoint and
  /// returns the coach's reply text.
  Future<String> sendMessage(String message) async {
    final res = await _api.post('/ai/chat', body: {'message': message});
    return (res as Map<String, dynamic>)['reply'] as String;
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

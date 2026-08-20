import '../../../services/api_client.dart';
import '../models/coach_models.dart';

class CoachFinderService {
  CoachFinderService(this._api);
  final ApiClient _api;

  Future<List<CoachProfile>> fetchCoaches() async {
    try {
      final res = await _api.get('/coaches') as List;
      return res.map((c) => CoachProfile.fromJson(c as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> requestCoach(String coachId) async {
    await _api.post('/coach-requests', body: {'coach_id': coachId});
  }
}

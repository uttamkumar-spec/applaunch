import '../../../services/api_client.dart';
import '../../workouts/models/workout_plan.dart';
import '../models/coach_models.dart';

class CoachService {
  CoachService(this._api);
  final ApiClient _api;

  Future<List<CoachRequest>> fetchRequests() async {
    try {
      final res = await _api.get('/coach/requests') as List;
      return res.map((r) => CoachRequest.fromJson(r as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> respondToRequest(String requestId, bool accept) async {
    await _api.put('/coach/requests/$requestId', body: {'accept': accept});
  }

  Future<List<AssignedAthlete>> fetchAthletes() async {
    try {
      final res = await _api.get('/coach/athletes') as List;
      return res.map((a) => AssignedAthlete.fromJson(a as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Asks the backend (Gemini 2.5 Flash) to draft a plan for [athleteId],
  /// optionally steered by the coach's free-text [notes].
  Future<WorkoutPlan> generatePlan(String athleteId, {String? notes}) async {
    final res = await _api.post('/coach/plans/generate', body: {
      'athlete_id': athleteId,
      'notes': notes,
    });
    return WorkoutPlan.fromJson(res as Map<String, dynamic>);
  }

  Future<void> pushPlan(String athleteId, WorkoutPlan plan) async {
    await _api.post('/coach/plans/$athleteId/push', body: {
      'title': plan.title,
      'level': plan.level,
      'description': plan.description,
      'days': plan.days
          .map((d) => {
                'id': d.id,
                'name': d.name,
                'exercises': d.exercises
                    .map((e) => {
                          'id': e.id,
                          'name': e.name,
                          'sets': e.sets,
                          'reps': e.reps,
                          'rest_seconds': e.restSeconds,
                          'beginner_tip': e.beginnerTip,
                          'instructions': e.instructions,
                        })
                    .toList(),
              })
          .toList(),
    });
  }
}

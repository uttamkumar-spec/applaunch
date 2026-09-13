import '../../../core/models/guardrail_rule.dart';
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

  // --- Guardrails: which athlete questions this coach lets the AI answer
  // instantly, vs. must be routed to them ---

  Future<List<GuardrailRule>> fetchGuardrails() async {
    try {
      final res = await _api.get('/coach/guardrails') as List;
      return res.map((r) => GuardrailRule.fromJson(r as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> createGuardrail(GuardrailRule rule) async {
    await _api.post('/coach/guardrails', body: rule.toJson());
  }

  Future<void> updateGuardrail(String id, GuardrailRule rule) async {
    await _api.put('/coach/guardrails/$id', body: rule.toJson());
  }

  Future<void> deleteGuardrail(String id) async {
    await _api.delete('/coach/guardrails/$id');
  }

  // --- Athlete questions routed to this coach for a human response ---

  Future<List<PendingCoachMessage>> fetchPendingMessages() async {
    try {
      final res = await _api.get('/coach/pending-messages') as List;
      return res.map((m) => PendingCoachMessage.fromJson(m as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<PendingCoachMessage> fetchPendingMessageDetail(String id) async {
    final res = await _api.get('/coach/pending-messages/$id');
    return PendingCoachMessage.fromJson(res as Map<String, dynamic>);
  }

  /// Asks the AI a free-form follow-up about this athlete's broader history
  /// (workouts, nutrition, chat, etc.) — for the coach's own understanding,
  /// never sent to the athlete.
  Future<String> askAboutAthlete(String pendingMessageId, String question) async {
    final res = await _api.post(
      '/coach/pending-messages/$pendingMessageId/ask',
      body: {'question': question},
    );
    return (res as Map<String, dynamic>)['answer'] as String;
  }

  /// Asks the AI to draft a reply to the athlete's routed question,
  /// grounded in their data — a starting point the coach edits before
  /// sending, not a final answer.
  Future<String> draftReply(String pendingMessageId, {String? coachNote}) async {
    final res = await _api.post(
      '/coach/pending-messages/$pendingMessageId/draft',
      body: {'coach_note': coachNote},
    );
    return (res as Map<String, dynamic>)['draft'] as String;
  }

  Future<void> respondToPendingMessage(String pendingMessageId, String reply) async {
    await _api.post('/coach/pending-messages/$pendingMessageId/respond', body: {'reply': reply});
  }
}

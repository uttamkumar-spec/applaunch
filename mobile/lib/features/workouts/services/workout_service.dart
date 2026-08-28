import '../../../services/api_client.dart';
import '../models/workout_plan.dart';

class WorkoutService {
  WorkoutService(this._api);
  final ApiClient _api;

  Future<List<WorkoutPlan>> fetchPlans() async {
    try {
      final res = await _api.get('/workouts/plans') as List;
      return res.map((p) => WorkoutPlan.fromJson(p as Map<String, dynamic>)).toList();
    } catch (_) {
      return _fallbackPlans;
    }
  }

  Future<void> logCompletion({
    required String planId,
    required String dayId,
    required List<String> completedExerciseIds,
  }) async {
    try {
      await _api.post('/workouts/plans/$planId/complete', body: {
        'day_id': dayId,
        'completed_exercise_ids': completedExerciseIds,
      });
    } catch (_) {
      // Offline / backend not reachable — completion still counts locally.
    }
  }
}

/// Shown when the backend isn't reachable yet, so the app is still fully
/// explorable for a beginner starting out on day one.
final _fallbackPlans = [
  WorkoutPlan(
    id: 'beginner-full-body',
    title: 'Beginner Full Body',
    level: 'Absolute beginner',
    description:
        'Three short full-body sessions a week. No equipment needed — just you, some floor space, and 20 minutes.',
    days: [
      WorkoutDay(
        id: 'day-1',
        name: 'Day 1 · Full Body Basics',
        exercises: [
          Exercise(
            id: 'bodyweight-squat',
            name: 'Bodyweight Squat',
            sets: 3,
            reps: '10',
            restSeconds: 45,
            beginnerTip: 'Sit back like you\'re reaching for a chair — knees stay behind your toes.',
            instructions: 'Stand feet shoulder-width apart, lower hips down and back, then stand tall.',
          ),
          Exercise(
            id: 'incline-pushup',
            name: 'Incline Push-Up (on a counter/table)',
            sets: 3,
            reps: '8',
            restSeconds: 45,
            beginnerTip: 'The higher the surface, the easier it is — start high, work your way down over weeks.',
            instructions: 'Hands on a sturdy elevated surface, lower your chest, push back up.',
          ),
          Exercise(
            id: 'glute-bridge',
            name: 'Glute Bridge',
            sets: 3,
            reps: '12',
            restSeconds: 30,
            beginnerTip: 'Squeeze your glutes at the top for a full second — quality over speed.',
            instructions: 'Lie on your back, knees bent, lift hips toward the ceiling, lower slowly.',
          ),
          Exercise(
            id: 'plank-hold',
            name: 'Plank Hold',
            sets: 3,
            reps: '20 sec',
            restSeconds: 30,
            beginnerTip: 'Drop to your knees if a full plank is too hard yet — that still counts.',
            instructions: 'Forearms and toes on the ground, body in a straight line, brace your core.',
          ),
        ],
      ),
      WorkoutDay(
        id: 'day-2',
        name: 'Day 2 · Easy Cardio + Mobility',
        exercises: [
          Exercise(
            id: 'brisk-walk',
            name: 'Brisk Walk',
            sets: 1,
            reps: '15 min',
            restSeconds: 0,
            beginnerTip: 'Aim for a pace where you could talk but not sing.',
          ),
          Exercise(
            id: 'cat-cow',
            name: 'Cat-Cow Stretch',
            sets: 2,
            reps: '10',
            restSeconds: 15,
            beginnerTip: 'Move slowly with your breath — inhale arch, exhale round.',
          ),
        ],
      ),
      WorkoutDay(
        id: 'day-3',
        name: 'Day 3 · Full Body Basics (again!)',
        exercises: [
          Exercise(
            id: 'bodyweight-squat',
            name: 'Bodyweight Squat',
            sets: 3,
            reps: '12',
            restSeconds: 45,
            beginnerTip: 'Two extra reps from Day 1 — notice that? That\'s progress.',
          ),
          Exercise(
            id: 'incline-pushup',
            name: 'Incline Push-Up',
            sets: 3,
            reps: '10',
            restSeconds: 45,
            beginnerTip: 'If 10 feels easy, lower the surface height next time.',
          ),
        ],
      ),
    ],
  ),
];

class ProgressSummary {
  ProgressSummary({
    required this.workoutsThisWeek,
    required this.workoutGoalThisWeek,
    required this.currentStreak,
    required this.totalWorkoutsLogged,
    required this.weeklyCompletion,
  });

  final int workoutsThisWeek;
  final int workoutGoalThisWeek;
  final int currentStreak;
  final int totalWorkoutsLogged;

  /// One entry per of the last 7 days, 0.0-1.0 completion, oldest first.
  final List<double> weeklyCompletion;

  factory ProgressSummary.fromJson(Map<String, dynamic> j) => ProgressSummary(
        workoutsThisWeek: j['workouts_this_week'] as int? ?? 0,
        workoutGoalThisWeek: j['workout_goal_this_week'] as int? ?? 3,
        currentStreak: j['current_streak'] as int? ?? 0,
        totalWorkoutsLogged: j['total_workouts_logged'] as int? ?? 0,
        weeklyCompletion: (j['weekly_completion'] as List? ?? [])
            .map((e) => (e as num).toDouble())
            .toList(),
      );

  factory ProgressSummary.empty() => ProgressSummary(
        workoutsThisWeek: 0,
        workoutGoalThisWeek: 3,
        currentStreak: 0,
        totalWorkoutsLogged: 0,
        weeklyCompletion: const [0, 0, 0, 0, 0, 0, 0],
      );
}

class StravaActivity {
  StravaActivity({
    required this.id,
    required this.name,
    required this.type,
    required this.distanceKm,
    required this.movingTimeMin,
    required this.date,
  });

  final String id;
  final String name;
  final String type;
  final double distanceKm;
  final int movingTimeMin;
  final DateTime date;

  factory StravaActivity.fromJson(Map<String, dynamic> j) => StravaActivity(
        id: j['id'].toString(),
        name: j['name'] as String,
        type: j['type'] as String? ?? 'Workout',
        distanceKm: (j['distance_km'] as num?)?.toDouble() ?? 0,
        movingTimeMin: j['moving_time_min'] as int? ?? 0,
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
      );
}

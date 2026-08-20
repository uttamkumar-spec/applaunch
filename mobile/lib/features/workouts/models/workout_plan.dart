class Exercise {
  Exercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.beginnerTip,
    this.instructions = '',
  });

  final String id;
  final String name;
  final int sets;
  final String reps; // e.g. "10-12" or "30 sec"
  final int restSeconds;
  final String beginnerTip;
  final String instructions;

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
        id: j['id']?.toString() ?? j['name'] as String,
        name: j['name'] as String,
        sets: j['sets'] as int? ?? 3,
        reps: j['reps']?.toString() ?? '10',
        restSeconds: j['rest_seconds'] as int? ?? 45,
        beginnerTip: j['beginner_tip'] as String? ?? '',
        instructions: j['instructions'] as String? ?? '',
      );
}

class WorkoutDay {
  WorkoutDay({required this.id, required this.name, required this.exercises});

  final String id;
  final String name;
  final List<Exercise> exercises;

  factory WorkoutDay.fromJson(Map<String, dynamic> j) => WorkoutDay(
        id: j['id']?.toString() ?? j['name'] as String,
        name: j['name'] as String,
        exercises: (j['exercises'] as List? ?? [])
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class WorkoutPlan {
  WorkoutPlan({
    required this.id,
    required this.title,
    required this.level,
    required this.description,
    required this.days,
  });

  final String id;
  final String title;
  final String level;
  final String description;
  final List<WorkoutDay> days;

  factory WorkoutPlan.fromJson(Map<String, dynamic> j) => WorkoutPlan(
        id: j['id']?.toString() ?? j['title'] as String,
        title: j['title'] as String,
        level: j['level'] as String? ?? 'Beginner',
        description: j['description'] as String? ?? '',
        days: (j['days'] as List? ?? [])
            .map((d) => WorkoutDay.fromJson(d as Map<String, dynamic>))
            .toList(),
      );
}

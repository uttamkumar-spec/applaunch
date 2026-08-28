class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'].toString(),
        name: j['name'] as String? ?? '—',
        email: j['email'] as String? ?? '',
        role: j['role'] as String? ?? 'athlete',
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

class PlatformLimits {
  PlatformLimits({required this.maxAthletesPerCoach, required this.dailyAiMessagesPerAthlete});

  final int maxAthletesPerCoach;
  final int dailyAiMessagesPerAthlete;

  factory PlatformLimits.fromJson(Map<String, dynamic> j) => PlatformLimits(
        maxAthletesPerCoach: j['max_athletes_per_coach'] as int? ?? 20,
        dailyAiMessagesPerAthlete: j['daily_ai_messages_per_athlete'] as int? ?? 50,
      );

  Map<String, dynamic> toJson() => {
        'max_athletes_per_coach': maxAthletesPerCoach,
        'daily_ai_messages_per_athlete': dailyAiMessagesPerAthlete,
      };
}

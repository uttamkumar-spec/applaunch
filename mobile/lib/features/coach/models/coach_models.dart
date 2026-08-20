class CoachProfile {
  CoachProfile({
    required this.id,
    required this.name,
    required this.specialty,
    required this.bio,
    required this.athleteCount,
  });

  final String id;
  final String name;
  final String specialty;
  final String bio;
  final int athleteCount;

  factory CoachProfile.fromJson(Map<String, dynamic> j) => CoachProfile(
        id: j['id'].toString(),
        name: j['name'] as String,
        specialty: j['specialty'] as String? ?? 'General fitness',
        bio: j['bio'] as String? ?? '',
        athleteCount: j['athlete_count'] as int? ?? 0,
      );
}

class CoachRequest {
  CoachRequest({
    required this.id,
    required this.athleteId,
    required this.athleteName,
    required this.status,
    this.aiRecommendationNote,
  });

  final String id;
  final String athleteId;
  final String athleteName;
  final String status; // pending | accepted | declined
  final String? aiRecommendationNote;

  factory CoachRequest.fromJson(Map<String, dynamic> j) => CoachRequest(
        id: j['id'].toString(),
        athleteId: j['athlete_id'].toString(),
        athleteName: j['athlete_name'] as String? ?? 'Athlete',
        status: j['status'] as String? ?? 'pending',
        aiRecommendationNote: j['ai_recommendation_note'] as String?,
      );
}

class AssignedAthlete {
  AssignedAthlete({
    required this.id,
    required this.name,
    required this.primaryGoal,
    required this.currentStreak,
  });

  final String id;
  final String name;
  final String primaryGoal;
  final int currentStreak;

  factory AssignedAthlete.fromJson(Map<String, dynamic> j) => AssignedAthlete(
        id: j['id'].toString(),
        name: j['name'] as String? ?? 'Athlete',
        primaryGoal: j['primary_goal'] as String? ?? 'General fitness',
        currentStreak: j['current_streak'] as int? ?? 0,
      );
}

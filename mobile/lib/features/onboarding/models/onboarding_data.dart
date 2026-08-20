/// Answers collected during the beginner-friendly onboarding quiz. This is
/// sent to the backend once the user has an account so workout plans and
/// the AI coach can be tailored to them.
class OnboardingData {
  OnboardingData({
    this.experienceLevel,
    this.primaryGoal,
    this.daysPerWeek,
    this.equipmentAccess,
    this.focusAreas = const [],
  });

  String? experienceLevel; // 'brand_new' | 'tried_before' | 'getting_back_into_it'
  String? primaryGoal; // 'lose_weight' | 'build_strength' | 'feel_healthier' | 'more_energy'
  int? daysPerWeek;
  String? equipmentAccess; // 'none' | 'home_basics' | 'full_gym'
  List<String> focusAreas; // 'full_body' | 'cardio' | 'strength' | 'flexibility'

  bool get isComplete =>
      experienceLevel != null &&
      primaryGoal != null &&
      daysPerWeek != null &&
      equipmentAccess != null;

  Map<String, dynamic> toJson() => {
        'experience_level': experienceLevel,
        'primary_goal': primaryGoal,
        'days_per_week': daysPerWeek,
        'equipment_access': equipmentAccess,
        'focus_areas': focusAreas,
      };
}

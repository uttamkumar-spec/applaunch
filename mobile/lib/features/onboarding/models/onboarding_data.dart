/// Answers collected during the beginner-friendly onboarding quiz. This is
/// sent to the backend once the user has an account so workout plans and
/// the AI coach can be tailored to them.
class OnboardingData {
  OnboardingData({
    this.experienceLevel,
    this.experienceLevelOtherText = '',
    this.hasWorkedWithCoachBefore,
    this.coachHistoryText = '',
    this.primaryGoal,
    this.primaryGoalOtherText = '',
    this.daysPerWeekSelection,
    this.daysPerWeekOtherText = '',
    this.equipmentAccess,
    this.equipmentAccessOtherText = '',
    this.focusAreas = const [],
  });

  // 'brand_new' | 'tried_before' | 'getting_back_into_it' | 'other'
  String? experienceLevel;
  String experienceLevelOtherText;

  bool? hasWorkedWithCoachBefore;
  String coachHistoryText; // filled in when hasWorkedWithCoachBefore is true

  // 'lose_weight' | 'build_strength' | 'feel_healthier' | 'more_energy' | 'other'
  String? primaryGoal;
  String primaryGoalOtherText;

  // '2' | '3' | '4' | '5' | 'other'
  String? daysPerWeekSelection;
  String daysPerWeekOtherText;

  /// Numeric days/week when a fixed option was picked; null when the answer
  /// was free text (e.g. "1 day" or something irregular).
  int? get daysPerWeek => int.tryParse(daysPerWeekSelection ?? '');

  // 'none' | 'home_basics' | 'full_gym' | 'other'
  String? equipmentAccess;
  String equipmentAccessOtherText;

  List<String> focusAreas; // 'full_body' | 'cardio' | 'strength' | 'flexibility'

  bool get isComplete =>
      experienceLevel != null &&
      hasWorkedWithCoachBefore != null &&
      primaryGoal != null &&
      daysPerWeekSelection != null &&
      equipmentAccess != null;

  Map<String, dynamic> toJson() => {
        'experience_level': experienceLevel,
        'experience_level_other_text': experienceLevelOtherText,
        'has_worked_with_coach_before': hasWorkedWithCoachBefore,
        'coach_history_text': coachHistoryText,
        'primary_goal': primaryGoal,
        'primary_goal_other_text': primaryGoalOtherText,
        'days_per_week': daysPerWeek,
        'days_per_week_selection': daysPerWeekSelection,
        'days_per_week_other_text': daysPerWeekOtherText,
        'equipment_access': equipmentAccess,
        'equipment_access_other_text': equipmentAccessOtherText,
        'focus_areas': focusAreas,
      };
}

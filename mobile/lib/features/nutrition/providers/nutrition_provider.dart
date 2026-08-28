import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';
import '../models/daily_log.dart';
import '../services/nutrition_service.dart';

final nutritionServiceProvider = Provider((ref) => NutritionService(ApiClient()));

class NutritionState {
  const NutritionState({
    this.completedHabitIds = const {},
    this.waterGlasses = 0,
    this.waterGoal = 8,
    this.meals = const [],
    this.streakDays = 1,
  });

  final Set<String> completedHabitIds;
  final int waterGlasses;
  final int waterGoal;
  final List<MealEntry> meals;
  final int streakDays;

  NutritionState copyWith({
    Set<String>? completedHabitIds,
    int? waterGlasses,
    List<MealEntry>? meals,
    int? streakDays,
  }) {
    return NutritionState(
      completedHabitIds: completedHabitIds ?? this.completedHabitIds,
      waterGlasses: waterGlasses ?? this.waterGlasses,
      waterGoal: waterGoal,
      meals: meals ?? this.meals,
      streakDays: streakDays ?? this.streakDays,
    );
  }
}

class NutritionController extends StateNotifier<NutritionState> {
  NutritionController(this._service) : super(const NutritionState());
  final NutritionService _service;

  void toggleHabit(String habitId) {
    final updated = {...state.completedHabitIds};
    final nowCompleted = !updated.contains(habitId);
    nowCompleted ? updated.add(habitId) : updated.remove(habitId);
    state = state.copyWith(completedHabitIds: updated);
    _service.toggleHabit(habitId, nowCompleted);
  }

  void addWater() {
    final glasses = state.waterGlasses + 1;
    state = state.copyWith(waterGlasses: glasses);
    _service.logWater(glasses);
  }

  void removeWater() {
    final glasses = (state.waterGlasses - 1).clamp(0, 99);
    state = state.copyWith(waterGlasses: glasses);
    _service.logWater(glasses);
  }

  void logMeal(String description) {
    final entry = MealEntry(id: DateTime.now().toIso8601String(), description: description, time: DateTime.now());
    state = state.copyWith(meals: [entry, ...state.meals]);
    _service.logMeal(description);
  }
}

final nutritionControllerProvider = StateNotifierProvider<NutritionController, NutritionState>((ref) {
  return NutritionController(ref.watch(nutritionServiceProvider));
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';
import '../models/workout_plan.dart';
import '../services/workout_service.dart';

final workoutServiceProvider = Provider((ref) => WorkoutService(ApiClient()));

final workoutPlansProvider = FutureProvider<List<WorkoutPlan>>((ref) {
  return ref.watch(workoutServiceProvider).fetchPlans();
});

/// The plan the user is currently following (first plan for now — a future
/// iteration lets them switch plans).
final activePlanProvider = Provider<AsyncValue<WorkoutPlan?>>((ref) {
  final plans = ref.watch(workoutPlansProvider);
  return plans.whenData((list) => list.isEmpty ? null : list.first);
});

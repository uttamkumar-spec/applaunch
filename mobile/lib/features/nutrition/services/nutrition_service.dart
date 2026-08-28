import '../../../services/api_client.dart';

class NutritionService {
  NutritionService(this._api);
  final ApiClient _api;

  Future<void> toggleHabit(String habitId, bool completed) async {
    try {
      await _api.post('/nutrition/habits/toggle', body: {
        'habit_id': habitId,
        'completed': completed,
      });
    } catch (_) {
      // Keep working offline; local state already reflects the change.
    }
  }

  Future<void> logMeal(String description) async {
    try {
      await _api.post('/nutrition/meals', body: {'description': description});
    } catch (_) {}
  }

  Future<void> logWater(int glasses) async {
    try {
      await _api.post('/nutrition/water', body: {'glasses': glasses});
    } catch (_) {}
  }
}

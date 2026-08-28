import 'api_client.dart';

/// Talks to the backend's `/users/me` endpoints for onboarding + profile data.
class ProfileService {
  ProfileService(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      final res = await _api.get('/users/me');
      return res as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveOnboarding(Map<String, dynamic> onboardingJson) async {
    await _api.put('/users/me/onboarding', body: onboardingJson);
  }
}

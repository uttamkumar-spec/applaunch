import '../../../core/config/env.dart';
import '../../../services/api_client.dart';
import '../models/progress_models.dart';

class ProgressService {
  ProgressService(this._api);
  final ApiClient _api;

  Future<ProgressSummary> fetchSummary() async {
    try {
      final res = await _api.get('/progress/summary');
      return ProgressSummary.fromJson(res as Map<String, dynamic>);
    } catch (_) {
      return ProgressSummary.empty();
    }
  }
}

class StravaService {
  StravaService(this._api);
  final ApiClient _api;

  /// The backend builds the Strava OAuth authorize URL (with client id +
  /// redirect back to its own callback) and hands it to the app so the
  /// Strava client secret never has to live on-device.
  Future<String?> fetchConnectUrl() async {
    try {
      final res = await _api.get('/strava/connect-url');
      return (res as Map<String, dynamic>)['url'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> fetchConnectionStatus() async {
    try {
      final res = await _api.get('/strava/status');
      return (res as Map<String, dynamic>)['connected'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<List<StravaActivity>> fetchActivities() async {
    try {
      final res = await _api.get('/strava/activities') as List;
      return res.map((a) => StravaActivity.fromJson(a as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  bool get isBackendConfigured => Env.apiBaseUrl.isNotEmpty;
}

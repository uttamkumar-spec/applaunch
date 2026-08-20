import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';
import '../models/progress_models.dart';
import '../services/progress_service.dart';

final progressServiceProvider = Provider((ref) => ProgressService(ApiClient()));
final stravaServiceProvider = Provider((ref) => StravaService(ApiClient()));

final progressSummaryProvider = FutureProvider.autoDispose<ProgressSummary>((ref) {
  return ref.watch(progressServiceProvider).fetchSummary();
});

final stravaConnectedProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.watch(stravaServiceProvider).fetchConnectionStatus();
});

final stravaActivitiesProvider = FutureProvider.autoDispose<List<StravaActivity>>((ref) {
  return ref.watch(stravaServiceProvider).fetchActivities();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';
import '../services/coach_service.dart';

final coachServiceProvider = Provider((ref) => CoachService(ApiClient()));

final coachRequestsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(coachServiceProvider).fetchRequests();
});

final assignedAthletesProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(coachServiceProvider).fetchAthletes();
});

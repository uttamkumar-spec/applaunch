import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';
import '../services/coach_finder_service.dart';

final coachFinderServiceProvider = Provider((ref) => CoachFinderService(ApiClient()));

final availableCoachesProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(coachFinderServiceProvider).fetchCoaches();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';
import '../services/admin_service.dart';

final adminServiceProvider = Provider((ref) => AdminService(ApiClient()));

final adminUsersProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(adminServiceProvider).fetchUsers();
});

final platformLimitsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(adminServiceProvider).fetchLimits();
});

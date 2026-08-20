import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';
import '../../../services/profile_service.dart';
import 'auth_provider.dart';

final profileServiceProvider = Provider((ref) => ProfileService(ApiClient()));

/// Refetches whenever the signed-in user changes (login/logout/switch).
final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(profileServiceProvider).fetchProfile();
});

/// 'athlete' | 'coach' | 'admin'. Defaults to 'athlete' while loading or if
/// the backend can't be reached, so the app degrades to the fullest-built
/// experience rather than stalling on an unknown role.
final roleProvider = Provider<String>((ref) {
  final profileAsync = ref.watch(profileProvider);
  return profileAsync.maybeWhen(
    data: (p) => (p?['role'] as String?) ?? 'athlete',
    orElse: () => 'athlete',
  );
});

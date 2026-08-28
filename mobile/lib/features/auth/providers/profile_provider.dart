import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Runs once per signed-in session: if the onboarding quiz was completed
/// right before Google sign-in, its answers were stashed to disk (since
/// web reloads the page mid-OAuth-redirect, losing in-memory state) — this
/// pushes them to the backend and clears the stash.
final pendingOnboardingFlushProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;

  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('pending_onboarding');
  if (raw == null) return;

  try {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    await ref.read(profileServiceProvider).saveOnboarding(json);
  } catch (_) {
    // Unreadable — drop it rather than retry forever with bad data.
  }
  await prefs.remove('pending_onboarding');
});

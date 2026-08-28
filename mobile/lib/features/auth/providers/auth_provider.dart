import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Emits every Supabase auth change so the router can redirect between the
/// signed-out and signed-in parts of the app.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  if (!Env.isSupabaseConfigured) {
    return const Stream.empty();
  }
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  if (!Env.isSupabaseConfigured) return null;
  final authState = ref.watch(authStateChangesProvider);
  return authState.maybeWhen(
    data: (state) => state.session?.user,
    orElse: () => ref.read(supabaseClientProvider).auth.currentUser,
  );
});

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.watch(supabaseClientProvider));
});

class AuthController {
  AuthController(this._client);
  final SupabaseClient _client;

  /// Google is the only sign-in method — this covers both new and
  /// returning users, since Supabase creates the auth record (keyed by
  /// its UUID, same as everywhere else in the app) on first sign-in and
  /// simply logs in on every one after that.
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'com.fitmovelab.fitmovelab://login-callback/',
    );
  }

  Future<void> signOut() => _client.auth.signOut();
}

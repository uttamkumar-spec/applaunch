import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../onboarding/screens/onboarding_quiz_screen.dart';
import '../providers/auth_provider.dart';

/// The only way into the app: Google sign-in via Supabase, for both new and
/// returning users. If the user just finished the onboarding quiz, their
/// answers are stashed to disk first — on web, completing Google sign-in
/// reloads the page (losing in-memory state), so this is what lets the
/// answers survive the round trip and get saved once signed in
/// (see [pendingOnboardingFlushProvider]).
class GoogleSignInScreen extends ConsumerStatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  ConsumerState<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends ConsumerState<GoogleSignInScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _continueWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final onboarding = ref.read(onboardingDataProvider);
      if (onboarding.isComplete) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_onboarding', jsonEncode(onboarding.toJson()));
      }
      await ref.read(authControllerProvider).signInWithGoogle();
    } catch (e) {
      setState(() => _error = 'Could not sign in with Google. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Text('Welcome to FitMoveLab', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                "Sign in with Google — it's the only account you'll need.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              if (_error != null) ...[
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 12),
              ],
              ElevatedButton.icon(
                onPressed: _loading ? null : _continueWithGoogle,
                icon: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const _GoogleGlyph(),
                label: Text(_loading ? 'Signing in…' : 'Continue with Google'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: const Text(
        'G',
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 13, height: 1),
      ),
    );
  }
}

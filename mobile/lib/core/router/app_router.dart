import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/screens/admin_home_screen.dart';
import '../../features/ai_coach/screens/ai_chat_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/profile_provider.dart';
import '../../features/auth/screens/google_sign_in_screen.dart';
import '../../features/coach/screens/coach_finder_screen.dart';
import '../../features/coach/screens/coach_home_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/nutrition/screens/nutrition_screen.dart';
import '../../features/onboarding/screens/onboarding_quiz_screen.dart';
import '../../features/onboarding/screens/welcome_screen.dart';
import '../../features/progress/screens/progress_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/workouts/screens/workout_list_screen.dart';
import '../config/env.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

const _roleHome = {
  'coach': '/coach-home',
  'admin': '/admin-home',
  'athlete': '/home',
};

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: _RiverpodRefreshStream(ref),
    redirect: (context, state) {
      if (!Env.isSupabaseConfigured) return null;

      final loggedIn = ref.read(currentUserProvider) != null;
      final loggingInRoute = ['/auth', '/onboarding', '/'].contains(state.matchedLocation);

      if (!loggedIn && !loggingInRoute) return '/';

      if (loggedIn) {
        final role = ref.read(roleProvider);
        final home = _roleHome[role] ?? '/home';
        final onWrongRoleHome = (state.matchedLocation == '/home' && role != 'athlete') ||
            (state.matchedLocation == '/coach-home' && role != 'coach') ||
            (state.matchedLocation == '/admin-home' && role != 'admin');
        if (state.matchedLocation == '/' || state.matchedLocation == '/auth' || onWrongRoleHome) {
          return home;
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingQuizScreen()),
      GoRoute(path: '/auth', builder: (context, state) => const GoogleSignInScreen()),
      GoRoute(path: '/coach-finder', builder: (context, state) => const CoachFinderScreen()),
      GoRoute(path: '/coach-home', builder: (context, state) => const CoachHomeScreen()),
      GoRoute(path: '/admin-home', builder: (context, state) => const AdminHomeScreen()),
      GoRoute(path: '/admin/limits', builder: (context, state) => const AdminLimitsScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/workouts', builder: (context, state) => const WorkoutListScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/coach', builder: (context, state) => const AiChatScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/nutrition', builder: (context, state) => const NutritionScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/progress', builder: (context, state) => const ProgressScreen()),
          ]),
        ],
      ),
    ],
  );
});

/// Bridges Riverpod's auth + role streams into a [Listenable] so go_router
/// re-evaluates `redirect` on sign-in/out and once the user's role loads,
/// without recreating the whole router (which would blow away nav state).
class _RiverpodRefreshStream extends ChangeNotifier {
  _RiverpodRefreshStream(Ref ref) {
    ref.listen(authStateChangesProvider, (previous, next) => notifyListeners());
    ref.listen(roleProvider, (previous, next) => notifyListeners());
  }
}

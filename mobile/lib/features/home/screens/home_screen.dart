import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../progress/providers/progress_provider.dart';
import '../../workouts/providers/workout_provider.dart';
import '../../workouts/screens/workout_day_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final firstName = (user?.userMetadata?['full_name'] as String?)?.split(' ').first;
    final planAsync = ref.watch(activePlanProvider);
    final summaryAsync = ref.watch(progressSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(firstName != null ? 'Hi, $firstName' : 'Welcome'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authControllerProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          summaryAsync.maybeWhen(
            data: (s) => Card(
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 32),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        s.currentStreak > 0
                            ? "${s.currentStreak}-day streak — you're building a real habit."
                            : "Let's start your first streak today.",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),
          Text("Today's workout", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          planAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Could not load your plan: $e'),
            data: (plan) {
              if (plan == null || plan.days.isEmpty) {
                return const Text('No plan yet — check the Workouts tab.');
              }
              final day = plan.days.first;
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(18),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 28),
                  ),
                  title: Text(day.name, style: Theme.of(context).textTheme.titleLarge),
                  subtitle: Text('${day.exercises.length} exercises · about 20 min'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => WorkoutDayScreen(plan: plan, day: day)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Quick links', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickLink(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Ask your AI coach',
                  onTap: () => context.go('/coach'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickLink(
                  icon: Icons.restaurant_rounded,
                  label: "Log today's habits",
                  onTap: () => context.go('/nutrition'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _QuickLink(
            icon: Icons.groups_rounded,
            label: 'Find a human coach',
            onTap: () => context.push('/coach-finder'),
          ),
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 10),
              Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

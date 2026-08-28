import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../models/workout_plan.dart';
import '../providers/workout_provider.dart';
import 'workout_day_screen.dart';

class WorkoutListScreen extends ConsumerWidget {
  const WorkoutListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(workoutPlansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Plan')),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load workouts: $e')),
        data: (plans) {
          if (plans.isEmpty) {
            return const Center(child: Text('No workout plan yet.'));
          }
          final plan = plans.first;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Chip(label: Text(plan.level)),
                      const SizedBox(height: 10),
                      Text(plan.title, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 6),
                      Text(plan.description, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('This week', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...plan.days.map((day) => _DayCard(plan: plan, day: day)),
            ],
          );
        },
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.plan, required this.day});

  final WorkoutPlan plan;
  final WorkoutDay day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.directions_run_rounded, color: AppColors.primary),
          ),
          title: Text(day.name, style: Theme.of(context).textTheme.titleLarge),
          subtitle: Text('${day.exercises.length} exercises'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => WorkoutDayScreen(plan: plan, day: day)),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/progress_provider.dart';
import '../widgets/strava_connect_card.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(progressSummaryProvider);
    final activitiesAsync = ref.watch(stravaActivitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(progressSummaryProvider);
              ref.invalidate(stravaConnectedProvider);
              ref.invalidate(stravaActivitiesProvider);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
            summaryAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Could not load progress: $e'),
              data: (summary) => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Current streak',
                          value: '${summary.currentStreak} days',
                          icon: Icons.local_fire_department_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'This week',
                          value: '${summary.workoutsThisWeek}/${summary.workoutGoalThisWeek}',
                          icon: Icons.check_circle_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Last 7 days', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 140,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(summary.weeklyCompletion.length, (i) {
                                final completion = summary.weeklyCompletion[i].clamp(0.05, 1.0);
                                return Container(
                                  width: 18,
                                  height: 140 * completion,
                                  decoration: BoxDecoration(
                                    color: summary.weeklyCompletion[i] > 0
                                        ? AppColors.primary
                                        : AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total workouts logged: ${summary.totalWorkoutsLogged}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const StravaConnectCard(),
            const SizedBox(height: 20),
            activitiesAsync.maybeWhen(
              data: (activities) {
                if (activities.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Strava activity', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ...activities.map((a) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.directions_run_rounded, color: AppColors.accent),
                            title: Text(a.name),
                            subtitle: Text(
                              '${a.type} · ${a.distanceKm.toStringAsFixed(1)} km · ${a.movingTimeMin} min\n${DateFormat.yMMMd().format(a.date)}',
                            ),
                            isThreeLine: true,
                          ),
                        )),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.accent),
            const SizedBox(height: 10),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

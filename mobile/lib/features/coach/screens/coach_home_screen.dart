import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/coach_provider.dart';
import 'coach_athlete_detail_screen.dart';

class CoachHomeScreen extends ConsumerWidget {
  const CoachHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(coachRequestsProvider);
    final athletesAsync = ref.watch(assignedAthletesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authControllerProvider).signOut();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(coachRequestsProvider);
          ref.invalidate(assignedAthletesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Pending requests', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            requestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Could not load requests: $e'),
              data: (requests) {
                if (requests.isEmpty) return const Text('No pending requests right now.');
                return Column(
                  children: requests.map((r) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.athleteName, style: Theme.of(context).textTheme.titleLarge),
                            if (r.aiRecommendationNote != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'AI note: ${r.aiRecommendationNote}',
                                  style: const TextStyle(color: AppColors.primaryDark),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      await ref.read(coachServiceProvider).respondToRequest(r.id, false);
                                      ref.invalidate(coachRequestsProvider);
                                    },
                                    child: const Text('Decline'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await ref.read(coachServiceProvider).respondToRequest(r.id, true);
                                      ref.invalidate(coachRequestsProvider);
                                      ref.invalidate(assignedAthletesProvider);
                                    },
                                    child: const Text('Accept'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 28),
            Text('Your athletes', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            athletesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Could not load athletes: $e'),
              data: (athletes) {
                if (athletes.isEmpty) return const Text('No athletes assigned yet.');
                return Column(
                  children: athletes.map((a) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person_rounded, color: AppColors.primary),
                        title: Text(a.name),
                        subtitle: Text('${a.primaryGoal} · ${a.currentStreak}-day streak'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CoachAthleteDetailScreen(athlete: a)),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

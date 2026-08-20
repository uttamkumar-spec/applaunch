import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/coach_finder_provider.dart';

class CoachFinderScreen extends ConsumerWidget {
  const CoachFinderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coachesAsync = ref.watch(availableCoachesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Find a Coach')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: AppColors.primaryLight,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Not sure who's right for you? Ask your AI coach in chat and it'll point you to a good fit.",
                      style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/coach'),
                    child: const Text('Ask AI'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Available coaches', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          coachesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Could not load coaches: $e'),
            data: (coaches) {
              if (coaches.isEmpty) {
                return const Text('No coaches available yet — check back soon.');
              }
              return Column(
                children: coaches.map((c) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primaryLight,
                                child: Text(c.name[0].toUpperCase(),
                                    style: const TextStyle(color: AppColors.primaryDark)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name, style: Theme.of(context).textTheme.titleLarge),
                                    Text(c.specialty, style: Theme.of(context).textTheme.bodyMedium),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (c.bio.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(c.bio, style: Theme.of(context).textTheme.bodyMedium),
                          ],
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () async {
                              await ref.read(coachFinderServiceProvider).requestCoach(c.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Request sent to ${c.name}.')),
                                );
                              }
                            },
                            child: const Text('Request this coach'),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

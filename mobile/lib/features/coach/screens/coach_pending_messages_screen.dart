import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/coach_provider.dart';
import 'coach_pending_message_detail_screen.dart';

/// Questions from this coach's athletes that a guardrail routed away from
/// the AI — the coach answers each one directly, optionally with an
/// AI-drafted starting point.
class CoachPendingMessagesScreen extends ConsumerWidget {
  const CoachPendingMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingMessagesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Athlete Questions')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(pendingMessagesProvider),
        child: pendingAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load questions: $e')),
          data: (pending) {
            if (pending.isEmpty) {
              return ListView(
                children: const [
                  Padding(padding: EdgeInsets.all(40), child: Text('No questions waiting on you right now.')),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: pending.length,
              itemBuilder: (context, i) {
                final p = pending[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.accent),
                    title: Text(p.athleteName),
                    subtitle: Text(p.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CoachPendingMessageDetailScreen(pendingMessageId: p.id)),
                      );
                      ref.invalidate(pendingMessagesProvider);
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

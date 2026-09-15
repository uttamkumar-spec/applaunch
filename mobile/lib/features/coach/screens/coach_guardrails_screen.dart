import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/guardrails_editor.dart';
import '../providers/coach_provider.dart';

/// Lets a coach define, on top of the platform's default guardrails, which
/// of their own athletes' questions the AI can answer instantly vs. must be
/// routed to the coach.
class CoachGuardrailsScreen extends ConsumerWidget {
  const CoachGuardrailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(coachGuardrailsProvider);
    final service = ref.read(coachServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Guardrail Rules')),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load rules: $e')),
        data: (rules) => GuardrailsEditor(
          rules: rules,
          emptyHint:
              "You don't have any rules of your own yet. Platform defaults still apply — add a rule here to customize "
              'what the AI can answer for your own athletes.',
          onCreate: (rule) async {
            await service.createGuardrail(rule);
            ref.invalidate(coachGuardrailsProvider);
          },
          onUpdate: (id, rule) async {
            await service.updateGuardrail(id, rule);
            ref.invalidate(coachGuardrailsProvider);
          },
          onDelete: (id) async {
            await service.deleteGuardrail(id);
            ref.invalidate(coachGuardrailsProvider);
          },
        ),
      ),
    );
  }
}

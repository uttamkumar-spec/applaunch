import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/guardrails_editor.dart';
import '../providers/admin_provider.dart';

/// Platform-wide default guardrail rules — apply to every athlete, and a
/// coach can layer their own rules on top for their own athletes.
class AdminGuardrailsScreen extends ConsumerWidget {
  const AdminGuardrailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(adminGuardrailsProvider);
    final service = ref.read(adminServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Platform Guardrail Rules')),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load rules: $e')),
        data: (rules) => GuardrailsEditor(
          rules: rules,
          emptyHint:
              'No platform rules yet. Until you add one, every athlete question routes to their coach by default.',
          onCreate: (rule) async {
            await service.createGuardrail(rule);
            ref.invalidate(adminGuardrailsProvider);
          },
          onUpdate: (id, rule) async {
            await service.updateGuardrail(id, rule);
            ref.invalidate(adminGuardrailsProvider);
          },
          onDelete: (id) async {
            await service.deleteGuardrail(id);
            ref.invalidate(adminGuardrailsProvider);
          },
        ),
      ),
    );
  }
}

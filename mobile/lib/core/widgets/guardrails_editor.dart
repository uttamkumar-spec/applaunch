import 'package:flutter/material.dart';

import '../models/guardrail_rule.dart';
import '../theme/app_theme.dart';

/// Shared list + create/edit/delete UI for guardrail rules, used by both the
/// coach screen (their own rules) and the admin screen (platform-wide
/// defaults) — the two differ only in which API calls back them.
class GuardrailsEditor extends StatelessWidget {
  const GuardrailsEditor({
    super.key,
    required this.rules,
    required this.emptyHint,
    required this.onCreate,
    required this.onUpdate,
    required this.onDelete,
  });

  final List<GuardrailRule> rules;
  final String emptyHint;
  final Future<void> Function(GuardrailRule rule) onCreate;
  final Future<void> Function(String id, GuardrailRule rule) onUpdate;
  final Future<void> Function(String id) onDelete;

  void _openForm(BuildContext context, {GuardrailRule? existing}) {
    final label = TextEditingController(text: existing?.label);
    final keywords = TextEditingController(text: existing?.keywords.join(', '));
    final instructions = TextEditingController(text: existing?.responseInstructions);
    String action = existing?.action ?? 'route_to_coach';
    bool enabled = existing?.enabled ?? true;
    bool submitting = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(existing == null ? 'New guardrail rule' : 'Edit rule', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(controller: label, decoration: const InputDecoration(labelText: 'Label')),
                const SizedBox(height: 12),
                TextField(
                  controller: keywords,
                  decoration: const InputDecoration(
                    labelText: 'Keywords (comma-separated)',
                    hintText: 'pain, hurt, injury',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: action,
                  decoration: const InputDecoration(labelText: 'When matched'),
                  items: const [
                    DropdownMenuItem(value: 'route_to_coach', child: Text('Route to coach')),
                    DropdownMenuItem(value: 'auto_respond', child: Text('Let AI answer instantly')),
                  ],
                  onChanged: (v) => setState(() => action = v ?? 'route_to_coach'),
                ),
                if (action == 'auto_respond') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: instructions,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Guidance for the AI reply',
                      hintText: 'What should the AI emphasize when answering this?',
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enabled'),
                  value: enabled,
                  onChanged: (v) => setState(() => enabled = v),
                ),
                if (error != null) ...[
                  const SizedBox(height: 6),
                  Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                ],
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          final kws = keywords.text.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
                          if (label.text.trim().isEmpty || kws.isEmpty) {
                            setState(() => error = 'Label and at least one keyword are required.');
                            return;
                          }
                          if (action == 'auto_respond' && instructions.text.trim().isEmpty) {
                            setState(() => error = 'Guidance for the AI reply is required for this action.');
                            return;
                          }
                          setState(() {
                            submitting = true;
                            error = null;
                          });
                          final rule = GuardrailRule(
                            id: existing?.id ?? '',
                            scope: existing?.scope ?? '',
                            label: label.text.trim(),
                            keywords: kws,
                            action: action,
                            responseInstructions: action == 'auto_respond' ? instructions.text.trim() : null,
                            enabled: enabled,
                          );
                          try {
                            if (existing == null) {
                              await onCreate(rule);
                            } else {
                              await onUpdate(existing.id, rule);
                            }
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          } catch (_) {
                            setState(() {
                              error = "Couldn't save. Try again shortly.";
                              submitting = false;
                            });
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New rule'),
      ),
      body: rules.isEmpty
          ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(emptyHint, textAlign: TextAlign.center)))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: rules.length,
              itemBuilder: (context, i) {
                final r = rules[i];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      r.isAutoRespond ? Icons.smart_toy_rounded : Icons.support_agent_rounded,
                      color: r.enabled ? (r.isAutoRespond ? AppColors.primary : AppColors.accent) : Colors.grey,
                    ),
                    title: Text(r.label, style: TextStyle(color: r.enabled ? null : Colors.grey)),
                    subtitle: Text(
                      '${r.isAutoRespond ? "Auto-answer" : "Route to coach"} · ${r.keywords.join(", ")}'
                      '${r.enabled ? "" : " · disabled"}',
                    ),
                    onTap: () => _openForm(context, existing: r),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => onDelete(r.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

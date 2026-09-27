import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../workouts/models/workout_plan.dart';
import '../models/coach_models.dart';
import '../providers/coach_provider.dart';

class CoachGroupDetailScreen extends ConsumerStatefulWidget {
  const CoachGroupDetailScreen({super.key, required this.group});

  final CoachGroup group;

  @override
  ConsumerState<CoachGroupDetailScreen> createState() => _CoachGroupDetailScreenState();
}

class _CoachGroupDetailScreenState extends ConsumerState<CoachGroupDetailScreen> {
  final _notesController = TextEditingController();
  late Set<String> _selectedMemberIds;
  WorkoutPlan? _draft;
  bool _savingMembers = false;
  bool _generating = false;
  bool _pushing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedMemberIds = widget.group.athleteIds.toSet();
  }

  Future<void> _saveMembers() async {
    setState(() => _savingMembers = true);
    try {
      await ref.read(coachServiceProvider).updateGroupMembers(widget.group.id, _selectedMemberIds.toList());
      ref.invalidate(coachGroupsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Group members updated.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Couldn't save members. Try again shortly.")));
      }
    } finally {
      if (mounted) setState(() => _savingMembers = false);
    }
  }

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final plan = await ref.read(coachServiceProvider).generatePlanForGroup(
            widget.group.id,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );
      setState(() => _draft = plan);
    } catch (e) {
      setState(() => _error = 'Could not generate a plan right now. Try again shortly.');
    } finally {
      setState(() => _generating = false);
    }
  }

  Future<void> _push() async {
    if (_draft == null) return;
    setState(() => _pushing = true);
    try {
      final count = await ref.read(coachServiceProvider).pushPlanToGroup(widget.group.id, _draft!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plan pushed to $count athlete${count == 1 ? '' : 's'}.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _error = 'Could not push the plan. Try again shortly.');
    } finally {
      if (mounted) setState(() => _pushing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final athletesAsync = ref.watch(assignedAthletesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.group.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Members', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Choose which of your athletes belong to this group.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          athletesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Could not load athletes: $e'),
            data: (athletes) {
              if (athletes.isEmpty) {
                return const Text('No athletes assigned to you yet.');
              }
              return Column(
                children: athletes.map((a) {
                  final selected = _selectedMemberIds.contains(a.id);
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: selected,
                    title: Text(a.name),
                    subtitle: Text(a.primaryGoal),
                    onChanged: (checked) => setState(() {
                      if (checked ?? false) {
                        _selectedMemberIds.add(a.id);
                      } else {
                        _selectedMemberIds.remove(a.id);
                      }
                    }),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _savingMembers ? null : _saveMembers,
            child: _savingMembers
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Save members (${_selectedMemberIds.length})'),
          ),
          const Divider(height: 40),
          Text('Draft a plan with AI', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            "Since this goes to several athletes, describe the group's level and focus here — "
            "the plan won't be based on any one athlete's profile.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'e.g. "mostly beginners, 3 days a week, bodyweight only, one has a bad knee"',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _generating ? null : _generate,
            icon: _generating
                ? const SizedBox(
                    height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(_generating ? 'Generating…' : 'Generate plan with AI'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (_draft != null) ...[
            const SizedBox(height: 20),
            Text(_draft!.title, style: Theme.of(context).textTheme.titleLarge),
            Text(_draft!.description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            ..._draft!.days.map((day) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(day.name, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        ...day.exercises.map((e) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('• ${e.name} — ${e.sets} × ${e.reps}'),
                            )),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _pushing ? null : _push,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              child: _pushing
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Push to group (${_selectedMemberIds.length})'),
            ),
          ],
        ],
      ),
    );
  }
}

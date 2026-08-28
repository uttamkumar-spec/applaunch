import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../workouts/models/workout_plan.dart';
import '../models/coach_models.dart';
import '../providers/coach_provider.dart';

class CoachAthleteDetailScreen extends ConsumerStatefulWidget {
  const CoachAthleteDetailScreen({super.key, required this.athlete});

  final AssignedAthlete athlete;

  @override
  ConsumerState<CoachAthleteDetailScreen> createState() => _CoachAthleteDetailScreenState();
}

class _CoachAthleteDetailScreenState extends ConsumerState<CoachAthleteDetailScreen> {
  final _notesController = TextEditingController();
  WorkoutPlan? _draft;
  bool _generating = false;
  bool _pushing = false;
  String? _error;

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final plan = await ref.read(coachServiceProvider).generatePlan(
            widget.athlete.id,
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
      await ref.read(coachServiceProvider).pushPlan(widget.athlete.id, _draft!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plan pushed to ${widget.athlete.name}.')),
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
    final a = widget.athlete;
    return Scaffold(
      appBar: AppBar(title: Text(a.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Goal: ${a.primaryGoal}', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text('Current streak: ${a.currentStreak} days',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Draft a plan with AI', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Any notes for this plan? e.g. "focus on lower body, they have a bad knee"',
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
                  : Text('Push to ${a.name}'),
            ),
          ],
        ],
      ),
    );
  }
}

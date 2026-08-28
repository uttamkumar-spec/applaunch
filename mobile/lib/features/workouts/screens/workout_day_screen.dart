import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../models/workout_plan.dart';
import '../providers/workout_provider.dart';

class WorkoutDayScreen extends ConsumerStatefulWidget {
  const WorkoutDayScreen({super.key, required this.plan, required this.day});

  final WorkoutPlan plan;
  final WorkoutDay day;

  @override
  ConsumerState<WorkoutDayScreen> createState() => _WorkoutDayScreenState();
}

class _WorkoutDayScreenState extends ConsumerState<WorkoutDayScreen> {
  final Set<String> _completed = {};

  Future<void> _finish() async {
    await ref.read(workoutServiceProvider).logCompletion(
          planId: widget.plan.id,
          dayId: widget.day.id,
          completedExerciseIds: _completed.toList(),
        );
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.celebration_rounded, color: AppColors.accent, size: 40),
        title: const Text('Nice work!'),
        content: Text(
          "You completed ${_completed.length}/${widget.day.exercises.length} exercises. "
          "Every session adds up — see you next time.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allDone = _completed.length == widget.day.exercises.length;
    return Scaffold(
      appBar: AppBar(title: Text(widget.day.name)),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: widget.day.exercises.length,
        itemBuilder: (context, i) {
          final ex = widget.day.exercises[i];
          final done = _completed.contains(ex.id);
          return _ExerciseCard(
            exercise: ex,
            done: done,
            onToggle: () => setState(() {
              done ? _completed.remove(ex.id) : _completed.add(ex.id);
            }),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: _completed.isEmpty ? null : _finish,
            child: Text(allDone ? 'Finish workout' : 'Save progress (${_completed.length}/${widget.day.exercises.length})'),
          ),
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  const _ExerciseCard({required this.exercise, required this.done, required this.onToggle});

  final Exercise exercise;
  final bool done;
  final VoidCallback onToggle;

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  int? _secondsLeft;
  Timer? _timer;

  void _startRest() {
    _timer?.cancel();
    setState(() => _secondsLeft = widget.exercise.restSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if ((_secondsLeft ?? 0) <= 1) {
        t.cancel();
        setState(() => _secondsLeft = null);
      } else {
        setState(() => _secondsLeft = _secondsLeft! - 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(ex.name, style: Theme.of(context).textTheme.titleLarge),
                  ),
                  Checkbox(value: widget.done, onChanged: (_) => widget.onToggle()),
                ],
              ),
              Text('${ex.sets} sets × ${ex.reps}', style: Theme.of(context).textTheme.bodyMedium),
              if (ex.instructions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(ex.instructions, style: Theme.of(context).textTheme.bodyMedium),
              ],
              if (ex.beginnerTip.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_rounded, color: AppColors.primaryDark, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ex.beginnerTip,
                          style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (ex.restSeconds > 0) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _secondsLeft == null ? _startRest : null,
                  icon: const Icon(Icons.timer_outlined),
                  label: Text(_secondsLeft == null ? 'Start rest timer' : 'Resting… ${_secondsLeft}s'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

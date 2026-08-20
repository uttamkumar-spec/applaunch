import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../models/daily_log.dart';
import '../providers/nutrition_provider.dart';

const _iconMap = {
  'water_drop': Icons.water_drop_rounded,
  'eco': Icons.eco_rounded,
  'directions_walk': Icons.directions_walk_rounded,
  'bedtime': Icons.bedtime_rounded,
};

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  void _showAddMeal(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What did you eat?', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              "No calorie counting — just a quick note to build awareness.",
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'e.g. Oatmeal with banana'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  ref.read(nutritionControllerProvider.notifier).logMeal(controller.text.trim());
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nutritionControllerProvider);
    final controller = ref.read(nutritionControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition & Habits')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMeal(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Log a meal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: AppColors.accent, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${state.streakDays}-day streak — keep it going!',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Water intake', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  IconButton.outlined(
                    onPressed: controller.removeWater,
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${state.waterGlasses} / ${state.waterGoal} glasses',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (state.waterGlasses / state.waterGoal).clamp(0, 1),
                            minHeight: 8,
                            backgroundColor: AppColors.primaryLight,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    onPressed: controller.addWater,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text("Today's habits", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...defaultHabits.map((h) => _HabitTile(
                habit: h,
                checked: state.completedHabitIds.contains(h.id),
                onTap: () => controller.toggleHabit(h.id),
              )),
          const SizedBox(height: 20),
          if (state.meals.isNotEmpty) ...[
            Text("Today's meals", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...state.meals.map((m) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.restaurant_rounded, color: AppColors.primary),
                    title: Text(m.description),
                    subtitle: Text('${m.time.hour}:${m.time.minute.toString().padLeft(2, '0')}'),
                  ),
                )),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({required this.habit, required this.checked, required this.onTap});
  final HabitDefinition habit;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          onTap: onTap,
          leading: Icon(_iconMap[habit.icon], color: AppColors.primary),
          title: Text(habit.label),
          trailing: Checkbox(value: checked, onChanged: (_) => onTap()),
        ),
      ),
    );
  }
}

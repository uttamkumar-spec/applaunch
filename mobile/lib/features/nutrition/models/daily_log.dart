class HabitDefinition {
  const HabitDefinition({required this.id, required this.label, required this.icon});
  final String id;
  final String label;
  final String icon; // maps to a Material icon name in the widget layer
}

const defaultHabits = [
  HabitDefinition(id: 'water', label: 'Drank enough water', icon: 'water_drop'),
  HabitDefinition(id: 'veggies', label: 'Ate a fruit or vegetable', icon: 'eco'),
  HabitDefinition(id: 'moved', label: 'Moved my body today', icon: 'directions_walk'),
  HabitDefinition(id: 'sleep', label: 'Slept 7+ hours', icon: 'bedtime'),
];

class MealEntry {
  MealEntry({required this.id, required this.description, required this.time});
  final String id;
  final String description;
  final DateTime time;
}

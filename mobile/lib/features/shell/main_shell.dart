import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom-tab shell hosting the five main sections of the app. Wrapped
/// around a [StatefulShellRoute] so each tab keeps its own navigation stack.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _labels = ['Home', 'Workouts', 'Coach', 'Nutrition', 'Progress'];
  static const _icons = [
    Icons.home_rounded,
    Icons.fitness_center_rounded,
    Icons.chat_bubble_rounded,
    Icons.restaurant_rounded,
    Icons.insights_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: List.generate(
          _labels.length,
          (i) => BottomNavigationBarItem(icon: Icon(_icons[i]), label: _labels[i]),
        ),
      ),
    );
  }
}

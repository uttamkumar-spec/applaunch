import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../models/onboarding_data.dart';

final onboardingDataProvider = StateProvider<OnboardingData>((ref) => OnboardingData());

class _Step {
  const _Step({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
}

const _steps = [
  _Step(
    title: "Where are you starting from?",
    subtitle: "There's no wrong answer — we just want to meet you where you are.",
  ),
  _Step(
    title: "What matters most to you right now?",
    subtitle: "We'll shape your plan and coach around this.",
  ),
  _Step(
    title: "How many days a week can you realistically show up?",
    subtitle: "Start small — consistency beats intensity.",
  ),
  _Step(
    title: "What do you have to work with?",
    subtitle: "We'll only suggest exercises you can actually do.",
  ),
];

/// A short, encouraging quiz used to tailor workout plans and the AI coach.
/// Answers live in [onboardingDataProvider] until the user creates an
/// account, at which point they're pushed to the backend.
class OnboardingQuizScreen extends ConsumerStatefulWidget {
  const OnboardingQuizScreen({super.key});

  @override
  ConsumerState<OnboardingQuizScreen> createState() => _OnboardingQuizScreenState();
}

class _OnboardingQuizScreenState extends ConsumerState<OnboardingQuizScreen> {
  int _step = 0;

  bool get _canAdvance {
    final data = ref.read(onboardingDataProvider);
    switch (_step) {
      case 0:
        return data.experienceLevel != null;
      case 1:
        return data.primaryGoal != null;
      case 2:
        return data.daysPerWeek != null;
      case 3:
        return data.equipmentAccess != null;
    }
    return false;
  }

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
    } else {
      context.go('/signup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingDataProvider);
    final notifier = ref.read(onboardingDataProvider.notifier);
    final step = _steps[_step];

    return Scaffold(
      appBar: AppBar(
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _step--),
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(_steps.length, (i) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      height: 6,
                      decoration: BoxDecoration(
                        color: i <= _step ? AppColors.primary : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),
              Text(step.title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(step.subtitle, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 28),
              Expanded(child: _buildStepBody(data, notifier)),
              SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: _canAdvance ? _next : null,
                  child: Text(_step == _steps.length - 1 ? "Create my plan" : "Continue"),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepBody(OnboardingData data, StateController<OnboardingData> notifier) {
    switch (_step) {
      case 0:
        return _OptionList(
          options: const {
            'brand_new': "I'm brand new to exercise",
            'tried_before': "I've tried before but didn't stick with it",
            'getting_back_into_it': "I used to be active, getting back into it",
          },
          selected: data.experienceLevel,
          onSelect: (v) => notifier.update((d) => d..experienceLevel = v),
        );
      case 1:
        return _OptionList(
          options: const {
            'lose_weight': "Lose weight",
            'build_strength': "Build strength",
            'feel_healthier': "Just feel healthier overall",
            'more_energy': "Have more energy day-to-day",
          },
          selected: data.primaryGoal,
          onSelect: (v) => notifier.update((d) => d..primaryGoal = v),
        );
      case 2:
        return _OptionList(
          options: const {
            '2': "2 days a week",
            '3': "3 days a week",
            '4': "4 days a week",
            '5': "5+ days a week",
          },
          selected: data.daysPerWeek?.toString(),
          onSelect: (v) => notifier.update((d) => d..daysPerWeek = int.parse(v)),
        );
      case 3:
        return _OptionList(
          options: const {
            'none': "No equipment — just my body",
            'home_basics': "A few basics at home (bands, dumbbells)",
            'full_gym': "I have access to a full gym",
          },
          selected: data.equipmentAccess,
          onSelect: (v) => notifier.update((d) => d..equipmentAccess = v),
        );
    }
    return const SizedBox.shrink();
  }
}

class _OptionList extends StatelessWidget {
  const _OptionList({required this.options, required this.selected, required this.onSelect});

  final Map<String, String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: options.entries.map((e) {
        final isSelected = e.key == selected;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onSelect(e.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryLight : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFE3E6DF),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.value,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: AppColors.primary)
                  else
                    const Icon(Icons.circle_outlined, color: Color(0xFFCBD1C7)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

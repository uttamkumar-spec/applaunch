import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/option_picker.dart';
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
    title: "Have you worked with a coach before?",
    subtitle: "In person, online, a class — anything counts.",
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
        return data.experienceLevel != null &&
            (data.experienceLevel != 'other' || data.experienceLevelOtherText.trim().isNotEmpty);
      case 1:
        return data.hasWorkedWithCoachBefore != null &&
            (data.hasWorkedWithCoachBefore != true || data.coachHistoryText.trim().isNotEmpty);
      case 2:
        return data.primaryGoal != null &&
            (data.primaryGoal != 'other' || data.primaryGoalOtherText.trim().isNotEmpty);
      case 3:
        return data.daysPerWeekSelection != null &&
            (data.daysPerWeekSelection != 'other' || data.daysPerWeekOtherText.trim().isNotEmpty);
      case 4:
        return data.equipmentAccess != null &&
            (data.equipmentAccess != 'other' || data.equipmentAccessOtherText.trim().isNotEmpty);
    }
    return false;
  }

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
    } else {
      context.go('/auth');
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
        return OptionPicker(
          options: const {
            'brand_new': "I'm brand new to exercise",
            'tried_before': "I've tried before but didn't stick with it",
            'getting_back_into_it': "I used to be active, getting back into it",
          },
          selected: data.experienceLevel,
          onSelect: (v) => notifier.update((d) => d.clone()..experienceLevel = v),
          otherText: data.experienceLevelOtherText,
          onOtherTextChanged: (v) => notifier.update((d) => d.clone()..experienceLevelOtherText = v),
        );
      case 1:
        return _YesNoWithDetail(
          selected: data.hasWorkedWithCoachBefore,
          onSelect: (v) => notifier.update((d) => d.clone()..hasWorkedWithCoachBefore = v),
          detailText: data.coachHistoryText,
          onDetailTextChanged: (v) => notifier.update((d) => d.clone()..coachHistoryText = v),
          detailHint: "Who was it, or where — tell us a bit about it",
        );
      case 2:
        return OptionPicker(
          options: const {
            'lose_weight': "Lose weight",
            'build_strength': "Build strength",
            'feel_healthier': "Just feel healthier overall",
            'more_energy': "Have more energy day-to-day",
          },
          selected: data.primaryGoal,
          onSelect: (v) => notifier.update((d) => d.clone()..primaryGoal = v),
          otherText: data.primaryGoalOtherText,
          onOtherTextChanged: (v) => notifier.update((d) => d.clone()..primaryGoalOtherText = v),
        );
      case 3:
        return OptionPicker(
          options: const {
            '2': "2 days a week",
            '3': "3 days a week",
            '4': "4 days a week",
            '5': "5+ days a week",
          },
          selected: data.daysPerWeekSelection,
          onSelect: (v) => notifier.update((d) => d.clone()..daysPerWeekSelection = v),
          otherText: data.daysPerWeekOtherText,
          onOtherTextChanged: (v) => notifier.update((d) => d.clone()..daysPerWeekOtherText = v),
        );
      case 4:
        return OptionPicker(
          options: const {
            'none': "No equipment — just my body",
            'home_basics': "A few basics at home (bands, dumbbells)",
            'full_gym': "I have access to a full gym",
          },
          selected: data.equipmentAccess,
          onSelect: (v) => notifier.update((d) => d.clone()..equipmentAccess = v),
          otherText: data.equipmentAccessOtherText,
          onOtherTextChanged: (v) => notifier.update((d) => d.clone()..equipmentAccessOtherText = v),
        );
    }
    return const SizedBox.shrink();
  }
}

/// Yes/No question that reveals a free-text field when the answer is Yes.
class _YesNoWithDetail extends StatefulWidget {
  const _YesNoWithDetail({
    required this.selected,
    required this.onSelect,
    required this.detailText,
    required this.onDetailTextChanged,
    required this.detailHint,
  });

  final bool? selected;
  final ValueChanged<bool> onSelect;
  final String detailText;
  final ValueChanged<String> onDetailTextChanged;
  final String detailHint;

  @override
  State<_YesNoWithDetail> createState() => _YesNoWithDetailState();
}

class _YesNoWithDetailState extends State<_YesNoWithDetail> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.detailText);
  }

  @override
  void didUpdateWidget(covariant _YesNoWithDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.detailText != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: widget.detailText,
        selection: TextSelection.collapsed(offset: widget.detailText.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _YesNoTile(label: 'Yes', isSelected: widget.selected == true, onTap: () => widget.onSelect(true)),
        _YesNoTile(label: 'No', isSelected: widget.selected == false, onTap: () => widget.onSelect(false)),
        if (widget.selected == true) ...[
          const SizedBox(height: 12),
          TextField(
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: widget.detailHint,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE3E6DF)),
              ),
            ),
            controller: _controller,
            onChanged: widget.onDetailTextChanged,
          ),
        ],
      ],
    );
  }
}

class _YesNoTile extends StatelessWidget {
  const _YesNoTile({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
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
                  label,
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
  }
}

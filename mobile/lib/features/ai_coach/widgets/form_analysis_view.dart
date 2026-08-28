import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/form_analysis_result.dart';

Color _severityColor(String severity) {
  switch (severity) {
    case 'high':
      return AppColors.danger;
    case 'low':
      return AppColors.primary;
    default:
      return AppColors.warning;
  }
}

class _FlawCard extends StatelessWidget {
  const _FlawCard({required this.flaw, required this.index});
  final FormFlaw flaw;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(flaw.severity);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$index. ${flaw.label}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  flaw.severity.toUpperCase(),
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(flaw.explanation, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ExercisesBox extends StatelessWidget {
  const _ExercisesBox({required this.muscles, required this.exercises});
  final List<String> muscles;
  final List<String> exercises;

  @override
  Widget build(BuildContext context) {
    if (muscles.isEmpty && exercises.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (muscles.isNotEmpty) ...[
            const Text('Muscles to work on',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primaryDark)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: muscles.map((m) => Chip(label: Text(m, style: const TextStyle(fontSize: 11)))).toList(),
            ),
          ],
          if (exercises.isNotEmpty) ...[
            if (muscles.isNotEmpty) const SizedBox(height: 10),
            const Text('Recommended exercises',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primaryDark)),
            const SizedBox(height: 4),
            ...exercises.map((e) => Text('• $e', style: const TextStyle(fontSize: 12, color: AppColors.primaryDark))),
          ],
        ],
      ),
    );
  }
}

/// Renders a completed form-check — either a single annotated image or a
/// scrollable filmstrip of annotated video frames — inside a chat bubble.
class FormAnalysisView extends StatefulWidget {
  const FormAnalysisView({super.key, required this.result});
  final FormAnalysisResult result;

  @override
  State<FormAnalysisView> createState() => _FormAnalysisViewState();
}

class _FormAnalysisViewState extends State<FormAnalysisView> {
  int _selectedFrame = 0;

  @override
  Widget build(BuildContext context) {
    final r = widget.result;

    if (!r.isVideo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r.annotatedImageBase64 != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(base64Decode(r.annotatedImageBase64!), fit: BoxFit.cover),
            ),
          const SizedBox(height: 8),
          if (r.flaws.isEmpty)
            const Text('✓ No significant form issues detected', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))
          else
            ...r.flaws.asMap().entries.map((e) => _FlawCard(flaw: e.value, index: e.key + 1)),
          _ExercisesBox(muscles: r.musclesNeedingStrength, exercises: r.recommendedExercises),
        ],
      );
    }

    if (r.frames.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✓ No significant form issues detected in this video',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          _ExercisesBox(muscles: r.musclesNeedingStrength, exercises: r.recommendedExercises),
        ],
      );
    }

    final frame = r.frames[_selectedFrame];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: r.frames.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final f = r.frames[i];
              final selected = i == _selectedFrame;
              return GestureDetector(
                onTap: () => setState(() => _selectedFrame = i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: selected ? AppColors.accent : Colors.transparent, width: 2),
                    ),
                    child: Image.memory(base64Decode(f.annotatedImageBase64), width: 90, height: 60, fit: BoxFit.cover),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(base64Decode(frame.annotatedImageBase64), fit: BoxFit.cover),
        ),
        const SizedBox(height: 8),
        ...frame.flaws.asMap().entries.map((e) => _FlawCard(flaw: e.value, index: e.key + 1)),
        _ExercisesBox(muscles: r.musclesNeedingStrength, exercises: r.recommendedExercises),
      ],
    );
  }
}

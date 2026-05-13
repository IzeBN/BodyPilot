import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../models/training_models.dart';

class TrainingCard extends StatelessWidget {
  final WorkoutSummary workout;
  final VoidCallback? onTap;

  const TrainingCard({super.key, required this.workout, this.onTap});

  LinearGradient get _gradient {
    switch (workout.gradient) {
      case WorkoutGradient.coral:   return AppGradients.coral;
      case WorkoutGradient.violet:  return AppGradients.violet;
      case WorkoutGradient.graph:   return AppGradients.graph;
      case WorkoutGradient.cyan:    return AppGradients.cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.trainingCard),
          border: Border.all(color: AppColors.borderStrong, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111827).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.trainingCard),
          child: Column(
            children: [
              // Hero gradient header — 100px
              Container(
                height: 100,
                decoration: BoxDecoration(gradient: _gradient),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        workout.tag.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(workout.name, style: AppText.cardTitle(color: Colors.white)),
                  ],
                ),
              ),
              // Body metrics: мин | упр. | ~ккал
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Builder(
                  builder: (context) {
                    final l = AppL10n.of(context);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Metric(value: '${workout.durationMin}', unit: l.unitMin),
                        _Metric(value: '${workout.exerciseCount}', unit: l.unitExercises),
                        _Metric(value: '~${workout.kcal}', unit: l.unitKcal),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String unit;
  const _Metric({required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value, style: AppText.counter()),
        const SizedBox(width: 3),
        Text(unit, style: AppText.meta12(color: AppColors.textHint)),
      ],
    );
  }
}

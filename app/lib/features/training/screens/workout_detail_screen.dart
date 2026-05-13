import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';
import '../models/training_models.dart';
import '../providers/training_provider.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  final String workoutId;
  const WorkoutDetailScreen({super.key, required this.workoutId});

  LinearGradient _gradient(WorkoutGradient g) {
    switch (g) {
      case WorkoutGradient.coral:   return AppGradients.coral;
      case WorkoutGradient.violet:  return AppGradients.violet;
      case WorkoutGradient.graph:   return AppGradients.graph;
      case WorkoutGradient.cyan:    return AppGradients.cyan;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(workoutDetailProvider(workoutId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: detailAsync.when(
        data: (detail) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Hero(detail: detail, gradient: _gradient(detail.gradient)),
            ),
            SliverToBoxAdapter(child: _StatsStrip(detail: detail)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                child: Builder(
                  builder: (ctx) {
                    final l = AppL10n.of(ctx);
                    return Row(
                      children: [
                        Text(
                          l.exercisesSection.toUpperCase(),
                          style: AppText.labelCaps11(),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${detail.exerciseCount}',
                          style: AppText.monoSmall(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _ExRow(ex: detail.exercises[i]),
                childCount: detail.exercises.length,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                child: Builder(
                  builder: (ctx) => AppButton(
                    label: AppL10n.of(ctx).workoutDetailCta,
                    onPressed: () => context.push('/training/$workoutId/live'),
                  ),
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(AppL10n.of(context).errorLoading)),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final WorkoutDetail detail;
  final LinearGradient gradient;
  const _Hero({required this.detail, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(gradient: gradient),
      padding: const EdgeInsets.fromLTRB(22, 68, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(AppRadius.appBarAction),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                ),
              ),
              const Spacer(),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(AppRadius.appBarAction),
                ),
                child: const Icon(Icons.more_horiz, color: Colors.white, size: 18),
              ),
            ],
          ),
          const Spacer(),
          Text(
            detail.tag.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: Colors.white,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

// Stats strip: МИН | ККАЛ | УПР.
class _StatsStrip extends StatelessWidget {
  final WorkoutDetail detail;
  const _StatsStrip({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 16, 22, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Builder(
        builder: (context) {
          final l = AppL10n.of(context);
          return Row(
            children: [
              Expanded(child: _StatCol(value: '${detail.durationMin}', label: l.statMin)),
              Container(width: 1, height: 32, color: AppColors.borderStrong),
              Expanded(child: _StatCol(value: '${detail.kcal}', label: l.statKcal)),
              Container(width: 1, height: 32, color: AppColors.borderStrong),
              Expanded(child: _StatCol(value: '${detail.exerciseCount}', label: l.statExercises)),
            ],
          );
        },
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String value;
  final String label;
  const _StatCol({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppText.monoNums()),
        const SizedBox(height: 2),
        Text(label, style: AppText.labelCaps()),
      ],
    );
  }
}

class _ExRow extends StatelessWidget {
  final ExerciseEntry ex;
  const _ExRow({required this.ex});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${ex.number}',
                style: AppText.monoCount(color: AppColors.textHint),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ex.name, style: AppText.bodyName()),
                Text(ex.setsReps, style: AppText.meta()),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFED7AA), Color(0xFFFBA74F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('🏋️', style: TextStyle(fontSize: 20))),
          ),
        ],
      ),
    );
  }
}

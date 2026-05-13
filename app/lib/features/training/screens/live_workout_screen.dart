import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';
import '../models/training_models.dart';
import '../providers/training_provider.dart';

class LiveWorkoutScreen extends ConsumerStatefulWidget {
  final String workoutId;
  const LiveWorkoutScreen({super.key, required this.workoutId});

  @override
  ConsumerState<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends ConsumerState<LiveWorkoutScreen> {
  int _exIdx = 0;
  int _setIdx = 0;
  int _reps = 10;
  double _weight = 0;
  bool _initialized = false;

  List<LiveExercise> _toExercises(List<ExerciseEntry> entries) => entries
      .map((e) => LiveExercise(
            name: e.name,
            sets: e.totalSets,
            reps: e.defaultReps,
            weight: e.defaultWeight,
            icon: '🏋️',
          ))
      .toList();

  void _initIfNeeded(List<LiveExercise> exercises) {
    if (!_initialized && exercises.isNotEmpty) {
      _reps = exercises[0].reps;
      _weight = exercises[0].weight;
      _initialized = true;
    }
  }


  double _progressPct(int total, int sets) {
    if (total == 0) return 0;
    return ((_exIdx * 100) / total) + (((_setIdx + 1) / sets) * (100 / total));
  }

  void _next(List<LiveExercise> exercises, bool completed) {
    final total = exercises.length;
    final ex = exercises[_exIdx];
    setState(() {
      if (_setIdx + 1 < ex.sets) {
        _setIdx++;
      } else if (_exIdx + 1 < total) {
        _exIdx++;
        _setIdx = 0;
        _reps = exercises[_exIdx].reps;
        _weight = exercises[_exIdx].weight;
      } else {
        context.go('/journal');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final exercisesAsync = ref.watch(scheduleExercisesProvider(widget.workoutId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: exercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l.errorLoading)),
        data: (entries) {
          final exercises = _toExercises(entries);
          _initIfNeeded(exercises);

          if (exercises.isEmpty) {
            return Center(child: Text(l.errorLoading));
          }

          final ex = exercises[_exIdx];
          final total = exercises.length;
          final totalSets = ex.sets;
          final progressPct = _progressPct(total, totalSets);

          return SafeArea(
            child: Column(
              children: [
                // AppBar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Icon(Icons.close, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                height: 6,
                                color: AppColors.surfaceTint,
                                child: FractionallySizedBox(
                                  widthFactor: (progressPct / 100).clamp(0.0, 1.0),
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AppColors.coralStart, AppColors.coralEnd],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              l.liveExerciseProgress(_exIdx + 1, total),
                              style: AppText.meta(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.pause_outlined, size: 22),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Exercise image with warm gradient
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 22),
                          height: 180,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFED7AA), Color(0xFFFBA74F)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.liveImg),
                          ),
                          child: Center(
                            child: Text(ex.icon, style: const TextStyle(fontSize: 64)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                          child: Text(
                            ex.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
                          child: Text(
                            l.liveSetProgress(_setIdx + 1, totalSets),
                            style: AppText.meta12(color: AppColors.textMuted),
                          ),
                        ),

                        // Set card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 22),
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderStrong, width: 0.5),
                          ),
                          child: Column(
                            children: [
                              // Sets row with labels
                              Row(
                                children: List.generate(totalSets, (i) {
                                  final isDone = i < _setIdx;
                                  final isCurrent = i == _setIdx;
                                  return Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          l.liveSetLabel(i + 1),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textMuted,
                                            letterSpacing: 0.3,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 5),
                                        Container(
                                          width: 44,
                                          height: 44,
                                          margin: const EdgeInsets.symmetric(horizontal: 2),
                                          decoration: BoxDecoration(
                                            color: isDone
                                                ? AppColors.protein
                                                : isCurrent
                                                    ? AppColors.coralStart
                                                    : AppColors.surfaceTint,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: isDone
                                                ? const Text('✓',
                                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))
                                                : isCurrent
                                                    ? const Text('•',
                                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))
                                                    : const Text('—',
                                                        style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 16),

                              // Reps counter
                              const Divider(color: AppColors.borderStrong, height: 1, thickness: 0.5),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(l.liveReps,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                                    ),
                                    _CounterControl(
                                      value: _reps,
                                      onDecrement: () => setState(() { if (_reps > 1) _reps--; }),
                                      onIncrement: () => setState(() => _reps++),
                                    ),
                                  ],
                                ),
                              ),

                              // Weight counter
                              const Divider(color: AppColors.borderStrong, height: 1, thickness: 0.5),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(l.liveWeightKg,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                                    ),
                                    _CounterControl(
                                      value: _weight.toInt(),
                                      onDecrement: () => setState(() { if (_weight > 0) _weight -= 1; }),
                                      onIncrement: () => setState(() => _weight += 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: l.liveSkip,
                          variant: AppButtonVariant.outline,
                          onPressed: () => _next(exercises, false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: AppButton(
                          label: l.liveDone,
                          variant: AppButtonVariant.coral,
                          onPressed: () => _next(exercises, true),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CounterControl extends StatelessWidget {
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _CounterControl({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(icon: '−', onTap: onDecrement),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('$value', style: AppText.counter()),
        ),
        _CircleButton(icon: '+', onTap: onIncrement),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderStrong),
        ),
        child: Center(
          child: Text(icon, style: const TextStyle(fontSize: 16, height: 1)),
        ),
      ),
    );
  }
}

class LiveExercise {
  final String name;
  final int sets;
  final int reps;
  final double weight;
  final String icon;
  LiveExercise({required this.name, required this.sets, required this.reps, required this.weight, required this.icon});
}

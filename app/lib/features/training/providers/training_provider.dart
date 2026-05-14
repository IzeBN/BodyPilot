import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../models/training_models.dart';

part 'training_provider.g.dart';

// ── Schedule → workouts for a given date ─────────────────────────────────────

@riverpod
Future<List<WorkoutSummary>> todaySchedule(TodayScheduleRef ref, String date) async {
  try {
    final resp = await apiDio.get('/api/v1/training/schedule');
    final data = resp.data as Map<String, dynamic>;
    final entries = data['entries'] as List? ?? [];

    // Filter entries matching the requested date
    final filtered = entries.where((e) {
      final md = e as Map<String, dynamic>;
      return md['scheduled_date'] == date;
    });

    int gradientIndex = 0;
    final gradients = WorkoutGradient.values;

    return filtered.map((e) {
      final md = e as Map<String, dynamic>;
      final g = gradients[gradientIndex % gradients.length];
      gradientIndex++;
      return WorkoutSummary(
        id: md['id']?.toString() ?? '',
        workoutId: md['workout_id']?.toString() ?? '',
        name: md['workout_name'] as String? ?? '',
        tag: '',
        durationMin: 45,
        exerciseCount: 0,
        kcal: 0,
        gradient: g,
        scheduleId: md['id']?.toString() ?? '',
        status: md['status'] as String? ?? 'pending',
      );
    }).toList();
  } catch (_) {
    return [];
  }
}

// ── Full schedule (all entries) ───────────────────────────────────────────────

@riverpod
Future<ScheduleData> fullSchedule(FullScheduleRef ref) async {
  final resp = await apiDio.get('/api/v1/training/schedule');
  final data = resp.data as Map<String, dynamic>;
  return ScheduleData.fromJson(data);
}

// ── Exercises for a schedule entry ───────────────────────────────────────────

@riverpod
Future<List<ExerciseEntry>> scheduleExercises(ScheduleExercisesRef ref, String scheduleId) async {
  final resp = await apiDio.get('/api/v1/training/schedule/$scheduleId/exercises');
  final data = resp.data;
  List list;
  if (data is List) {
    list = data;
  } else if (data is Map && data['exercises'] is List) {
    list = data['exercises'] as List;
  } else {
    return [];
  }

  int idx = 1;
  return list.map((e) {
    final md = e as Map<String, dynamic>;
    final approaches = (md['approaches'] as List? ?? []);
    final firstApp = approaches.isNotEmpty
        ? approaches.first as Map<String, dynamic>
        : <String, dynamic>{};
    final reps = (firstApp['repetitions'] as num?)?.toInt() ?? 10;
    final sets = approaches.isNotEmpty ? approaches.length : 3;
    final weight = (firstApp['weight'] as num?)?.toDouble();

    return ExerciseEntry(
      id: md['exercise_id']?.toString() ?? '',
      number: idx++,
      name: md['name'] as String? ?? '',
      setsReps: '$sets × $reps',
      defaultWeight: weight ?? 0,
      defaultReps: reps,
      totalSets: sets,
    );
  }).toList();
}

// ── Workout detail (from schedule entry + exercises) ──────────────────────────

@riverpod
Future<WorkoutDetail> workoutDetail(WorkoutDetailRef ref, String scheduleId) async {
  // Fetch exercises via schedule endpoint
  List<ExerciseEntry> exercises = [];
  try {
    exercises = await ref.read(scheduleExercisesProvider(scheduleId).future);
  } catch (_) {}

  // Get workout name from full schedule list
  String name = '';
  String tag = '';
  int durationMin = 45;
  try {
    final resp = await apiDio.get('/api/v1/training/schedule');
    final data = resp.data as Map<String, dynamic>;
    final entries = data['entries'] as List? ?? [];
    final entry = entries.firstWhere(
      (e) => (e as Map<String, dynamic>)['id']?.toString() == scheduleId,
      orElse: () => <String, dynamic>{},
    ) as Map<String, dynamic>;
    name = entry['workout_name'] as String? ?? '';
    tag = entry['muscle_groups'] as String? ?? '';
    durationMin = (entry['duration_minutes'] as num?)?.toInt() ?? 45;
  } catch (_) {}

  return WorkoutDetail(
    id: scheduleId,
    name: name,
    tag: tag,
    durationMin: durationMin,
    exerciseCount: exercises.length,
    kcal: 0,
    gradient: WorkoutGradient.coral,
    exercises: exercises,
  );
}

// ── Submit workout result ─────────────────────────────────────────────────────

Future<void> submitWorkoutResult({
  required String scheduleId,
  required String exerciseId,
  required List<Map<String, dynamic>> approaches,
  required bool trainingComplete,
}) async {
  await apiDio.post('/api/v1/training/results', data: {
    'schedule_id': int.tryParse(scheduleId) ?? 0,
    'exercise_id': int.tryParse(exerciseId) ?? 0,
    'approaches': approaches,
    'training_complete': trainingComplete,
  });
}

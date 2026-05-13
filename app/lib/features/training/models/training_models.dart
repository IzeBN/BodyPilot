enum WorkoutGradient { coral, violet, graph, cyan }

class WorkoutSummary {
  final String id;
  final String workoutId;
  final String name;
  final String tag;
  final int durationMin;
  final int exerciseCount;
  final int kcal;
  final WorkoutGradient gradient;
  final String scheduleId;
  final String status;

  const WorkoutSummary({
    required this.id,
    required this.workoutId,
    required this.name,
    required this.tag,
    required this.durationMin,
    required this.exerciseCount,
    required this.kcal,
    this.gradient = WorkoutGradient.coral,
    required this.scheduleId,
    this.status = 'pending',
  });
}

class ExerciseEntry {
  final String id;
  final int number;
  final String name;
  final String setsReps;
  final double defaultWeight;
  final int defaultReps;
  final int totalSets;

  const ExerciseEntry({
    required this.id,
    required this.number,
    required this.name,
    required this.setsReps,
    this.defaultWeight = 0,
    this.defaultReps = 10,
    this.totalSets = 3,
  });
}

class WorkoutDetail {
  final String id;
  final String name;
  final String tag;
  final int durationMin;
  final int exerciseCount;
  final int kcal;
  final WorkoutGradient gradient;
  final List<ExerciseEntry> exercises;

  const WorkoutDetail({
    required this.id,
    required this.name,
    required this.tag,
    required this.durationMin,
    required this.exerciseCount,
    required this.kcal,
    required this.gradient,
    required this.exercises,
  });

  factory WorkoutDetail.fromJson(Map<String, dynamic> j) {
    final exercises = (j['exercises'] as List? ?? []);
    int idx = 1;
    final exList = exercises.map((e) {
      final md = e as Map<String, dynamic>;
      final approaches = (md['approaches'] as List? ?? []);
      final first = approaches.isNotEmpty ? approaches.first as Map<String, dynamic> : <String, dynamic>{};
      final reps = (first['repetitions'] as num?)?.toInt() ?? 10;
      final sets = approaches.isNotEmpty ? approaches.length : 3;
      return ExerciseEntry(
        id: md['exercise_id']?.toString() ?? '',
        number: idx++,
        name: md['name'] as String? ?? '',
        setsReps: '$sets × $reps',
        defaultWeight: (first['weight'] as num?)?.toDouble() ?? 0,
        defaultReps: reps,
        totalSets: sets,
      );
    }).toList();

    return WorkoutDetail(
      id: j['workout_id']?.toString() ?? j['id']?.toString() ?? '',
      name: j['workout_name'] as String? ?? j['name'] as String? ?? '',
      tag: j['muscle_groups'] as String? ?? j['tag'] as String? ?? '',
      durationMin: (j['duration_minutes'] as num?)?.toInt() ?? 45,
      exerciseCount: exList.length,
      kcal: (j['calories_burned'] as num?)?.toInt() ?? 0,
      gradient: WorkoutGradient.coral,
      exercises: exList,
    );
  }
}

class ScheduleData {
  final String? programName;
  final int? programId;
  final List<ScheduleEntry> entries;

  const ScheduleData({this.programName, this.programId, required this.entries});

  factory ScheduleData.fromJson(Map<String, dynamic> j) {
    final entries = (j['entries'] as List? ?? [])
        .map((e) => ScheduleEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return ScheduleData(
      programName: j['program_name'] as String?,
      programId: (j['program_id'] as num?)?.toInt(),
      entries: entries,
    );
  }

  /// Current week number (how many completed weeks from first entry)
  int get currentWeek {
    if (entries.isEmpty) return 1;
    final completed = entries.where((e) => e.status == 'completed').length;
    return (completed ~/ 3) + 1;
  }

  /// Total weeks based on total entries
  int get totalWeeks {
    if (entries.isEmpty) return 8;
    return (entries.length / 3).ceil().clamp(1, 20);
  }

  ScheduleEntry? get nextEntry {
    final pending = entries
        .where((e) => e.status == 'pending')
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return pending.isNotEmpty ? pending.first : null;
  }
}

class ScheduleEntry {
  final String id;
  final String workoutId;
  final String workoutName;
  final String scheduledDate;
  final String status;

  const ScheduleEntry({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.scheduledDate,
    required this.status,
  });

  factory ScheduleEntry.fromJson(Map<String, dynamic> j) => ScheduleEntry(
    id: j['id']?.toString() ?? '',
    workoutId: j['workout_id']?.toString() ?? '',
    workoutName: j['workout_name'] as String? ?? '',
    scheduledDate: j['scheduled_date'] as String? ?? '',
    status: j['status'] as String? ?? 'pending',
  );
}

class LiveSet {
  int reps;
  double weight;
  bool done;
  LiveSet({required this.reps, required this.weight, this.done = false});
}

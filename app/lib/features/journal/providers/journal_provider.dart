import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../models/journal_models.dart';

part 'journal_provider.g.dart';

@riverpod
Future<JournalDay> journalDay(JournalDayRef ref, String date) async {
  // Load meals and nutrition goals in parallel
  final results = await Future.wait([
    apiDio.get('/api/v1/nutrition/meals', queryParameters: {'date': date}),
    apiDio.get('/api/v1/nutrition/goals').catchError((_) => null),
  ]);

  final resp = results[0];
  final goalsResp = results[1];

  final data = resp.data as Map<String, dynamic>;
  final meals = (data['meals'] as List? ?? []);
  final summary = data['summary'] as Map<String, dynamic>? ?? {};

  // Load goal calories from API, fallback to local, then 2000
  int goalKcal = 2000;
  if (goalsResp != null) {
    try {
      final gd = goalsResp.data as Map<String, dynamic>?;
      goalKcal = (gd?['calories'] as num?)?.toInt() ?? 2000;
    } catch (_) {}
  }
  if (goalKcal == 2000) {
    // Fallback: try local stored goal
    final local = await loadLocalNutritionGoal();
    if (local != null) goalKcal = local.targetCalories;
  }

  // Group meals by meal_type
  final groups = <String, List<MealEntry>>{};
  for (final m in meals) {
    final md = m as Map<String, dynamic>;
    final type = md['meal_type'] as String? ?? 'other';
    final entry = MealEntry(
      id: md['id']?.toString() ?? '',
      name: md['food_name'] as String? ?? '',
      meta: '${(md['amount_g'] as num?)?.toInt() ?? 0} г',
      kcal: (md['calories'] as num?)?.toInt() ?? 0,
    );
    groups.putIfAbsent(type, () => []).add(entry);
  }

  final mealGroups = groups.entries.map((e) {
    final totalKcal = e.value.fold(0, (s, m) => s + m.kcal);
    return MealGroup(
      id: e.key,
      name: e.key,
      totalKcal: totalKcal,
      entries: e.value,
    );
  }).toList();

  return JournalDay(
    date: date,
    totalKcal: (summary['total_calories'] as num?)?.toInt() ?? 0,
    goalKcal: goalKcal,
    protein: (summary['total_protein'] as num?)?.toInt() ?? 0,
    fat: (summary['total_fat'] as num?)?.toInt() ?? 0,
    carbs: (summary['total_carbs'] as num?)?.toInt() ?? 0,
    meals: mealGroups,
  );
}

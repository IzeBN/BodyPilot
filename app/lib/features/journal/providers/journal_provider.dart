import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../models/journal_models.dart';

part 'journal_provider.g.dart';

@riverpod
Future<JournalDay> journalDay(JournalDayRef ref, String date) async {
  final resp = await apiDio.get(
    '/api/v1/nutrition/meals',
    queryParameters: {'date': date},
  );

  final data = resp.data as Map<String, dynamic>;
  final meals = (data['meals'] as List? ?? []);
  final summary = data['summary'] as Map<String, dynamic>? ?? {};

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
    goalKcal: 2000,
    protein: (summary['total_protein'] as num?)?.toInt() ?? 0,
    fat: (summary['total_fat'] as num?)?.toInt() ?? 0,
    carbs: (summary['total_carbs'] as num?)?.toInt() ?? 0,
    meals: mealGroups,
  );
}

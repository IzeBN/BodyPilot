class MealEntry {
  final String id;
  final String name;
  final String meta;
  final int kcal;
  MealEntry({required this.id, required this.name, required this.meta, required this.kcal});

  factory MealEntry.fromJson(Map<String, dynamic> j) => MealEntry(
        id: j['id']?.toString() ?? '',
        name: j['food_name'] as String? ?? j['name'] as String? ?? '',
        meta: '${j['weight'] ?? j['amount'] ?? ''} г',
        kcal: (j['calories'] as num?)?.toInt() ?? 0,
      );
}

class MealGroup {
  final String id;
  final String name;
  final int totalKcal;
  final List<MealEntry> entries;
  MealGroup({required this.id, required this.name, required this.totalKcal, required this.entries});
}

class JournalDay {
  final String date;
  final int totalKcal;
  final int goalKcal;
  final int protein;
  final int carbs;
  final int fat;
  final List<MealGroup> meals;

  JournalDay({
    required this.date,
    required this.totalKcal,
    required this.goalKcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.meals,
  });
}

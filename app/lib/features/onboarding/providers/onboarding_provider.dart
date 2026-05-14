import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Storage keys ──────────────────────────────────────────────────────────────

const _kDone = 'onboarding_done_v2';
const _kData = 'onboarding_pending_v2';
const _kGoal = 'nutrition_goal_v1';

// ─── Models ────────────────────────────────────────────────────────────────────

class OnboardingData {
  final String goal; // 'lose_weight' | 'maintain' | 'gain_muscle'
  final String gender; // 'male' | 'female'
  final int age;
  final double height; // cm
  final double weight; // kg
  final double targetWeight; // kg
  final String trainingFreq; // '0' | '1-2' | '3-4' | 'daily'
  final List<String> modules; // 'nutrition' | 'training'
  final List<String> equipment; // equipment names

  const OnboardingData({
    required this.goal,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    required this.targetWeight,
    required this.trainingFreq,
    this.modules = const ['nutrition', 'training'],
    this.equipment = const [],
  });

  Map<String, dynamic> toJson() => {
        'goal': goal,
        'gender': gender,
        'age': age,
        'height': height,
        'weight': weight,
        'targetWeight': targetWeight,
        'trainingFreq': trainingFreq,
        'modules': modules,
        'equipment': equipment,
      };

  factory OnboardingData.fromJson(Map<String, dynamic> j) => OnboardingData(
        goal: j['goal'] as String? ?? 'maintain',
        gender: j['gender'] as String? ?? 'male',
        age: j['age'] as int? ?? 25,
        height: (j['height'] as num?)?.toDouble() ?? 170,
        weight: (j['weight'] as num?)?.toDouble() ?? 70,
        targetWeight: (j['targetWeight'] as num?)?.toDouble() ?? 70,
        trainingFreq: j['trainingFreq'] as String? ?? '1-2',
        modules: (j['modules'] as List?)?.cast<String>() ?? const ['nutrition', 'training'],
        equipment: (j['equipment'] as List?)?.cast<String>() ?? const [],
      );
}

class NutritionGoal {
  final int targetCalories;
  final int protein;
  final int fat;
  final int carbs;
  final int? daysToGoal;
  final double? targetWeight;

  const NutritionGoal({
    required this.targetCalories,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.daysToGoal,
    this.targetWeight,
  });

  Map<String, dynamic> toJson() => {
        'targetCalories': targetCalories,
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
        if (daysToGoal != null) 'daysToGoal': daysToGoal,
        if (targetWeight != null) 'targetWeight': targetWeight,
      };

  factory NutritionGoal.fromJson(Map<String, dynamic> j) => NutritionGoal(
        targetCalories: j['targetCalories'] as int? ?? 2000,
        protein: j['protein'] as int? ?? 130,
        fat: j['fat'] as int? ?? 60,
        carbs: j['carbs'] as int? ?? 200,
        daysToGoal: j['daysToGoal'] as int?,
        targetWeight: (j['targetWeight'] as num?)?.toDouble(),
      );
}

// ─── Calculation ───────────────────────────────────────────────────────────────

NutritionGoal calculateNutritionGoal(OnboardingData d) {
  // BMR — Mifflin-St Jeor (WHO/FAO standard)
  final offset = d.gender == 'male' ? 5.0 : -161.0;
  final bmr = 10 * d.weight + 6.25 * d.height - 5 * d.age + offset;

  // Activity coefficient
  final actCoef = switch (d.trainingFreq) {
    'daily' => 1.725,
    '3-4' => 1.55,
    '1-2' => 1.375,
    _ => 1.2,
  };
  final tdee = bmr * actCoef;

  // Target calories
  final targetCal = switch (d.goal) {
    'lose_weight' => (tdee - 500).clamp(1200.0, 9999.0),
    'gain_muscle' => tdee + 300,
    _ => tdee,
  };

  // Macros
  final protein = d.weight * 1.6;
  final fat = d.weight * 0.9;
  final carbs = ((targetCal - protein * 4 - fat * 9) / 4).clamp(0.0, 9999.0);

  // Days to goal
  int? days;
  if (d.goal == 'lose_weight' && d.targetWeight < d.weight) {
    final deficit = tdee - targetCal;
    if (deficit > 0) {
      days = ((d.weight - d.targetWeight) * 7700 / deficit).round().clamp(1, 999);
    }
  } else if (d.goal == 'gain_muscle' && d.targetWeight > d.weight) {
    final surplus = targetCal - tdee;
    if (surplus > 0) {
      days = ((d.targetWeight - d.weight) * 7700 / surplus).round().clamp(1, 999);
    }
  }

  return NutritionGoal(
    targetCalories: targetCal.round(),
    protein: protein.round(),
    fat: fat.round(),
    carbs: carbs.round(),
    daysToGoal: days,
    targetWeight: d.targetWeight,
  );
}

// ─── SharedPreferences helpers ─────────────────────────────────────────────────

Future<bool> loadOnboardingDone() async {
  try {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kDone) ?? false;
  } catch (_) {
    return false;
  }
}

Future<void> saveOnboardingDoneFlag() async {
  try {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDone, true);
  } catch (e) {
    debugPrint('[onboarding] save done failed: $e');
  }
}

Future<void> saveOnboardingData(OnboardingData data) async {
  try {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kData, jsonEncode(data.toJson()));
  } catch (e) {
    debugPrint('[onboarding] save data failed: $e');
  }
}

Future<OnboardingData?> loadOnboardingData() async {
  try {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kData);
    if (raw == null) return null;
    return OnboardingData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (e) {
    debugPrint('[onboarding] load data failed: $e');
    return null;
  }
}

Future<void> saveLocalNutritionGoal(NutritionGoal goal) async {
  try {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kGoal, jsonEncode(goal.toJson()));
  } catch (e) {
    debugPrint('[onboarding] save goal failed: $e');
  }
}

Future<NutritionGoal?> loadLocalNutritionGoal() async {
  try {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kGoal);
    if (raw == null) return null;
    return NutritionGoal.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (e) {
    debugPrint('[onboarding] load goal failed: $e');
    return null;
  }
}

// ─── Riverpod state (no codegen — manual AsyncNotifier) ───────────────────────

class OnboardingDoneNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => loadOnboardingDone();

  Future<void> markDone() async {
    await saveOnboardingDoneFlag();
    state = const AsyncData(true);
  }
}

final onboardingDoneProvider =
    AsyncNotifierProvider<OnboardingDoneNotifier, bool>(
  OnboardingDoneNotifier.new,
);

// ─── Equipment setup done flag ─────────────────────────────────────────────────

const _kEquipDone = 'equipment_setup_done_v1';

Future<bool> loadEquipmentSetupDone() async {
  try {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kEquipDone) ?? false;
  } catch (_) {
    return false;
  }
}

Future<void> saveEquipmentSetupDone() async {
  try {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kEquipDone, true);
  } catch (_) {}
}

class EquipmentSetupDoneNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => loadEquipmentSetupDone();

  Future<void> markDone() async {
    await saveEquipmentSetupDone();
    state = const AsyncData(true);
  }
}

final equipmentSetupDoneProvider =
    AsyncNotifierProvider<EquipmentSetupDoneNotifier, bool>(
  EquipmentSetupDoneNotifier.new,
);

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/api_client.dart';
import '../../features/onboarding/providers/onboarding_provider.dart' as ob;

part 'profile_provider.g.dart';

class UserProfile {
  final int id;
  final String? email;
  final String? fullname;
  final NutritionProfile? nutrition;
  final TrainingProfile? training;
  final Subscription? subscription;

  const UserProfile({
    required this.id,
    this.email,
    this.fullname,
    this.nutrition,
    this.training,
    this.subscription,
  });

  String get initials {
    final name = fullname ?? email ?? '';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.isNotEmpty) return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
    return '??';
  }

  factory UserProfile.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>? ?? j;
    final np = j['nutrition_profile'] as Map<String, dynamic>?;
    final tp = j['training_profile'] as Map<String, dynamic>?;
    final sub = j['subscription'] as Map<String, dynamic>?;
    return UserProfile(
      id: (user['id'] as num?)?.toInt() ?? 0,
      email: user['email'] as String?,
      fullname: user['fullname'] as String?,
      nutrition: np != null ? NutritionProfile.fromJson(np) : null,
      training: tp != null ? TrainingProfile.fromJson(tp) : null,
      subscription: sub != null ? Subscription.fromJson(sub) : null,
    );
  }
}

class NutritionProfile {
  final int? caloriesGoal;
  final int? proteinG;
  final int? fatG;
  final int? carbsG;
  final double? weightKg;
  final int? heightCm;
  final String? birthDate;
  final String? goal;

  const NutritionProfile({
    this.caloriesGoal,
    this.proteinG,
    this.fatG,
    this.carbsG,
    this.weightKg,
    this.heightCm,
    this.birthDate,
    this.goal,
  });

  factory NutritionProfile.fromJson(Map<String, dynamic> j) => NutritionProfile(
    caloriesGoal: (j['calories'] as num?)?.toInt(),
    proteinG: (j['protein_g'] as num?)?.toInt(),
    fatG: (j['fat_g'] as num?)?.toInt(),
    carbsG: (j['carbs_g'] as num?)?.toInt(),
    weightKg: (j['weight_kg'] as num?)?.toDouble(),
    heightCm: (j['height_cm'] as num?)?.toInt(),
    birthDate: j['birth_date'] as String?,
    goal: j['goal'] as String?,
  );
}

class TrainingProfile {
  final int? preferredDurationMin;
  final String? experience;
  final String? trainingType;
  final int? sessionsPerWeek;

  const TrainingProfile({
    this.preferredDurationMin,
    this.experience,
    this.trainingType,
    this.sessionsPerWeek,
  });

  factory TrainingProfile.fromJson(Map<String, dynamic> j) => TrainingProfile(
    preferredDurationMin: (j['preferred_duration_min'] as num?)?.toInt(),
    experience: j['experience'] as String?,
    trainingType: j['training_type'] as String?,
    sessionsPerWeek: (j['sessions_per_week'] as num?)?.toInt(),
  );
}

class Subscription {
  final String? planName;
  final String? expiresAt;
  final bool isActive;

  const Subscription({this.planName, this.expiresAt, this.isActive = false});

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
    planName: j['plan_name'] as String?,
    expiresAt: j['expires_at'] as String?,
    isActive: j['is_active'] as bool? ?? false,
  );

  String get expireShort {
    if (expiresAt == null) return '';
    final dt = DateTime.tryParse(expiresAt!);
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}';
  }
}

// ── Nutrition goals from a separate endpoint ──────────────────────────────────

class NutritionGoals {
  final int calories;
  final int proteinG;
  final int fatG;
  final int carbsG;

  const NutritionGoals({
    this.calories = 2000,
    this.proteinG = 130,
    this.fatG = 70,
    this.carbsG = 200,
  });

  factory NutritionGoals.fromJson(Map<String, dynamic> j) => NutritionGoals(
    calories: (j['calories'] as num?)?.toInt() ?? 2000,
    proteinG: (j['protein_g'] as num?)?.toInt() ?? 130,
    fatG: (j['fat_g'] as num?)?.toInt() ?? 70,
    carbsG: (j['carbs_g'] as num?)?.toInt() ?? 200,
  );
}

@riverpod
Future<UserProfile> userProfile(UserProfileRef ref) async {
  final resp = await apiDio.get('/api/v1/user/profile');
  return UserProfile.fromJson(resp.data as Map<String, dynamic>);
}

@riverpod
Future<NutritionGoals> nutritionGoals(NutritionGoalsRef ref) async {
  try {
    final resp = await apiDio.get('/api/v1/nutrition/goals');
    final data = resp.data;
    if (data is List && data.isNotEmpty) {
      return NutritionGoals.fromJson(data.first as Map<String, dynamic>);
    }
    if (data is Map) {
      return NutritionGoals.fromJson(data as Map<String, dynamic>);
    }
  } catch (_) {}

  // Fallback: local onboarding-computed goal
  final local = await ob.loadLocalNutritionGoal();
  if (local != null) {
    return NutritionGoals(
      calories: local.targetCalories,
      proteinG: local.protein,
      fatG: local.fat,
      carbsG: local.carbs,
    );
  }
  return const NutritionGoals();
}

// ── Weekly progress (for calendar tags) ──────────────────────────────────────

class DayProgress {
  final String date;
  final String status; // 'completed' | 'pending' | 'none'
  final String? workoutName;

  const DayProgress({required this.date, required this.status, this.workoutName});

  factory DayProgress.fromJson(Map<String, dynamic> j) => DayProgress(
    date: j['date'] as String,
    status: j['status'] as String? ?? 'none',
    workoutName: j['workout_name'] as String?,
  );
}

@riverpod
Future<List<DayProgress>> weeklyProgress(WeeklyProgressRef ref) async {
  try {
    final resp = await apiDio.get('/api/v1/user/progress');
    final data = resp.data as Map<String, dynamic>;
    final days = data['days'] as List? ?? [];
    return days.map((d) => DayProgress.fromJson(d as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
  }
}

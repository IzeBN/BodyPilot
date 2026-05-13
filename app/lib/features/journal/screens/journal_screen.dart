import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/profile_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/avatar_button.dart';
import '../../../shared/widgets/macro_rings.dart';
import '../../training/providers/training_provider.dart';
import '../../training/widgets/training_card.dart';
import '../models/journal_models.dart';
import '../providers/journal_provider.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _eatSectionOpen = true;
  bool _trainSectionOpen = true;

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final journalAsync = ref.watch(journalDayProvider(_dateKey));
    final trainingAsync = ref.watch(todayScheduleProvider(_dateKey));
    final scheduleAsync = ref.watch(fullScheduleProvider);
    final goalsAsync = ref.watch(nutritionGoalsProvider);
    final progressAsync = ref.watch(weeklyProgressProvider);

    final schedule = scheduleAsync.valueOrNull;
    final week = schedule?.currentWeek ?? 1;
    final totalWeeks = schedule?.totalWeeks ?? 8;
    final progressDays = progressAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, week, totalWeeks),
          SliverToBoxAdapter(
            child: _CalendarStrip(
              selected: _selectedDate,
              onSelect: (d) => setState(() => _selectedDate = d),
              progressDays: progressDays,
            ),
          ),
          journalAsync.when(
            data: (day) {
              final goalKcal = goalsAsync.valueOrNull?.calories ?? day.goalKcal;
              final effectiveDay = goalKcal != day.goalKcal
                  ? JournalDay(
                      date: day.date,
                      totalKcal: day.totalKcal,
                      goalKcal: goalKcal,
                      protein: day.protein,
                      fat: day.fat,
                      carbs: day.carbs,
                      meals: day.meals,
                    )
                  : day;
              return SliverList(
                delegate: SliverChildListDelegate([
                  _SummaryBlock(day: effectiveDay),
                  const SizedBox(height: 8),
                  _SectionHead(
                    title: l.sectionFood,
                    count: effectiveDay.meals.fold(0, (s, g) => s + g.entries.length),
                    sub: l.foodSectionSub(effectiveDay.totalKcal, effectiveDay.protein, effectiveDay.carbs, effectiveDay.fat),
                    open: _eatSectionOpen,
                    onTap: () => setState(() => _eatSectionOpen = !_eatSectionOpen),
                  ),
                  if (_eatSectionOpen) ...[
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppColors.surfaceTint, width: 0.5)),
                      ),
                      child: Column(
                        children: [
                          for (final group in effectiveDay.meals)
                            for (final entry in group.entries) _MealRow(entry: entry),
                          _AddMealLink(label: l.addMeal, onTap: () {}),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ]),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => SliverFillRemaining(
              child: Center(child: Text(l.errorLoading)),
            ),
          ),
          trainingAsync.when(
            data: (workouts) {
              final nextEntry = schedule?.nextEntry;
              return SliverList(
                delegate: SliverChildListDelegate([
                  _SectionHead(
                    title: l.sectionTraining,
                    count: workouts.length,
                    sub: l.trainingSectionSub(week, totalWeeks),
                    open: _trainSectionOpen,
                    onTap: () => setState(() => _trainSectionOpen = !_trainSectionOpen),
                  ),
                  if (_trainSectionOpen) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Column(
                        children: [
                          for (final w in workouts) ...[
                            const SizedBox(height: 12),
                            TrainingCard(
                              workout: w,
                              onTap: () => context.push('/training/${w.id}'),
                            ),
                          ],
                          const SizedBox(height: 12),
                          if (nextEntry != null)
                            _NextWorkoutLine(workout: nextEntry.workoutName),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 100),
                ]),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, int week, int totalWeeks) {
    final l = AppL10n.of(context);
    final now = DateTime.now();
    final dayNames = [l.dayMon, l.dayTue, l.dayWed, l.dayThu, l.dayFri, l.daySat, l.daySun];
    final monthNames = [
      l.monthJan, l.monthFeb, l.monthMar, l.monthApr, l.monthMay, l.monthJun,
      l.monthJul, l.monthAug, l.monthSep, l.monthOct, l.monthNov, l.monthDec,
    ];
    final dayName = dayNames[now.weekday - 1];
    final month = monthNames[now.month - 1];
    final subtitle = l.journalSubtitle(dayName, now.day, month, week, totalWeeks);

    final profileAsync = ref.watch(userProfileProvider);
    final initials = profileAsync.valueOrNull?.initials ?? '??';

    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      toolbarHeight: 70,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
        title: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.journalTitle, style: AppText.appBarTitle()),
                  Text(subtitle, style: AppText.meta12()),
                ],
              ),
            ),
            AvatarButton(
              initials: initials,
              onTap: () => context.push('/account'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Calendar Strip ────────────────────────────────────────────────────────────

enum _CalDayState { normal, logged, missed, active }
enum _CalTagType { none, violet, coral }

class _CalDay {
  final String label;
  final DateTime date;
  final _CalDayState state;
  final _CalTagType tag;
  _CalDay({required this.label, required this.date, required this.state, required this.tag});
}

class _CalendarStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  final List<DayProgress> progressDays;

  const _CalendarStrip({
    required this.selected,
    required this.onSelect,
    required this.progressDays,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final today = DateTime.now();
    final dayLabels = [l.dayMon, l.dayTue, l.dayWed, l.dayThu, l.dayFri, l.daySat, l.daySun];

    // Build progress map: date string → DayProgress
    final progressMap = {for (final p in progressDays) p.date: p};

    // Build 7 days centered on today
    final days = List.generate(7, (i) {
      final offset = i - 3;
      final date = today.add(Duration(days: offset));
      final isSelected = date.year == selected.year &&
          date.month == selected.month &&
          date.day == selected.day;

      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final progress = progressMap[dateStr];

      _CalDayState state;
      if (isSelected) {
        state = _CalDayState.active;
      } else if (progress != null) {
        state = progress.status == 'completed'
            ? _CalDayState.logged
            : progress.status == 'missed'
                ? _CalDayState.missed
                : _CalDayState.normal;
      } else if (date.isBefore(today) && !isSelected) {
        state = _CalDayState.normal;
      } else {
        state = _CalDayState.normal;
      }

      // Training tag based on workout in progress
      _CalTagType tag = _CalTagType.none;
      if (progress != null && progress.workoutName != null) {
        tag = date.weekday % 2 == 0 ? _CalTagType.violet : _CalTagType.coral;
      }

      return _CalDay(
        label: dayLabels[date.weekday - 1],
        date: date,
        state: state,
        tag: tag,
      );
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days.map((d) => _buildDay(d)).toList(),
      ),
    );
  }

  Widget _buildDay(_CalDay d) {
    Color numBg = Colors.transparent;
    Color numColor = AppColors.textPrimary;
    Border? numBorder;

    switch (d.state) {
      case _CalDayState.active:
        numBg = AppColors.brandBlue;
        numColor = Colors.white;
      case _CalDayState.logged:
        numBorder = Border.all(color: AppColors.protein, width: 1.5);
      case _CalDayState.missed:
        numBorder = Border.all(color: AppColors.calories, width: 1.5);
        numColor = AppColors.calories;
      case _CalDayState.normal:
        break;
    }

    return GestureDetector(
      onTap: () => onSelect(d.date),
      child: Column(
        children: [
          Text(
            d.label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: numBg,
              shape: BoxShape.circle,
              border: numBorder,
            ),
            child: Center(
              child: Text(
                '${d.date.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: numColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Training tag: 18x3px pill
          _buildTag(d.tag),
        ],
      ),
    );
  }

  Widget _buildTag(_CalTagType tag) {
    if (tag == _CalTagType.none) {
      return const SizedBox(width: 18, height: 3);
    }
    final gradient = tag == _CalTagType.violet ? AppGradients.calViolet : AppGradients.calCoral;
    return Container(
      width: 18,
      height: 3,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

// ── Summary Block ─────────────────────────────────────────────────────────────

class _SummaryBlock extends StatelessWidget {
  final JournalDay day;
  const _SummaryBlock({required this.day});

  @override
  Widget build(BuildContext context) {
    final caloriesFill = day.goalKcal > 0 ? (day.totalKcal / day.goalKcal).clamp(0.0, 1.0) : 0.0;
    final proteinFill = day.protein > 0 ? (day.protein / 130.0).clamp(0.0, 1.0) : 0.50;
    final carbsFill = day.carbs > 0 ? (day.carbs / 210.0).clamp(0.0, 1.0) : 0.72;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
      child: Row(
        children: [
          MacroRings(
            caloriesFill: caloriesFill,
            proteinFill: proteinFill,
            carbsFill: carbsFill,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppL10n.of(context).caloriesLabel, style: AppText.labelCaps()),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${day.totalKcal}', style: AppText.heroKcal()),
                    const SizedBox(width: 6),
                    Text(AppL10n.of(context).caloriesGoal(day.goalKcal), style: AppText.meta12()),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MacroItem(color: AppColors.protein, value: '${day.protein}g', label: AppL10n.of(context).macroProtein),
                    const SizedBox(width: 12),
                    _MacroItem(color: AppColors.carbs, value: '${day.carbs}g', label: AppL10n.of(context).macroCarbs),
                    const SizedBox(width: 12),
                    _MacroItem(color: AppColors.fat, value: '${day.fat}g', label: AppL10n.of(context).macroFat),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroItem extends StatelessWidget {
  final Color color;
  final String value;
  final String label;
  const _MacroItem({required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 4),
        Text(value, style: AppText.monoSmall(color: AppColors.textPrimary)),
        const SizedBox(width: 2),
        Text(label, style: AppText.monoSmall()),
      ],
    );
  }
}

// ── Section Head ──────────────────────────────────────────────────────────────

class _SectionHead extends StatelessWidget {
  final String title;
  final int count;
  final String sub;
  final bool open;
  final VoidCallback onTap;

  const _SectionHead({
    required this.title,
    required this.count,
    required this.sub,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
        child: Row(
          children: [
            Text(title, style: AppText.sectionHead()),
            const SizedBox(width: 8),
            Text('$count', style: AppText.monoCount()),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                sub,
                style: AppText.meta(color: AppColors.textMuted),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            AnimatedRotation(
              turns: open ? 0 : -0.25,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceTint,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('⌄', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Meal Row ──────────────────────────────────────────────────────────────────

class _MealRow extends StatelessWidget {
  final MealEntry entry;
  const _MealRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceTint, width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.name, style: AppText.bodyName(), overflow: TextOverflow.ellipsis),
                  Text(entry.meta, style: AppText.meta()),
                ],
              ),
            ),
            Text('${entry.kcal}', style: AppText.mealKcal()),
          ],
        ),
      ),
    );
  }
}

class _AddMealLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddMealLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.brandBlue,
          ),
        ),
      ),
    );
  }
}

class _NextWorkoutLine extends StatelessWidget {
  final String workout;
  const _NextWorkoutLine({required this.workout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Text(
          AppL10n.of(context).nextWorkout(workout),
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

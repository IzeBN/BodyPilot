import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'ai_meal_sheet.dart';

/// Bottom sheet shown when the centre "+" tab is tapped.
/// 4 options per the design spec: Еда (AI), Тренировка, Вода, Вес.
class AddSheet extends StatelessWidget {
  const AddSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final bottom = MediaQuery.of(context).padding.bottom;

    final options = [
      _Option(
        gradient: const LinearGradient(
          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        emoji: '🍽️',
        name: l.addSheetFood,
        desc: l.addSheetFoodDesc,
        onTap: () {
          final today = DateTime.now().toIso8601String().substring(0, 10);
          Navigator.of(context, rootNavigator: true).pop();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            useRootNavigator: true,
            builder: (_) => AiMealSheet(date: today),
          );
        },
      ),
      _Option(
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFF43F5E)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        emoji: '🏋️',
        name: l.addSheetWorkout,
        desc: l.addSheetWorkoutDesc,
        onTap: () {
          Navigator.of(context).pop();
          context.push('/training/programs');
        },
      ),
      _Option(
        gradient: const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF0284C7)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        emoji: '💧',
        name: l.addSheetWater,
        desc: l.addSheetWaterDesc,
        onTap: () {
          Navigator.of(context).pop();
          _showWaterDialog(context, l);
        },
      ),
      _Option(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        emoji: '⚖️',
        name: l.addSheetWeight,
        desc: l.addSheetWeightDesc,
        onTap: () {
          Navigator.of(context).pop();
          _showWeightDialog(context, l);
        },
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.borderStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ...options.map((o) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _OptionTile(option: o),
          )),
        ],
      ),
    );
  }

  void _showWaterDialog(BuildContext context, AppL10n l) {
    final ctrl = TextEditingController(text: '250');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.dialogAddWater),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(suffix: Text(l.unitMl)),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(
            onPressed: () { Navigator.pop(ctx); },
            child: Text(l.saveMeal),
          ),
        ],
      ),
    );
  }

  void _showWeightDialog(BuildContext context, AppL10n l) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.dialogRecordWeight),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(suffix: Text(l.unitKg)),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(
            onPressed: () { Navigator.pop(ctx); },
            child: Text(l.saveMeal),
          ),
        ],
      ),
    );
  }
}

class _Option {
  final LinearGradient gradient;
  final String emoji;
  final String name;
  final String desc;
  final VoidCallback onTap;
  const _Option({
    required this.gradient, required this.emoji,
    required this.name, required this.desc, required this.onTap,
  });
}

class _OptionTile extends StatefulWidget {
  final _Option option;
  const _OptionTile({super.key, required this.option});

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.option;
    return ScaleTransition(
      scale: _press,
      child: GestureDetector(
        onTapDown: (_) => _press.reverse(),
        onTapUp: (_) { _press.forward(); HapticFeedback.selectionClick(); o.onTap(); },
        onTapCancel: () => _press.forward(),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: o.gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(o.emoji, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.name, style: AppText.bodyName()),
                    Text(o.desc, style: AppText.meta()),
                  ],
                ),
              ),
              Text('›', style: AppText.meta(color: AppColors.textMuted).copyWith(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}

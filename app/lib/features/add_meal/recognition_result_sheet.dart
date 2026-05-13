import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../journal/providers/journal_provider.dart';

/// Bottom sheet shown after AI recognition (text / photo / voice / barcode).
/// Displays recognised items with editable weights and a macro donut summary.
/// Backend sends per-portion values (for weight_grams); we store per-100g internally.
class RecognitionResultSheet extends ConsumerStatefulWidget {
  final String date;
  final List<Map<String, dynamic>> items;
  final String dishName;

  const RecognitionResultSheet({
    super.key,
    required this.date,
    required this.items,
    required this.dishName,
  });

  @override
  ConsumerState<RecognitionResultSheet> createState() => _RecognitionResultSheetState();
}

class _RecognitionResultSheetState extends ConsumerState<RecognitionResultSheet>
    with SingleTickerProviderStateMixin {
  late final List<_RecItem> _items;
  String _mealType = _inferMealType();
  bool _saving = false;

  static String _inferMealType() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'breakfast';
    if (hour < 15) return 'lunch';
    if (hour < 18) return 'snack';
    return 'dinner';
  }

  @override
  void initState() {
    super.initState();
    _items = widget.items.map((raw) {
      final weight = (raw['weight_grams'] as num?)?.toDouble() ?? 100.0;
      // Backend sends per-portion calories/protein/fat/carbs for weight_grams.
      // Prefer *_per_100g if present (barcode path), otherwise compute from portion.
      double per100(String per100Key, String portionKey) {
        final p100 = (raw[per100Key] as num?)?.toDouble();
        if (p100 != null) return p100;
        final portion = (raw[portionKey] as num?)?.toDouble() ?? 0.0;
        return weight > 0 ? portion * 100.0 / weight : 0.0;
      }
      return _RecItem(
        name: raw['name'] as String? ?? '',
        weightCtrl: TextEditingController(text: weight.toStringAsFixed(0)),
        kcalPer100: per100('calories_per_100g', 'calories'),
        proteinPer100: per100('protein_per_100g', 'protein'),
        fatPer100: per100('fat_per_100g', 'fat'),
        carbsPer100: per100('carbs_per_100g', 'carbs'),
        selected: true,
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final i in _items) i.weightCtrl.dispose();
    super.dispose();
  }

  double _val(double per100, TextEditingController ctrl) {
    final w = double.tryParse(ctrl.text) ?? 100.0;
    return per100 * w / 100.0;
  }

  ({double kcal, double protein, double fat, double carbs}) get _totals {
    double kcal = 0, pro = 0, fat = 0, carbs = 0;
    for (final item in _items) {
      if (!item.selected) continue;
      kcal += _val(item.kcalPer100, item.weightCtrl);
      pro += _val(item.proteinPer100, item.weightCtrl);
      fat += _val(item.fatPer100, item.weightCtrl);
      carbs += _val(item.carbsPer100, item.weightCtrl);
    }
    return (kcal: kcal, protein: pro, fat: fat, carbs: carbs);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      for (final item in _items) {
        if (!item.selected) continue;
        final weight = double.tryParse(item.weightCtrl.text) ?? 100.0;
        await apiDio.post('/api/v1/nutrition/meals', data: {
          'log_date': widget.date,
          'meal_type': _mealType,
          'food_name': item.name,
          'amount_g': weight,
          'calories': _val(item.kcalPer100, item.weightCtrl),
          'protein': _val(item.proteinPer100, item.weightCtrl),
          'fat': _val(item.fatPer100, item.weightCtrl),
          'carbs': _val(item.carbsPer100, item.weightCtrl),
        });
      }
      ref.invalidate(journalDayProvider(widget.date));
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppL10n.of(context).saveError), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final t = _totals;
    final selectedCount = _items.where((i) => i.selected).length;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            decoration: BoxDecoration(color: AppColors.borderStrong, borderRadius: BorderRadius.circular(2)),
          ),
          // Dish name + close
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.dishName.isNotEmpty ? widget.dishName : l.addFoodTitle,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary, letterSpacing: -0.3),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),

          // Macro summary card
          _MacroSummaryCard(totals: t, l: l),

          // Meal type
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: _MealTypePicker(
              selected: _mealType,
              onChanged: (t) => setState(() => _mealType = t),
              l: l,
            ),
          ),

          // Recognized header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: Row(
              children: [
                Text(
                  l.recognizedCount(_items.length),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: AppColors.textMuted, letterSpacing: 0.8),
                ),
              ],
            ),
          ),

          // Items list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              itemCount: _items.length,
              itemBuilder: (_, i) => _ItemRow(
                item: _items[i],
                kcalForWeight: _val(_items[i].kcalPer100, _items[i].weightCtrl),
                onToggle: () { HapticFeedback.selectionClick(); setState(() => _items[i].selected = !_items[i].selected); },
                onWeightChanged: () => setState(() {}),
                l: l,
              ),
            ),
          ),

          // Save CTA
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 20),
            child: _SaveButton(
              saving: _saving,
              disabled: selectedCount == 0,
              totalKcal: t.kcal,
              onSave: _save,
              l: l,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Macro summary card: donut + macro pills
// ─────────────────────────────────────────────────────────────────────────────

class _MacroSummaryCard extends StatelessWidget {
  final ({double kcal, double protein, double fat, double carbs}) totals;
  final AppL10n l;
  const _MacroSummaryCard({required this.totals, required this.l});

  @override
  Widget build(BuildContext context) {
    final pro = totals.protein;
    final fat = totals.fat;
    final carbs = totals.carbs;
    final macroTotal = pro + fat + carbs;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Donut chart
          SizedBox(
            width: 72, height: 72,
            child: CustomPaint(
              painter: _DonutPainter(
                protein: pro,
                fat: fat,
                carbs: carbs,
                total: macroTotal,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      totals.kcal.round().toString(),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary, letterSpacing: -0.5),
                    ),
                    Text(
                      l.unitKcal,
                      style: const TextStyle(fontSize: 8, color: AppColors.textMuted,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Macro pills
          Expanded(
            child: Column(
              children: [
                _MacroPill(label: l.macroProtein, value: '${pro.round()}${l.unitG}',
                    color: AppColors.protein, fraction: macroTotal > 0 ? pro / macroTotal : 0),
                const SizedBox(height: 5),
                _MacroPill(label: l.macroFat, value: '${fat.round()}${l.unitG}',
                    color: AppColors.fat, fraction: macroTotal > 0 ? fat / macroTotal : 0),
                const SizedBox(height: 5),
                _MacroPill(label: l.macroCarbs, value: '${carbs.round()}${l.unitG}',
                    color: AppColors.carbs, fraction: macroTotal > 0 ? carbs / macroTotal : 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double protein;
  final double fat;
  final double carbs;
  final double total;

  const _DonutPainter({required this.protein, required this.fat,
      required this.carbs, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = math.min(cx, cy) - 2;
    final innerR = outerR * 0.58;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: outerR);

    if (total <= 0) {
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false,
          Paint()..color = AppColors.borderStrong..style = PaintingStyle.stroke
            ..strokeWidth = outerR - innerR);
      return;
    }

    final segments = [
      (protein / total, AppColors.protein),
      (fat / total, AppColors.fat),
      (carbs / total, AppColors.carbs),
    ];

    double startAngle = -math.pi / 2;
    const gap = 0.04;

    for (final (fraction, color) in segments) {
      final sweep = fraction * math.pi * 2 - gap;
      if (sweep > 0) {
        canvas.drawArc(rect, startAngle + gap / 2, sweep, false,
            Paint()..color = color..style = PaintingStyle.stroke
              ..strokeWidth = outerR - innerR..strokeCap = StrokeCap.round);
      }
      startAngle += fraction * math.pi * 2;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.protein != protein || old.fat != fat || old.carbs != carbs;
}

class _MacroPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double fraction;
  const _MacroPill({required this.label, required this.value,
      required this.color, required this.fraction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 7, height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted,
            fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meal type picker
// ─────────────────────────────────────────────────────────────────────────────

class _MealTypePicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final AppL10n l;
  const _MealTypePicker({required this.selected, required this.onChanged, required this.l});

  @override
  Widget build(BuildContext context) {
    final types = [
      ('breakfast', l.mealTypeBreakfast),
      ('lunch', l.mealTypeLunch),
      ('dinner', l.mealTypeDinner),
      ('snack', l.mealTypeSnack),
    ];
    return Wrap(
      spacing: 8, runSpacing: 6,
      children: types.map((t) {
        final sel = selected == t.$1;
        return GestureDetector(
          onTap: () => onChanged(t.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: sel ? AppColors.brandBlue : AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: sel ? AppColors.brandBlue : AppColors.borderStrong, width: 1.5),
            ),
            child: Text(t.$2,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : AppColors.textSecondary)),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item row with checkbox
// ─────────────────────────────────────────────────────────────────────────────

class _RecItem {
  final String name;
  final TextEditingController weightCtrl;
  final double kcalPer100;
  final double proteinPer100;
  final double fatPer100;
  final double carbsPer100;
  bool selected;

  _RecItem({
    required this.name,
    required this.weightCtrl,
    required this.kcalPer100,
    required this.proteinPer100,
    required this.fatPer100,
    required this.carbsPer100,
    this.selected = true,
  });
}

class _ItemRow extends StatelessWidget {
  final _RecItem item;
  final double kcalForWeight;
  final VoidCallback onToggle;
  final VoidCallback onWeightChanged;
  final AppL10n l;

  const _ItemRow({
    required this.item,
    required this.kcalForWeight,
    required this.onToggle,
    required this.onWeightChanged,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final weight = double.tryParse(item.weightCtrl.text) ?? 100.0;
    final protein = (item.proteinPer100 * weight / 100).round();
    final fat = (item.fatPer100 * weight / 100).round();
    final carbs = (item.carbsPer100 * weight / 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: item.selected ? AppColors.surfaceSoft : AppColors.surfaceTint.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.selected ? AppColors.borderStrong : AppColors.borderStrong.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: item.selected ? const Color(0xFF059669) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: item.selected ? const Color(0xFF059669) : AppColors.borderStrong,
                  width: 2,
                ),
              ),
              child: item.selected
                  ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          // Name + macros
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: item.selected ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  '${kcalForWeight.round()} ${l.unitKcal}  ·  '
                  '${l.macroProtein} ${protein}${l.unitG}  '
                  '${l.macroFat} ${fat}${l.unitG}  '
                  '${l.macroCarbs} ${carbs}${l.unitG}',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Weight field
          SizedBox(
            width: 64,
            child: TextField(
              controller: item.weightCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => onWeightChanged(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
              decoration: InputDecoration(
                suffix: Text(l.unitG,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                filled: true, fillColor: AppColors.surfaceTint,
                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.borderStrong)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Save button
// ─────────────────────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool saving;
  final bool disabled;
  final double totalKcal;
  final VoidCallback onSave;
  final AppL10n l;

  const _SaveButton({
    required this.saving,
    required this.disabled,
    required this.totalKcal,
    required this.onSave,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final active = !saving && !disabled;
    return SizedBox(
      width: double.infinity, height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF16A34A)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight)
              : LinearGradient(colors: [
                  AppColors.borderStrong.withValues(alpha: 0.8),
                  AppColors.borderStrong.withValues(alpha: 0.8),
                ]),
          borderRadius: BorderRadius.circular(AppRadius.button),
          boxShadow: active
              ? [BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.3),
                    blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: InkWell(
            onTap: active ? onSave : null,
            borderRadius: BorderRadius.circular(AppRadius.button),
            child: Center(
              child: saving
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${l.saveMeal}  ·  ${totalKcal.round()} ${l.unitKcal}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

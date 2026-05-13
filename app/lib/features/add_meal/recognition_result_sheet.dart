import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../journal/providers/journal_provider.dart';

/// Bottom sheet shown after AI recognition.
/// Displays recognised items with editable weights; user can confirm to save.
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

class _RecognitionResultSheetState extends ConsumerState<RecognitionResultSheet> {
  late final List<_RecItem> _items;
  String _mealType = 'lunch';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _items = widget.items.map((raw) {
      final weight = (raw['weight_grams'] as num?)?.toDouble() ?? 100.0;
      return _RecItem(
        name: raw['name'] as String? ?? '',
        weightCtrl: TextEditingController(text: weight.toStringAsFixed(0)),
        kcalPer100: (raw['calories_per_100g'] as num?)?.toDouble() ?? (raw['calories'] as num?)?.toDouble() ?? 0.0,
        proteinPer100: (raw['protein_per_100g'] as num?)?.toDouble() ?? (raw['protein'] as num?)?.toDouble() ?? 0.0,
        fatPer100: (raw['fat_per_100g'] as num?)?.toDouble() ?? (raw['fat'] as num?)?.toDouble() ?? 0.0,
        carbsPer100: (raw['carbs_per_100g'] as num?)?.toDouble() ?? (raw['carbs'] as num?)?.toDouble() ?? 0.0,
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

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      for (final item in _items) {
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
    final types = [
      ('breakfast', l.mealTypeBreakfast),
      ('lunch', l.mealTypeLunch),
      ('dinner', l.mealTypeDinner),
      ('snack', l.mealTypeSnack),
    ];

    // Total per current weights
    double totalKcal = 0, totalP = 0, totalF = 0, totalC = 0;
    for (final item in _items) {
      totalKcal += _val(item.kcalPer100, item.weightCtrl);
      totalP += _val(item.proteinPer100, item.weightCtrl);
      totalF += _val(item.fatPer100, item.weightCtrl);
      totalC += _val(item.carbsPer100, item.weightCtrl);
    }

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
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(color: AppColors.borderStrong, borderRadius: BorderRadius.circular(2)),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Color(0xFF059669), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.dishName.isNotEmpty ? widget.dishName : 'AI распознал',
                    style: AppText.sectionHead(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Totals summary
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TotalChip(label: l.unitKcal, value: totalKcal.round().toString(), color: AppColors.calories),
                _TotalChip(label: l.macroProtein, value: '${totalP.round()}${l.unitG}', color: AppColors.protein),
                _TotalChip(label: l.macroFat, value: '${totalF.round()}${l.unitG}', color: AppColors.fat),
                _TotalChip(label: l.macroCarbs, value: '${totalC.round()}${l.unitG}', color: AppColors.carbs),
              ],
            ),
          ),
          // Meal type
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: types.map((t) {
                final sel = _mealType == t.$1;
                return GestureDetector(
                  onTap: () => setState(() => _mealType = t.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.brandBlue : AppColors.surfaceTint,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: sel ? AppColors.brandBlue : AppColors.borderStrong, width: 1.5),
                    ),
                    child: Text(t.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.textSecondary)),
                  ),
                );
              }).toList(),
            ),
          ),
          // Items list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              itemCount: _items.length,
              itemBuilder: (_, i) => _ItemRow(item: _items[i], onChanged: () => setState(() {})),
            ),
          ),
          // Save button
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
            child: SizedBox(
              width: double.infinity, height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF16A34A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  boxShadow: [BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 4))],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  child: InkWell(
                    onTap: _saving ? null : _save,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    child: Center(
                      child: _saving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(l.saveMeal, style: AppText.btn()),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecItem {
  final String name;
  final TextEditingController weightCtrl;
  final double kcalPer100;
  final double proteinPer100;
  final double fatPer100;
  final double carbsPer100;

  _RecItem({
    required this.name,
    required this.weightCtrl,
    required this.kcalPer100,
    required this.proteinPer100,
    required this.fatPer100,
    required this.carbsPer100,
  });
}

class _TotalChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _TotalChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppText.heroKcal(color: color).copyWith(fontSize: 16)),
        Text(label, style: AppText.meta()),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  final _RecItem item;
  final VoidCallback onChanged;
  const _ItemRow({required this.item, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final weight = double.tryParse(item.weightCtrl.text) ?? 100.0;
    final kcal = (item.kcalPer100 * weight / 100).round();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppText.bodyName()),
                const SizedBox(height: 4),
                Text('$kcal ${AppL10n.of(context).unitKcal}', style: AppText.meta()),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: TextField(
              controller: item.weightCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => onChanged(),
              textAlign: TextAlign.center,
              style: AppText.counter(),
              decoration: InputDecoration(
                suffix: Text(AppL10n.of(context).unitG, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                filled: true, fillColor: AppColors.surfaceTint,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

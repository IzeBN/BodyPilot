import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';
import '../providers/journal_provider.dart';

class AddMealScreen extends ConsumerStatefulWidget {
  final String date;
  const AddMealScreen({super.key, required this.date});

  @override
  ConsumerState<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends ConsumerState<AddMealScreen> {
  final _foodCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();

  String _mealType = 'breakfast';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _foodCtrl.dispose();
    _amountCtrl.dispose();
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _fatCtrl.dispose();
    _carbsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppL10n.of(context);
    final food = _foodCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    final cal = double.tryParse(_calCtrl.text.trim());

    if (food.isEmpty || amount == null || cal == null) {
      setState(() => _error = AppL10n.of(context).fillFoodFields);
      return;
    }

    setState(() { _saving = true; _error = null; });
    try {
      await apiDio.post('/api/v1/nutrition/meals', data: {
        'log_date': widget.date,
        'meal_type': _mealType,
        'food_name': food,
        'amount_g': amount,
        'calories': cal,
        if (_proteinCtrl.text.trim().isNotEmpty)
          'protein': double.tryParse(_proteinCtrl.text.trim()),
        if (_fatCtrl.text.trim().isNotEmpty)
          'fat': double.tryParse(_fatCtrl.text.trim()),
        if (_carbsCtrl.text.trim().isNotEmpty)
          'carbs': double.tryParse(_carbsCtrl.text.trim()),
      });
      ref.invalidate(journalDayProvider(widget.date));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.mealSaved), duration: const Duration(seconds: 2)),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) setState(() { _saving = false; _error = AppL10n.of(context).saveError; });
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

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(AppRadius.appBarAction),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary),
          ),
        ),
        title: Text(l.addMealTitle, style: AppText.sectionHead()),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meal type chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: types.map((t) {
                  final selected = _mealType == t.$1;
                  return GestureDetector(
                    onTap: () => setState(() => _mealType = t.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.brandBlue : AppColors.surfaceTint,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected ? AppColors.brandBlue : AppColors.borderStrong,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        t.$2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Food name
              _FieldLabel(l.foodNameLabel),
              const SizedBox(height: 6),
              _TextField(controller: _foodCtrl, hint: l.foodNameHint, keyboardType: TextInputType.text),
              const SizedBox(height: 16),

              // Amount + Calories row
              Row(
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(l.amountLabel),
                      const SizedBox(height: 6),
                      _TextField(controller: _amountCtrl, hint: '200', keyboardType: TextInputType.number),
                    ],
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(l.caloriesFieldLabel),
                      const SizedBox(height: 6),
                      _TextField(controller: _calCtrl, hint: '240', keyboardType: TextInputType.number),
                    ],
                  )),
                ],
              ),
              const SizedBox(height: 16),

              // Macros row
              Row(
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(l.proteinLabel),
                      const SizedBox(height: 6),
                      _TextField(controller: _proteinCtrl, hint: '20', keyboardType: TextInputType.number),
                    ],
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(l.fatLabel),
                      const SizedBox(height: 6),
                      _TextField(controller: _fatCtrl, hint: '5', keyboardType: TextInputType.number),
                    ],
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(l.carbsLabel),
                      const SizedBox(height: 6),
                      _TextField(controller: _carbsCtrl, hint: '35', keyboardType: TextInputType.number),
                    ],
                  )),
                ],
              ),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.error)),
              ],

              const SizedBox(height: 28),
              AppButton(
                label: l.saveMeal,
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textHint, letterSpacing: 0.5),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  const _TextField({required this.controller, required this.hint, required this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
        filled: true,
        fillColor: AppColors.surfaceTint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderStrong, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandBlue, width: 1.5),
        ),
      ),
    );
  }
}

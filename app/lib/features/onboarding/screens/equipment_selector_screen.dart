import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';
import '../../equipment/providers/equipment_provider.dart';

class EquipmentSelectorScreen extends ConsumerStatefulWidget {
  const EquipmentSelectorScreen({super.key});

  @override
  ConsumerState<EquipmentSelectorScreen> createState() => _EquipmentSelectorScreenState();
}

class _EquipmentSelectorScreenState extends ConsumerState<EquipmentSelectorScreen> {
  // itemId → selected
  final Map<int, bool> _picked = {};
  bool _saving = false;

  Future<void> _save(List<EquipmentItem> allItems) async {
    setState(() => _saving = true);
    try {
      final selected = allItems.where((e) => _picked[e.id] ?? e.selected).toList();
      for (final e in allItems) {
        e.selected = _picked[e.id] ?? e.selected;
      }
      await saveUserEquipment(selected);
    } catch (_) {}
    if (mounted) {
      setState(() => _saving = false);
      context.go('/journal');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final catalogAsync = ref.watch(equipmentCatalogProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: catalogAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Text(l.obEquipTitle, style: AppText.onboardingH1()),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                child: AppButton(
                  label: l.continueButton,
                  onPressed: () => context.go('/journal'),
                ),
              ),
            ],
          ),
          data: (items) {
            if (_picked.isEmpty) {
              for (final item in items) {
                _picked[item.id] = item.selected;
              }
            }
            final count = _picked.values.where((v) => v).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 56),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceTint,
                            borderRadius: BorderRadius.circular(AppRadius.appBarAction),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _OnboardingProgress(activeCount: 3, total: 4)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Text(l.obEquipTitle, style: AppText.onboardingH1()),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Text(l.obEquipSubtitle, style: AppText.meta12(color: AppColors.textHint)),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: items.map((item) {
                      final on = _picked[item.id] ?? item.selected;
                      return _EqChip(
                        emoji: _emojiForName(item.name),
                        label: item.name,
                        selected: on,
                        onTap: () => setState(() => _picked[item.id] = !on),
                      );
                    }).toList(),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlueSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.brandBlueBorder),
                    ),
                    child: Text(
                      l.obEquipBanner(count, count * 12),
                      style: const TextStyle(fontSize: 13, color: AppColors.brandBlueDeep, height: 1.5),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                  child: AppButton(
                    label: l.continueButton,
                    loading: _saving,
                    onPressed: _saving ? null : () => _save(items),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _emojiForName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('гант')) return '🏋️';
  if (lower.contains('штанг')) return '⚡';
  if (lower.contains('турн')) return '🔝';
  if (lower.contains('скам') || lower.contains('лавк')) return '🪑';
  if (lower.contains('тренаж')) return '🏭';
  if (lower.contains('коврик') || lower.contains('мат')) return '🟩';
  if (lower.contains('резин') || lower.contains('эспандер')) return '🟡';
  return '🏅';
}

class _OnboardingProgress extends StatelessWidget {
  final int activeCount;
  final int total;
  const _OnboardingProgress({required this.activeCount, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            height: 5,
            decoration: BoxDecoration(
              color: i < activeCount ? AppColors.brandBlue : AppColors.borderStrong,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class _EqChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _EqChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandBlue : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.brandBlue : AppColors.borderStrong,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

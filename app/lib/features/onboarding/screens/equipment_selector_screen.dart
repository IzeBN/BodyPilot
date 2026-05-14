import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../equipment/providers/equipment_provider.dart';
import '../providers/onboarding_provider.dart';

// ─── Simple mode — hardcoded preset options ───────────────────────────────────

class _SimpleOpt {
  final String key;
  final IconData icon;
  final List<String> catKeywords;

  const _SimpleOpt({
    required this.key,
    required this.icon,
    required this.catKeywords,
  });
}

const _kSimpleOptions = [
  _SimpleOpt(
    key: 'bodyweight',
    icon: Icons.self_improvement_rounded,
    catKeywords: ['собственный', 'тело', 'bodyweight', 'calisthen', 'без оборудования'],
  ),
  _SimpleOpt(
    key: 'gym',
    icon: Icons.sports_rounded,
    catKeywords: ['тренаж', 'gym', 'machine', 'зал'],
  ),
  _SimpleOpt(
    key: 'dumbbell',
    icon: Icons.fitness_center_rounded,
    catKeywords: ['гант', 'dumbbell', 'свободн'],
  ),
  _SimpleOpt(
    key: 'barbell',
    icon: Icons.sports_gymnastics_rounded,
    catKeywords: ['штанг', 'barbell'],
  ),
  _SimpleOpt(
    key: 'cardio',
    icon: Icons.directions_run_rounded,
    catKeywords: ['кардио', 'cardio', 'беговая', 'велотренаж'],
  ),
  _SimpleOpt(
    key: 'bands',
    icon: Icons.linear_scale_rounded,
    catKeywords: ['резин', 'эспандер', 'band', 'resistance', 'лента'],
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class EquipmentSelectorScreen extends ConsumerStatefulWidget {
  const EquipmentSelectorScreen({super.key});

  @override
  ConsumerState<EquipmentSelectorScreen> createState() =>
      _EquipmentSelectorScreenState();
}

class _EquipmentSelectorScreenState
    extends ConsumerState<EquipmentSelectorScreen> {
  bool _showDetailed = false;
  // 0 = category grid, N = sub-page for categories[N-1]
  int _detailedPage = 0;

  // Simple mode
  final Set<String> _simpleSelected = {};

  // Detailed mode: items without options → item_id → bool
  final Map<int, bool> _pickedItems = {};
  // Detailed mode: items with options → item_id → selected option ids
  final Map<int, Set<int>> _pickedOptions = {};

  bool _saving = false;
  bool _inited = false;

  void _initFromItems(List<EquipmentItem> items) {
    if (_inited) return;
    _inited = true;
    for (final item in items) {
      if (item.hasOptions) {
        _pickedOptions[item.id] = Set.from(item.selectedOptionIds);
      } else {
        _pickedItems[item.id] = item.selected;
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _optName(AppL10n l, String key) {
    switch (key) {
      case 'bodyweight': return l.equipOptBodyweightName;
      case 'gym': return l.equipOptGymName;
      case 'dumbbell': return l.equipOptDumbbellName;
      case 'barbell': return l.equipOptBarbellName;
      case 'cardio': return l.equipOptCardioName;
      case 'bands': return l.equipOptBandsName;
      default: return key;
    }
  }

  String _optDesc(AppL10n l, String key) {
    switch (key) {
      case 'bodyweight': return l.equipOptBodyweightDesc;
      case 'gym': return l.equipOptGymDesc;
      case 'dumbbell': return l.equipOptDumbbellDesc;
      case 'barbell': return l.equipOptBarbellDesc;
      case 'cardio': return l.equipOptCardioDesc;
      case 'bands': return l.equipOptBandsDesc;
      default: return '';
    }
  }

  List<EquipmentItem> _itemsForSimpleOpt(
      _SimpleOpt opt, List<EquipmentItem> allItems) {
    return allItems.where((item) {
      final lower =
          '${item.categoryName.toLowerCase()} ${item.name.toLowerCase()}';
      return opt.catKeywords.any((kw) => lower.contains(kw));
    }).toList();
  }

  bool _isItemSelected(EquipmentItem item) {
    if (item.hasOptions) {
      return (_pickedOptions[item.id]?.isNotEmpty) ?? false;
    }
    return _pickedItems[item.id] ?? false;
  }

  int _selectedCountInCategory(EquipmentCategory cat) {
    return cat.items.where(_isItemSelected).length;
  }

  // ── Toggles ───────────────────────────────────────────────────────────────

  void _toggleItem(EquipmentItem item, List<EquipmentItem> allItems) {
    setState(() {
      _pickedItems[item.id] = !(_pickedItems[item.id] ?? false);
    });
    _putPicked(allItems);
  }

  void _toggleOption(
      EquipmentItem item, int optionId, List<EquipmentItem> allItems) {
    setState(() {
      final set = _pickedOptions.putIfAbsent(item.id, () => {});
      if (set.contains(optionId)) {
        set.remove(optionId);
      } else {
        set.add(optionId);
      }
    });
    _putPicked(allItems);
  }

  Future<void> _putPicked(List<EquipmentItem> allItems) async {
    try {
      await saveUserEquipment(allItems, _pickedItems, _pickedOptions);
    } catch (_) {}
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _skip() async {
    await ref.read(equipmentSetupDoneProvider.notifier).markDone();
    if (mounted) context.go('/journal');
  }

  Future<void> _continue(List<EquipmentItem> allItems) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (!_showDetailed) {
        // Map simple selections → API items
        final matchedItems = <EquipmentItem>[];
        for (final key in _simpleSelected) {
          final opt =
              _kSimpleOptions.firstWhere((o) => o.key == key);
          matchedItems.addAll(_itemsForSimpleOpt(opt, allItems));
        }
        // For simple mode, select all items (without options) and all options for opt items
        final simplePickedItems = <int, bool>{};
        final simplePickedOptions = <int, Set<int>>{};
        for (final item in matchedItems) {
          if (item.hasOptions) {
            simplePickedOptions[item.id] =
                item.options.map((o) => o.id).toSet();
          } else {
            simplePickedItems[item.id] = true;
          }
        }
        await saveUserEquipment(allItems, simplePickedItems, simplePickedOptions);
      } else {
        await saveUserEquipment(allItems, _pickedItems, _pickedOptions);
      }

      await ref.read(equipmentSetupDoneProvider.notifier).markDone();

      // Adaptive program generation
      String? taskId;
      try {
        final resp = await apiDio.post('/api/v1/training/programs/generate');
        final data = resp.data;
        if (data is Map) taskId = data['task_id']?.toString();
      } catch (_) {}

      if (mounted) {
        context.go('/training/generating', extra: taskId);
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(equipmentCatalogProvider);
    final catAsync = ref.watch(equipmentCategoriesProvider);
    final l = AppL10n.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(l, catAsync.valueOrNull),
      body: Column(
        children: [
          Expanded(
            child: catalogAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildSimpleBody([], l),
              data: (items) {
                final cats = catAsync.valueOrNull ?? [];
                _initFromItems(items);
                return _showDetailed
                    ? _buildDetailedBody(cats, items, l)
                    : _buildSimpleBody(items, l);
              },
            ),
          ),
          _buildBottom(catalogAsync.valueOrNull ?? [], l),
        ],
      ),
    );
  }

  AppBar _buildAppBar(AppL10n l, List<EquipmentCategory>? cats) {
    String title = l.equipScreenTitle;
    if (_showDetailed && _detailedPage > 0 && cats != null) {
      final cat = cats.elementAtOrNull(_detailedPage - 1);
      if (cat != null) title = cat.name;
    }

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: _showDetailed
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: AppColors.textPrimary),
              onPressed: () {
                if (_detailedPage > 0) {
                  setState(() => _detailedPage = 0);
                } else {
                  setState(() => _showDetailed = false);
                }
              },
            )
          : IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
      title: Text(title, style: AppText.appBarTitle()),
    );
  }

  // ── Simple body ───────────────────────────────────────────────────────────

  Widget _buildSimpleBody(List<EquipmentItem> allItems, AppL10n l) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Text(
          l.equipSimpleTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l.equipSimpleSubtitle,
          style: const TextStyle(
              fontSize: 14, color: AppColors.textMuted, height: 1.5),
        ),
        const SizedBox(height: 16),
        ..._kSimpleOptions.map((opt) => _buildSimpleTile(opt, l)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() {
            _showDetailed = true;
            _detailedPage = 0;
          }),
          child: Container(
            margin: const EdgeInsets.only(top: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Center(
              child: Text(
                l.equipDetailedBtn,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleTile(_SimpleOpt opt, AppL10n l) {
    final isSelected = _simpleSelected.contains(opt.key);
    return GestureDetector(
      onTap: () => setState(() {
        if (_simpleSelected.contains(opt.key)) {
          _simpleSelected.remove(opt.key);
        } else {
          _simpleSelected.add(opt.key);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandBlue : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.brandBlue : AppColors.borderStrong,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(opt.icon, size: 24,
                  color: isSelected ? Colors.white : AppColors.textSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _optName(l, opt.key),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _optDesc(l, opt.key),
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  // ── Detailed body ─────────────────────────────────────────────────────────

  Widget _buildDetailedBody(
      List<EquipmentCategory> cats, List<EquipmentItem> allItems, AppL10n l) {
    if (_detailedPage == 0) {
      return _buildCategoryGrid(cats, l);
    }
    final cat = cats.elementAtOrNull(_detailedPage - 1);
    if (cat == null) return const SizedBox();
    return _buildSubPage(cat, allItems, l);
  }

  Widget _buildCategoryGrid(List<EquipmentCategory> cats, AppL10n l) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.equipDetailedTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 16,
            alignment: WrapAlignment.spaceAround,
            children: List.generate(cats.length, (i) {
              final cat = cats[i];
              final selectedCount = _selectedCountInCategory(cat);
              return GestureDetector(
                onTap: () => setState(() => _detailedPage = i + 1),
                child: _CategoryCircle(
                  name: cat.name,
                  selectedCount: selectedCount,
                  totalCount: cat.items.length,
                  icon: _iconForCategory(cat.name),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSubPage(
      EquipmentCategory cat, List<EquipmentItem> allItems, AppL10n l) {
    if (cat.items.isEmpty) {
      return Center(
        child: Text(l.equipNoItems,
            style: const TextStyle(color: AppColors.textMuted)),
      );
    }

    // Categories with items that have weight options (dumbbells, barbells, etc.)
    if (cat.hasOptions) {
      return _buildWeightSubPage(cat, allItems, l);
    }

    // Categories with plain items (gym machines, etc.)
    return _buildInventorySubPage(cat, allItems, l);
  }

  /// Sub-page for categories where items have weight options (гантели, штанга)
  Widget _buildWeightSubPage(
      EquipmentCategory cat, List<EquipmentItem> allItems, AppL10n l) {
    final itemWidth = (MediaQuery.of(context).size.width - 40) / 3;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.equipWeightsTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...cat.items.map((item) {
            if (!item.hasOptions) return const SizedBox();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cat.items.length > 1) ...[
                  Text(item.name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                ],
                Wrap(
                  spacing: 0,
                  runSpacing: 0,
                  children: item.options.map((opt) {
                    final isActive =
                        _pickedOptions[item.id]?.contains(opt.id) ?? false;
                    return GestureDetector(
                      onTap: () =>
                          _toggleOption(item, opt.id, allItems),
                      child: SizedBox(
                        width: itemWidth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _WeightCircle(
                                  label: opt.name, isActive: isActive),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (cat.items.length > 1) const SizedBox(height: 12),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Sub-page for categories where items have no weight options (тренажёры, etc.)
  Widget _buildInventorySubPage(
      EquipmentCategory cat, List<EquipmentItem> allItems, AppL10n l) {
    final itemWidth = (MediaQuery.of(context).size.width - 40) / 3;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.equipDetailedTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 0,
            runSpacing: 0,
            children: cat.items.map((item) {
              final isActive = _pickedItems[item.id] ?? false;
              return GestureDetector(
                onTap: () => _toggleItem(item, allItems),
                child: SizedBox(
                  width: itemWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _InventoryCircle(
                            isActive: isActive,
                            icon: _iconForItem(item.name)),
                        const SizedBox(height: 8),
                        Text(
                          item.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Bottom section ────────────────────────────────────────────────────────

  Widget _buildBottom(List<EquipmentItem> allItems, AppL10n l) {
    final hasSelection = _showDetailed
        ? (_pickedItems.values.any((v) => v) ||
            _pickedOptions.values.any((s) => s.isNotEmpty))
        : _simpleSelected.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        border: Border(
            top: BorderSide(color: AppColors.borderStrong, width: 0.5)),
        color: AppColors.surface,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : () => _continue(allItems),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.brandBlue.withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      hasSelection ? l.continueButton : l.equipStartWithout,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _saving ? null : _skip,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                l.skipButton,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (_showDetailed && _detailedPage > 0) ...[
            const SizedBox(height: 4),
            Text(
              l.equipAutoSave,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _CategoryCircle extends StatelessWidget {
  final String name;
  final int selectedCount;
  final int totalCount;
  final IconData icon;

  const _CategoryCircle({
    required this.name,
    required this.selectedCount,
    required this.totalCount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasSelection
                ? AppColors.brandBlueSoft
                : AppColors.surfaceTint,
            border: Border.all(
              color: hasSelection
                  ? AppColors.brandBlue
                  : AppColors.borderStrong,
              width: hasSelection ? 2.5 : 1.5,
            ),
          ),
          child: Icon(icon, size: 40,
              color: hasSelection
                  ? AppColors.brandBlue
                  : AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 120,
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (hasSelection)
          Text(
            '$selectedCount/$totalCount',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.brandBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _InventoryCircle extends StatelessWidget {
  final bool isActive;
  final IconData icon;

  const _InventoryCircle({required this.isActive, required this.icon});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: isActive ? AppColors.brandBlue : const Color(0xFFE6E9ED),
          width: 3,
        ),
      ),
      child: Icon(icon, size: 36,
          color: isActive ? AppColors.brandBlue : AppColors.textMuted),
    );
  }
}

/// Circle showing a weight label (e.g. "5 кг"), for items with options.
class _WeightCircle extends StatelessWidget {
  final String label;
  final bool isActive;

  const _WeightCircle({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppColors.brandBlueSoft : Colors.white,
        border: Border.all(
          color: isActive ? AppColors.brandBlue : const Color(0xFFE6E9ED),
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColors.brandBlue : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Icon helpers ─────────────────────────────────────────────────────────────

IconData _iconForCategory(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('гант') || lower.contains('dumbbell')) return Icons.fitness_center;
  if (lower.contains('штанг') || lower.contains('barbell')) return Icons.sports_gymnastics;
  if (lower.contains('кардио') || lower.contains('беговая') || lower.contains('cardio')) return Icons.directions_run;
  if (lower.contains('тренаж') || lower.contains('machine')) return Icons.sports;
  if (lower.contains('коврик') || lower.contains('йога') || lower.contains('yoga')) return Icons.self_improvement;
  if (lower.contains('резин') || lower.contains('эспандер') || lower.contains('band')) return Icons.linear_scale_rounded;
  if (lower.contains('турник') || lower.contains('pull')) return Icons.airline_seat_flat;
  if (lower.contains('скамь') || lower.contains('bench')) return Icons.weekend_outlined;
  if (lower.contains('гиря') || lower.contains('kettlebell')) return Icons.sports_martial_arts;
  if (lower.contains('собственн') || lower.contains('bodyweight')) return Icons.self_improvement_rounded;
  return Icons.sports_handball;
}

IconData _iconForItem(String name) => _iconForCategory(name);

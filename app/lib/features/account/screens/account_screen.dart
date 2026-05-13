import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../equipment/providers/equipment_provider.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  // itemId → selected (overrides from API)
  final Map<int, bool> _equipOverrides = {};

  Future<void> _saveEquipment(List<EquipmentItem> items) async {
    try {
      final toSave = items.where((e) => _equipOverrides[e.id] ?? e.selected).toList();
      await saveUserEquipment(toSave);
      ref.invalidate(equipmentCatalogProvider);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    final equipAsync = ref.watch(equipmentCatalogProvider);

    final profile = profileAsync.valueOrNull;
    final equipItems = equipAsync.valueOrNull ?? [];

    // init overrides from API data
    if (_equipOverrides.isEmpty && equipItems.isNotEmpty) {
      for (final e in equipItems) {
        _equipOverrides[e.id] = e.selected;
      }
    }
    final equipCount = _equipOverrides.isEmpty
        ? equipItems.where((e) => e.selected).length
        : _equipOverrides.values.where((v) => v).length;

    final np = profile?.nutrition;
    final sub = profile?.subscription;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, l),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildProfile(profile, sub, l),
              _buildStatsGrid(l),
              _buildSectionLabel(l.sectionProgram),
              _buildRows([
                _RowData(ic: '🎯', name: l.rowGoal, action: '›'),
                _RowData(
                  ic: '🍽',
                  name: l.rowNutrition,
                  sub: np != null ? '${np.caloriesGoal ?? 0} ${l.unitKcal} · ${np.proteinG ?? 0}/${np.carbsG ?? 0}/${np.fatG ?? 0} ${l.macroProtein}${l.macroFat}${l.macroCarbs}' : null,
                  action: '›',
                ),
                _RowData(ic: '🏋', name: l.rowTrainings, action: '›'),
              ]),
              _buildEquipmentSection(l, equipItems, equipCount),
              _buildSectionLabel(l.sectionLegal),
              _buildRows([
                _RowData(ic: '🤖', name: l.rowAiServices, sub: l.rowAiServicesSub, action: '›'),
                _RowData(ic: '🔒', name: l.rowPrivacy, sub: l.rowPrivacySub, action: '›'),
                _RowData(ic: '📄', name: l.rowPrivacyPolicy, action: '›'),
                _RowData(ic: '📜', name: l.rowTerms, action: '›'),
                _RowData(ic: '✨', name: l.rowAiModels, sub: l.rowAiModelsSub, action: l.rowAiModelsAction),
                _RowData(ic: '📤', name: l.rowExport, action: '›'),
              ]),
              _buildSectionLabel(l.sectionBody),
              _buildRows([
                _RowData(
                  ic: '⚖',
                  name: l.rowWeight,
                  sub: np?.weightKg != null ? '${np!.weightKg} ${l.unitKg}' : null,
                  action: np?.weightKg != null ? '${np!.weightKg} ${l.unitKg} ›' : '›',
                ),
                _RowData(
                  ic: '📏',
                  name: l.rowHeight,
                  action: np?.heightCm != null ? '${np!.heightCm} ${l.unitCm} ›' : '›',
                ),
                _RowData(ic: '🎂', name: l.rowAge, action: '›'),
              ]),
              _buildSectionLabel(l.sectionApp),
              _buildRows([
                _RowData(ic: '🔔', name: l.rowNotifications, action: '›'),
                _RowData(ic: '🌐', name: l.rowLanguage, action: '›'),
                _RowData(
                  ic: '💳',
                  name: l.rowSubscription,
                  sub: sub != null && sub.isActive ? 'Pro' : null,
                  action: '›',
                ),
                _RowData(ic: '❌', name: l.rowDeleteAccount, action: '›'),
                _RowData(ic: '❓', name: l.rowHelp, action: '›'),
              ]),
              _buildFooter(context, l),
              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, AppL10n l) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(AppRadius.appBarAction),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.accountTitle, style: AppText.appBarTitle()),
          Text(l.accountSubtitle, style: AppText.meta12()),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 22),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(AppRadius.appBarAction),
            ),
            child: const Center(child: Text('⚙', style: TextStyle(fontSize: 16))),
          ),
        ),
      ],
    );
  }

  Widget _buildProfile(UserProfile? profile, Subscription? sub, AppL10n l) {
    final initials = profile?.initials ?? '??';
    final name = profile?.fullname ?? profile?.email ?? '';
    final email = profile?.email ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppGradients.avatar,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Center(
              child: Text(initials,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text(email, style: AppText.meta12(color: AppColors.textHint)),
                if (sub != null && sub.isActive) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l.proLabel(sub.expireShort),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF92400E),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AppL10n l) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 24),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: _StatCell(value: '—', label: l.statsTrainings)),
          Container(width: 1, height: 48, color: AppColors.surface),
          Expanded(child: _StatCell(value: '—', label: l.statsWeeks)),
          Container(width: 1, height: 48, color: AppColors.surface),
          Expanded(child: _StatCell(value: '—', label: l.statsKgLost)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.6,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildRows(List<_RowData> rows) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.surfaceTint, width: 0.5),
        ),
      ),
      child: Column(
        children: rows.map((r) => _SettingsRow(data: r)).toList(),
      ),
    );
  }

  Widget _buildEquipmentSection(AppL10n l, List<EquipmentItem> items, int equipCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l.sectionEquipment,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Text(
                l.equipmentCount(equipCount),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandBlue,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 6),
          child: Text(l.equipmentHint, style: AppText.meta12(color: AppColors.textHint)),
        ),
        if (items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                final on = _equipOverrides[item.id] ?? item.selected;
                return _EqChip(
                  emoji: _emojiForEquipment(item.name),
                  label: item.name,
                  selected: on,
                  onTap: () {
                    setState(() => _equipOverrides[item.id] = !on);
                    _saveEquipment(items);
                  },
                );
              }).toList(),
            ),
          ),
        Container(
          margin: const EdgeInsets.fromLTRB(22, 14, 22, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.brandBlueSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.brandBlueBorder),
          ),
          child: Text(
            l.equipmentBanner(equipCount * 12),
            style: const TextStyle(fontSize: 12, color: AppColors.brandBlueDeep, height: 1.5),
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.fromLTRB(22, 10, 22, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Row(
              children: [
                const Text('⚙', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.equipmentExtended,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
                Text(l.equipmentExtendedSub, style: AppText.meta(color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, AppL10n l) {
    return Column(
      children: [
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => ref.read(authProvider.notifier).logout(),
          child: Text(
            l.logout,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.error),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l.appVersion('2.4.1'),
          style: const TextStyle(fontSize: 11, color: Color(0xFFD1D5DB)),
        ),
      ],
    );
  }

String _emojiForEquipment(String name) {
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
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Column(
        children: [
          Text(value, style: AppText.monoNums()),
          const SizedBox(height: 2),
          Text(label, style: AppText.meta(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _RowData {
  final String ic;
  final String name;
  final String? sub;
  final String? action;
  _RowData({required this.ic, required this.name, this.sub, this.action});
}

class _SettingsRow extends StatelessWidget {
  final _RowData data;
  const _SettingsRow({required this.data});

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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(AppRadius.iconBg),
              ),
              child: Center(child: Text(data.ic, style: const TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.name, style: AppText.bodyName()),
                  if (data.sub != null) ...[
                    const SizedBox(height: 2),
                    Text(data.sub!, style: AppText.meta12(color: AppColors.textMuted)),
                  ],
                ],
              ),
            ),
            if (data.action != null)
              Text(data.action!, style: AppText.meta12(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _EqChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _EqChip({required this.emoji, required this.label, required this.selected, required this.onTap});

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

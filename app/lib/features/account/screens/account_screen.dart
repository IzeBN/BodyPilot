import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../equipment/providers/equipment_provider.dart' show equipmentCatalogProvider;

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    final equipAsync = ref.watch(equipmentCatalogProvider);

    final profile = profileAsync.valueOrNull;
    final equipItems = equipAsync.valueOrNull ?? [];
    final equipCount = equipItems.where((e) => e.selected).length;

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
                _RowData(ic: Icons.flag_rounded, name: l.rowGoal, action: '›'),
                _RowData(
                  ic: Icons.restaurant_rounded,
                  name: l.rowNutrition,
                  sub: np != null ? '${np.caloriesGoal ?? 0} ${l.unitKcal} · ${np.proteinG ?? 0}/${np.carbsG ?? 0}/${np.fatG ?? 0} ${l.macroProtein}${l.macroFat}${l.macroCarbs}' : null,
                  action: '›',
                ),
                _RowData(ic: Icons.fitness_center_rounded, name: l.rowTrainings, action: '›'),
              ]),
              _buildEquipmentSection(l, equipCount),
              _buildSectionLabel(l.sectionLegal),
              _buildRows([
                _RowData(ic: Icons.smart_toy_rounded, name: l.rowAiServices, sub: l.rowAiServicesSub, action: '›'),
                _RowData(ic: Icons.lock_rounded, name: l.rowPrivacy, sub: l.rowPrivacySub, action: '›'),
                _RowData(ic: Icons.description_rounded, name: l.rowPrivacyPolicy, action: '›'),
                _RowData(ic: Icons.article_rounded, name: l.rowTerms, action: '›'),
                _RowData(ic: Icons.auto_awesome_rounded, name: l.rowAiModels, sub: l.rowAiModelsSub, action: l.rowAiModelsAction),
                _RowData(ic: Icons.upload_rounded, name: l.rowExport, action: '›'),
              ]),
              _buildSectionLabel(l.sectionBody),
              _buildRows([
                _RowData(
                  ic: Icons.monitor_weight_rounded,
                  name: l.rowWeight,
                  sub: np?.weightKg != null ? '${np!.weightKg} ${l.unitKg}' : null,
                  action: np?.weightKg != null ? '${np!.weightKg} ${l.unitKg} ›' : '›',
                ),
                _RowData(
                  ic: Icons.straighten_rounded,
                  name: l.rowHeight,
                  action: np?.heightCm != null ? '${np!.heightCm} ${l.unitCm} ›' : '›',
                ),
                _RowData(ic: Icons.cake_rounded, name: l.rowAge, action: '›'),
              ]),
              _buildSectionLabel(l.sectionApp),
              _buildRows([
                _RowData(ic: Icons.notifications_rounded, name: l.rowNotifications, action: '›'),
                _RowData(ic: Icons.language_rounded, name: l.rowLanguage, action: '›'),
                _RowData(
                  ic: Icons.credit_card_rounded,
                  name: l.rowSubscription,
                  sub: sub != null && sub.isActive ? 'Pro' : null,
                  action: '›',
                ),
                _RowData(ic: Icons.delete_outline_rounded, name: l.rowDeleteAccount, action: '›'),
                _RowData(ic: Icons.help_outline_rounded, name: l.rowHelp, action: '›'),
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
            child: const Icon(Icons.settings_rounded, size: 18, color: AppColors.textSecondary),
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

  Widget _buildEquipmentSection(AppL10n l, int equipCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(
          l.sectionEquipment,
          trailing: equipCount > 0
              ? Text(
                  l.equipmentCount(equipCount),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandBlue,
                    letterSpacing: 0.6,
                  ),
                )
              : null,
        ),
        GestureDetector(
          onTap: () => context.push('/onboarding/equipment'),
          child: Container(
            margin: const EdgeInsets.fromLTRB(22, 4, 22, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceTint,
                    borderRadius: BorderRadius.circular(AppRadius.iconBg),
                  ),
                  child: const Icon(Icons.fitness_center_rounded, size: 18, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.equipmentExtended,
                          style: AppText.bodyName()),
                      const SizedBox(height: 2),
                      Text(
                        equipCount > 0 ? l.equipmentBanner(equipCount * 12) : l.obEquipSubtitle,
                        style: AppText.meta12(color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
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
  final IconData ic;
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
              child: Icon(data.ic, size: 18, color: AppColors.textSecondary),
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


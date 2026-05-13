import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';

class ModuleSelectorScreen extends StatefulWidget {
  const ModuleSelectorScreen({super.key});

  @override
  State<ModuleSelectorScreen> createState() => _ModuleSelectorScreenState();
}

class _ModuleSelectorScreenState extends State<ModuleSelectorScreen> {
  bool _nutri = true;
  bool _train = true;

  bool get _ok => _nutri || _train;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 56),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _OnboardingProgress(activeCount: 2, total: 4),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text(l.obModulesTitle, style: AppText.onboardingH1()),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                l.obModulesSubtitle,
                style: AppText.meta12(color: AppColors.textHint),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  _GoalCard(
                    emoji: '🥗',
                    name: l.nutritionModuleName,
                    desc: l.nutritionModuleDesc,
                    selected: _nutri,
                    onTap: () => setState(() => _nutri = !_nutri),
                  ),
                  const SizedBox(height: 12),
                  _GoalCard(
                    emoji: '🏋️',
                    name: l.trainingModuleName,
                    desc: l.trainingModuleDesc,
                    selected: _train,
                    onTap: () => setState(() => _train = !_train),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                      Text(
                        l.obModulesHint,
                        style: AppText.meta12(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(22),
              child: AppButton(
                label: l.continueButton,
                onPressed: _ok ? () => context.go('/onboarding/equipment') : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
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

class _GoalCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String desc;
  final bool selected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.emoji,
    required this.name,
    required this.desc,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandBlueSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: selected ? AppColors.brandBlue : AppColors.borderStrong,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? AppColors.brandBlueBorder : AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppText.bodyName()),
                  const SizedBox(height: 2),
                  Text(desc, style: AppText.meta12(color: AppColors.textHint)),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.brandBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }
}

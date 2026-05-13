import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';

class ProgramItem {
  final String id;
  final String name;
  final String type;
  final int weeks;
  final String category;
  const ProgramItem({required this.id, required this.name, required this.type, required this.weeks, required this.category});
}

final programsProvider = FutureProvider<List<ProgramItem>>((ref) async {
  final resp = await apiDio.get('/api/v1/training/programs');
  final list = resp.data as List? ?? [];
  return list.map((e) {
    final m = e as Map<String, dynamic>;
    return ProgramItem(
      id: m['id']?.toString() ?? '',
      name: m['name'] as String? ?? m['title'] as String? ?? '',
      type: m['sample_type'] as String? ?? '',
      weeks: (m['training_count'] as num?)?.toInt() ?? 8,
      category: m['category'] as String? ?? '',
    );
  }).toList();
});

class ProgramsScreen extends ConsumerWidget {
  const ProgramsScreen({super.key});

  LinearGradient _gradient(int index) {
    const grads = [AppGradients.coral, AppGradients.violet, AppGradients.graph, AppGradients.cyan];
    return grads[index % grads.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPrograms = ref.watch(programsProvider);
    final l = AppL10n.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Программы тренировок', style: AppText.sectionHead()),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surfaceTint, borderRadius: BorderRadius.circular(AppRadius.appBarAction)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary),
          ),
        ),
      ),
      body: asyncPrograms.when(
        data: (programs) => programs.isEmpty
            ? Center(child: Text('Нет доступных программ', style: AppText.meta()))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                itemCount: programs.length,
                itemBuilder: (ctx, i) {
                  final p = programs[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ProgramCard(
                      program: p,
                      gradient: _gradient(i),
                      onSelect: () async {
                        try {
                          await apiDio.post('/api/v1/training/programs/select', data: {'program_id': int.tryParse(p.id) ?? 0});
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Программа "${p.name}" выбрана'), behavior: SnackBarBehavior.floating),
                            );
                            context.pop();
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ошибка выбора программы'), behavior: SnackBarBehavior.floating),
                            );
                          }
                        }
                      },
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l.errorLoading)),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final ProgramItem program;
  final LinearGradient gradient;
  final VoidCallback onSelect;
  const _ProgramCard({required this.program, required this.gradient, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.trainingCard),
        border: Border.all(color: AppColors.borderStrong),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.trainingCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero gradient header
            Container(
              height: 90,
              decoration: BoxDecoration(gradient: gradient),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (program.type.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(999)),
                      child: Text(program.type.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Colors.white)),
                    ),
                  const Spacer(),
                  Text(program.name, style: AppText.cardTitle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  Expanded(child: _Metric(value: '${program.weeks}', label: 'НЕДЕЛЬ')),
                  if (program.category.isNotEmpty)
                    Expanded(child: _Metric(value: program.category, label: 'ТИП')),
                  AppButton(label: 'Выбрать', onPressed: onSelect, small: true, expand: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  const _Metric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppText.monoNums()),
        Text(label, style: AppText.labelCaps()),
      ],
    );
  }
}

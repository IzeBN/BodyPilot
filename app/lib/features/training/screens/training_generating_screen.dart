import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/training_provider.dart' show fullScheduleProvider;

/// Screen shown while the backend asynchronously generates a training program.
/// If [taskId] is null the screen immediately navigates to /journal.
class TrainingGeneratingScreen extends ConsumerStatefulWidget {
  final String? taskId;

  const TrainingGeneratingScreen({super.key, this.taskId});

  @override
  ConsumerState<TrainingGeneratingScreen> createState() =>
      _TrainingGeneratingScreenState();
}

class _TrainingGeneratingScreenState
    extends ConsumerState<TrainingGeneratingScreen> {
  static const _maxAttempts = 36; // 36 × 5 s = 3 min max
  static const _pollInterval = Duration(seconds: 5);

  Timer? _timer;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    if (widget.taskId == null) {
      // Sync generation — schedule already ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _finish();
      });
    } else {
      _poll();
      _timer = Timer.periodic(_pollInterval, (_) => _poll());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    if (!mounted) return;
    _attempts++;

    try {
      final resp =
          await apiDio.get('/api/v1/training/programs/generate/${widget.taskId}/status');
      final data = resp.data as Map<String, dynamic>;
      final status = data['status'] as String?;

      if (status == 'success' || status == 'completed') {
        _finish();
        return;
      }
      if (status == 'error' || status == 'failed') {
        _timer?.cancel();
        if (mounted) context.go('/training/programs');
        return;
      }
    } catch (_) {}

    if (_attempts >= _maxAttempts) {
      _timer?.cancel();
      if (mounted) context.go('/training/programs');
      return;
    }

    if (mounted) setState(() {});
  }

  void _finish() {
    _timer?.cancel();
    // Invalidate schedule cache so journal refreshes
    ref.invalidate(fullScheduleProvider);
    if (mounted) context.go('/journal');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final progress = (_attempts / _maxAttempts).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppGradients.violet,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 52,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),

                Text(
                  l.generatingTitle,
                  style: AppText.sectionHead(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l.generatingSubtitle,
                  style: AppText.meta(color: AppColors.textHint),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: widget.taskId == null ? null : progress,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceTint,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.brandBlue),
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.taskId != null)
                  Text(
                    l.generatingSeconds(((_maxAttempts - _attempts) * _pollInterval.inSeconds).clamp(0, 9999)),
                    style: AppText.meta(color: AppColors.textHint),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/training_provider.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────

const _kGreen = Color(0xFF34C759);
const _kOrange = Color(0xFFFF9500);
const _kGrey = Color(0xFF8E8E93);
const _kText = Color(0xFF1C1C1E);
const _kRed = Color(0xFFFF3B30);

// ─── Models ───────────────────────────────────────────────────────────────────

class _Approach {
  final int number;
  int reps;
  int repMargin;
  double? weight; // null = bodyweight

  _Approach({
    required this.number,
    required this.reps,
    required this.repMargin,
    this.weight,
  });
}

class _ExerciseDetail {
  final int exerciseId;
  final String name;
  final String? description;
  final String? videoUrl;
  final List<_Approach> approaches;
  final List<Map<String, dynamic>> previousResults;
  final String? nextExerciseName;

  _ExerciseDetail({
    required this.exerciseId,
    required this.name,
    this.description,
    this.videoUrl,
    required this.approaches,
    required this.previousResults,
    this.nextExerciseName,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class LiveWorkoutScreen extends ConsumerStatefulWidget {
  final String workoutId; // schedule_id
  const LiveWorkoutScreen({super.key, required this.workoutId});

  @override
  ConsumerState<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends ConsumerState<LiveWorkoutScreen> {
  // Exercise navigation
  List<String> _exerciseIds = [];
  int _exIdx = 0;

  // Current exercise detail
  _ExerciseDetail? _detail;
  bool _loading = true;
  String? _loadError;

  // Approach tracking
  int _currentApproach = 0; // 0-indexed
  final Set<int> _doneApproachNums = {};
  bool _inRest = false;

  // Timer
  int _timerSecs = 60;
  bool _timerRunning = false;
  Timer? _timer;
  static const _restDuration = 60; // seconds rest between sets

  // Modals
  bool _showEndConfirm = false;
  bool _showDoneModal = false;
  bool _showHistory = false;

  // Done modal
  late TextEditingController _doneRepsCtrl;
  late TextEditingController _doneWeightCtrl;
  bool _doneNoWeight = false;

  @override
  void initState() {
    super.initState();
    _doneRepsCtrl = TextEditingController();
    _doneWeightCtrl = TextEditingController();
    _loadExerciseList();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _doneRepsCtrl.dispose();
    _doneWeightCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────────

  Future<void> _loadExerciseList() async {
    try {
      final entries = await ref
          .read(scheduleExercisesProvider(widget.workoutId).future);
      _exerciseIds = entries.map((e) => e.id).toList();
      if (_exerciseIds.isNotEmpty) {
        await _loadExercise(_exerciseIds[0]);
      } else {
        setState(() { _loading = false; _loadError = 'No exercises'; });
      }
    } catch (e) {
      setState(() { _loading = false; _loadError = e.toString(); });
    }
  }

  Future<void> _loadExercise(String exerciseId) async {
    setState(() { _loading = true; _loadError = null; });
    try {
      final resp = await apiDio.get(
        '/api/v1/training/schedule/${widget.workoutId}/exercise/$exerciseId',
      );
      final d = resp.data as Map<String, dynamic>;
      final approachList = (d['approaches'] as List? ?? []).map((a) {
        final am = a as Map<String, dynamic>;
        return _Approach(
          number: (am['approach_number'] as num?)?.toInt() ?? 1,
          reps: (am['repetitions'] as num?)?.toInt() ?? 10,
          repMargin: (am['repetition_margin'] as num?)?.toInt() ?? 0,
          weight: (am['weight'] as num?)?.toDouble(),
        );
      }).toList();

      final prevResults = (d['previous_results'] as List? ?? [])
          .map((r) => r as Map<String, dynamic>)
          .toList();

      if (mounted) {
        setState(() {
          _detail = _ExerciseDetail(
            exerciseId: (d['exercise_id'] as num?)?.toInt() ?? 0,
            name: d['name'] as String? ?? '',
            description: d['description'] as String?,
            videoUrl: d['video_url'] as String?,
            approaches: approachList,
            previousResults: prevResults,
            nextExerciseName: d['next_exercise'] as String?,
          );
          _currentApproach = 0;
          _doneApproachNums.clear();
          _inRest = false;
          _loading = false;
          // Set timer for first approach
          if (approachList.isNotEmpty) _timerSecs = 60;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; _loadError = e.toString(); });
      }
    }
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_timerSecs > 0) {
        setState(() => _timerSecs--);
      } else {
        _timer?.cancel();
        setState(() => _timerRunning = false);
        if (_inRest) _endRest();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _timerRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _timerSecs = _inRest ? _restDuration : 60;
      _timerRunning = false;
    });
  }

  void _endRest() {
    final approaches = _detail?.approaches ?? [];
    if (_currentApproach < approaches.length - 1) {
      setState(() {
        _currentApproach++;
        _inRest = false;
        _timerSecs = 60;
      });
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _openDoneModal() {
    final approaches = _detail?.approaches ?? [];
    if (_currentApproach >= approaches.length) return;
    final a = approaches[_currentApproach];
    _doneRepsCtrl.text = '${a.reps}';
    _doneWeightCtrl.text = a.weight != null ? '${a.weight}' : '0';
    _doneNoWeight = a.weight == null;
    setState(() => _showDoneModal = true);
  }

  Future<void> _confirmDone() async {
    final approaches = _detail?.approaches ?? [];
    if (_currentApproach >= approaches.length) return;
    final a = approaches[_currentApproach];
    final reps = int.tryParse(_doneRepsCtrl.text) ?? a.reps;
    final weight = _doneNoWeight ? null : double.tryParse(_doneWeightCtrl.text);

    setState(() {
      _showDoneModal = false;
      _doneApproachNums.add(a.number);
    });

    // Submit this approach
    _submitApproach(a.number, reps, weight);

    final isLastApproach = _currentApproach >= approaches.length - 1;
    if (isLastApproach) {
      await _finishExercise(isLastExercise: _exIdx >= _exerciseIds.length - 1);
    } else {
      // Start rest
      setState(() {
        _inRest = true;
        _timerSecs = _restDuration;
      });
      _startTimer();
    }
  }

  void _skipApproach() {
    final approaches = _detail?.approaches ?? [];
    if (_currentApproach >= approaches.length) return;
    final isLast = _currentApproach >= approaches.length - 1;
    if (isLast) {
      _finishExercise(isLastExercise: _exIdx >= _exerciseIds.length - 1);
    } else {
      setState(() {
        _currentApproach++;
        _inRest = false;
        _timer?.cancel();
        _timerRunning = false;
        _timerSecs = 60;
      });
    }
  }

  void _submitApproach(int approachNum, int reps, double? weight) {
    submitWorkoutResult(
      scheduleId: widget.workoutId,
      exerciseId: _detail!.exerciseId.toString(),
      approaches: [
        {'approach_number': approachNum, 'repetitions': reps, 'weight': weight}
      ],
      trainingComplete: false,
    ).catchError((_) {});
  }

  Future<void> _finishExercise({required bool isLastExercise}) async {
    _timer?.cancel();
    if (isLastExercise) {
      // Mark session complete
      if (_detail != null) {
        submitWorkoutResult(
          scheduleId: widget.workoutId,
          exerciseId: _detail!.exerciseId.toString(),
          approaches: [],
          trainingComplete: true,
        ).catchError((_) {});
      }
      if (mounted) context.go('/journal');
    } else {
      // Go to next exercise
      setState(() {
        _exIdx++;
        _loading = true;
      });
      await _loadExercise(_exerciseIds[_exIdx]);
    }
  }

  Future<void> _endWorkout() async {
    _timer?.cancel();
    if (_detail != null) {
      submitWorkoutResult(
        scheduleId: widget.workoutId,
        exerciseId: _detail!.exerciseId.toString(),
        approaches: [],
        trainingComplete: true,
      ).catchError((_) {});
    }
    if (mounted) context.go('/journal');
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);

    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator(color: _kOrange)),
      );
    }

    if (_loadError != null || _detail == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l.errorLoading),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/journal'),
                child: Text(l.retry),
              ),
            ],
          ),
        ),
      );
    }

    final detail = _detail!;
    final total = _exerciseIds.length;
    final approaches = detail.approaches;
    final progress = total > 0
        ? ((_exIdx + (_currentApproach / (approaches.isEmpty ? 1 : approaches.length))) / total)
            .clamp(0.0, 1.0)
        : 0.0;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: SafeArea(
            child: Column(
              children: [
                // ── Top bar ───────────────────────────────────────────────
                _buildTopBar(l, progress, total),

                // ── Scrollable content ────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Exercise image / video placeholder
                        _buildHero(detail),

                        // Exercise name + approach cards
                        _buildExerciseCard(detail, l),

                        const SizedBox(height: 8),

                        // History
                        _buildHistory(detail, l),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Timer + done controls (fixed above bottom)
        Positioned(
          left: 0, right: 0,
          bottom: MediaQuery.of(context).padding.bottom + 88,
          child: Center(child: _buildTimer(l)),
        ),

        // Bottom bar
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: _buildBottomBar(detail, l),
        ),

        // Modals
        if (_showEndConfirm) _buildEndConfirmModal(l),
        if (_showDoneModal) _buildDoneModal(l, detail),
        if (_showHistory) _buildHistoryModal(detail, l),
      ],
    );
  }

  Widget _buildTopBar(AppL10n l, double progress, int total) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showEndConfirm = true),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close, size: 22, color: _kText),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE5E5EA),
                    valueColor: const AlwaysStoppedAnimation(_kOrange),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.liveExerciseProgress(_exIdx + 1, total),
                  style: const TextStyle(fontSize: 12, color: _kGrey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _showHistory = true),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.history, size: 22, color: _kGrey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(_ExerciseDetail detail) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.28,
      color: Colors.black,
      child: const Center(
        child: Icon(Icons.fitness_center_rounded, size: 64, color: Colors.white38),
      ),
    );
  }

  Widget _buildExerciseCard(_ExerciseDetail detail, AppL10n l) {
    final approaches = detail.approaches;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.name,
            style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.w900, color: _kText),
          ),
          if (detail.description?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              detail.description!,
              style: const TextStyle(fontSize: 14, color: _kGrey, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),

          // Sets progress bar
          Row(
            children: [
              Text(
                '${approaches.length} ${l.liveSetLabel(approaches.length)}',
                style: const TextStyle(fontSize: 13, color: _kGrey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: List.generate(approaches.length, (i) {
                    final a = approaches[i];
                    final isDone = _doneApproachNums.contains(a.number);
                    final isCurrent = i == _currentApproach && !isDone && !_inRest;
                    return Expanded(
                      child: Container(
                        height: 6,
                        margin: EdgeInsets.only(right: i < approaches.length - 1 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: isDone
                              ? _kGreen
                              : isCurrent
                                  ? _kOrange
                                  : const Color(0xFFE5E5EA),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Approach cards
          ...List.generate(approaches.length, (i) {
            final a = approaches[i];
            final isDone = _doneApproachNums.contains(a.number);
            final isCurrent = i == _currentApproach && !isDone && !_inRest;
            Color bgColor;
            Color borderColor;
            if (isDone) {
              bgColor = const Color(0xFFF0F9F4);
              borderColor = _kGreen;
            } else if (isCurrent) {
              bgColor = const Color(0xFFFFF4E6);
              borderColor = _kOrange;
            } else {
              bgColor = const Color(0xFFF8F8F8);
              borderColor = const Color(0xFFE5E5EA);
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE5E5EA)),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, color: _kGreen, size: 16)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isCurrent ? _kOrange : _kText,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${a.reps} ${l.liveReps}'
                      '${a.weight != null ? ' · ${a.weight} ${l.unitKg}' : ' · ${l.liveNoWeight}'}',
                      style: const TextStyle(fontSize: 14, color: _kText),
                    ),
                  ),
                  if (isCurrent)
                    GestureDetector(
                      onTap: _openDoneModal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kOrange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l.liveDone,
                          style: const TextStyle(
                            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHistory(_ExerciseDetail detail, AppL10n l) {
    if (detail.previousResults.isEmpty) return const SizedBox();
    final previewText = detail.previousResults.take(2).map((r) {
      final reps = r['repetitions'] as int? ?? 0;
      final weight = r['weight'];
      return weight != null && weight != 0
          ? '$reps ${l.liveReps} × $weight ${l.unitKg}'
          : '$reps ${l.liveReps}';
    }).join(', ');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.history, size: 18, color: _kGrey),
          const SizedBox(width: 8),
          Text('${l.liveHistory}: ', style: const TextStyle(fontSize: 13, color: _kGrey)),
          Expanded(
            child: Text(
              previewText,
              style: const TextStyle(fontSize: 13, color: _kText, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showHistory = true),
            child: const Icon(Icons.chevron_right, color: _kGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer(AppL10n l) {
    final color = _inRest ? _kGreen : _kOrange;
    final total = _inRest ? _restDuration : 60;
    final progress = total > 0 ? (_timerSecs / total).clamp(0.0, 1.0) : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 72, height: 72,
          child: CustomPaint(
            painter: _TimerPainter(progress: progress, color: color),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$_timerSecs',
                  style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            _TimerButton(icon: Icons.restart_alt, onTap: _resetTimer),
            const SizedBox(width: 8),
            _TimerButton(
              icon: _timerRunning ? Icons.pause : Icons.play_arrow,
              color: color,
              onTap: _timerRunning ? _pauseTimer : _startTimer,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar(_ExerciseDetail detail, AppL10n l) {
    final isLastEx = _exIdx >= _exerciseIds.length - 1;
    final approaches = detail.approaches;
    final isLastApproach = _currentApproach >= approaches.length - 1;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, 20 + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          // Skip
          Expanded(
            child: OutlinedButton(
              onPressed: _inRest ? _skipApproach : _skipApproach,
              child: Text(l.liveSkipSet),
            ),
          ),
          const SizedBox(width: 12),
          // Done / Next / Finish
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _inRest ? null : _openDoneModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE5E5EA),
              ),
              child: Text(
                _inRest
                    ? l.liveRestLabel
                    : (isLastApproach && isLastEx)
                        ? l.liveFinishWorkout
                        : l.liveDone,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── End Confirm Modal ──────────────────────────────────────────────────────

  Widget _buildEndConfirmModal(AppL10n l) {
    return _ModalOverlay(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: _kRed, size: 48),
            const SizedBox(height: 16),
            Text(l.liveEndConfirmTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kText)),
            const SizedBox(height: 8),
            Text(l.liveEndConfirmBody,
                style: const TextStyle(fontSize: 14, color: _kGrey),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showEndConfirm = false),
                    child: Text(l.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _kRed, foregroundColor: Colors.white),
                    onPressed: _endWorkout,
                    child: Text(l.liveEndConfirmFinish),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Done Modal ─────────────────────────────────────────────────────────────

  Widget _buildDoneModal(AppL10n l, _ExerciseDetail detail) {
    final approaches = detail.approaches;
    if (_currentApproach >= approaches.length) return const SizedBox();

    return _ModalOverlay(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: StatefulBuilder(
          builder: (ctx, setInner) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.liveSetLabel(_currentApproach + 1),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: _kText),
              ),
              const SizedBox(height: 16),
              _FieldRow(
                label: l.liveRepsLabel,
                controller: _doneRepsCtrl,
              ),
              _FieldRow(
                label: l.liveWeightLabel,
                controller: _doneWeightCtrl,
                enabled: !_doneNoWeight,
              ),
              Row(
                children: [
                  Checkbox(
                    value: _doneNoWeight,
                    onChanged: (v) {
                      setInner(() => _doneNoWeight = v ?? false);
                      setState(() => _doneNoWeight = v ?? false);
                    },
                  ),
                  Text(l.liveNoWeight, style: const TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _showDoneModal = false),
                      child: Text(l.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _kGreen, foregroundColor: Colors.white),
                      onPressed: _confirmDone,
                      child: Text(l.liveDone),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── History Modal ──────────────────────────────────────────────────────────

  Widget _buildHistoryModal(_ExerciseDetail detail, AppL10n l) {
    return _ModalOverlay(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 8, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.liveHistory,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700, color: _kText)),
                IconButton(
                  onPressed: () => setState(() => _showHistory = false),
                  icon: const Icon(Icons.close, color: _kGrey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E5EA)),
          if (detail.previousResults.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(l.liveNoHistory,
                  style: const TextStyle(fontSize: 14, color: _kGrey)),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: detail.previousResults.map((r) {
                    final num = r['approach_number'] as int? ?? 0;
                    final reps = r['repetitions'] as int? ?? 0;
                    final weight = r['weight'];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${l.liveSetLabel(num)}',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600, color: _kText)),
                          Text(
                            '$reps ${l.liveReps}'
                            '${weight != null && weight != 0 ? ' × $weight ${l.unitKg}' : ''}',
                            style: const TextStyle(fontSize: 14, color: _kGrey),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _TimerButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _TimerButton({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: color ?? _kGrey),
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final Color color;

  _TimerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    const strokeWidth = 5.0;

    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_TimerPainter old) =>
      old.progress != progress || old.color != color;
}

class _ModalOverlay extends StatelessWidget {
  final Widget child;
  const _ModalOverlay({required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;

  const _FieldRow({
    required this.label,
    required this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 13, color: _kText)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: enabled
                    ? const Color(0xFFF2F2F7)
                    : const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Keep LiveExercise for backward compat (unused now but referenced by some imports)
class LiveExercise {
  final String id;
  final String name;
  final int sets;
  final int reps;
  final double weight;

  LiveExercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
  });
}

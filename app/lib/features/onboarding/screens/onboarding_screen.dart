import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/onboarding_provider.dart';

// ─── Step enum ─────────────────────────────────────────────────────────────────

enum _Step {
  landing,
  goals,
  gender,
  age,
  height,
  weight,
  training,
  modules,
  result,
}

// ─── Main screen ───────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  // ── Step management ────────────────────────────────────────────────────────
  int _stepIndex = 0;

  List<_Step> get _steps => [
        _Step.landing,
        _Step.goals,
        _Step.gender,
        _Step.age,
        _Step.height,
        _Step.weight,
        _Step.training,
        _Step.modules,
        _Step.result,
      ];

  _Step get _current => _steps[_stepIndex];

  // ── Collected data ─────────────────────────────────────────────────────────
  String _goal = '';
  String _gender = '';
  int? _age;
  double? _height;
  double? _weight;
  double? _targetWeight;
  String _trainingFreq = '';
  Set<String> _modules = {'nutrition', 'training'};

  // ── Controllers ────────────────────────────────────────────────────────────
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();

  String? _fieldError;

  // ── Calculated result ──────────────────────────────────────────────────────
  NutritionGoal? _calculatedGoal;

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _goNext() {
    setState(() {
      _fieldError = null;
      if (_stepIndex < _steps.length - 1) _stepIndex++;
    });
  }

  void _goBack() {
    setState(() {
      _fieldError = null;
      if (_stepIndex > 0) _stepIndex--;
    });
  }

  // ── Step-specific handlers ─────────────────────────────────────────────────

  void _handleHeightNext() {
    final h = double.tryParse(_heightCtrl.text);
    if (h == null || h < 100 || h > 250) {
      setState(() => _fieldError = _isRu ? 'Введите рост от 100 до 250 см' : 'Enter height 100–250 cm');
      return;
    }
    _height = h;
    _goNext();
  }

  void _handleWeightNext() {
    final w = double.tryParse(_weightCtrl.text);
    if (w == null || w < 30 || w > 300) {
      setState(() => _fieldError = _isRu ? 'Введите вес от 30 до 300 кг' : 'Enter weight 30–300 kg');
      return;
    }
    _weight = w;

    if (_goal == 'maintain') {
      _targetWeight = w;
      _goNext();
      return;
    }

    final tw = double.tryParse(_targetWeightCtrl.text);
    if (tw == null || tw < 30 || tw > 300) {
      setState(() => _fieldError = _isRu ? 'Введите целевой вес от 30 до 300 кг' : 'Enter target weight 30–300 kg');
      return;
    }
    _targetWeight = tw;
    _goNext();
  }

  bool get _isRu {
    try {
      return Localizations.localeOf(context).languageCode == 'ru';
    } catch (_) {
      return true;
    }
  }

  // ── Save and finish ────────────────────────────────────────────────────────

  Future<void> _saveAndGoToLogin() async {
    final data = OnboardingData(
      goal: _goal,
      gender: _gender,
      age: _age ?? 25,
      height: _height ?? 170,
      weight: _weight ?? 70,
      targetWeight: _targetWeight ?? _weight ?? 70,
      trainingFreq: _trainingFreq.isEmpty ? '1-2' : _trainingFreq,
      modules: _modules.toList(),
    );

    final goal = calculateNutritionGoal(data);

    await Future.wait([
      saveOnboardingData(data),
      saveLocalNutritionGoal(goal),
      ref.read(onboardingDoneProvider.notifier).markDone(),
    ]);

    if (mounted) context.go('/login');
  }

  // ── Calculation for result step ────────────────────────────────────────────

  NutritionGoal get _goalPreview {
    _calculatedGoal ??= calculateNutritionGoal(OnboardingData(
      goal: _goal.isEmpty ? 'maintain' : _goal,
      gender: _gender.isEmpty ? 'male' : _gender,
      age: _age ?? 25,
      height: _height ?? 170,
      weight: _weight ?? 70,
      targetWeight: _targetWeight ?? _weight ?? 70,
      trainingFreq: _trainingFreq.isEmpty ? '1-2' : _trainingFreq,
    ));
    return _calculatedGoal!;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLanding = _current == _Step.landing;

    if (isLanding) {
      return _LandingStep(
        isRu: _isRu,
        onStart: _goNext,
        onLogin: () => context.go('/login'),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: _buildCta(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(_current),
                  child: _buildStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header (progress + back) ───────────────────────────────────────────────

  Widget _buildHeader() {
    final totalSteps = _steps.length;
    final progress = _stepIndex / (totalSteps - 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _goBack,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(AppRadius.appBarAction),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppColors.borderStrong,
                valueColor: const AlwaysStoppedAnimation(AppColors.brandBlue),
              ),
            ),
          ),
          const SizedBox(width: 50),
        ],
      ),
    );
  }

  // ── CTA button ─────────────────────────────────────────────────────────────

  Widget? _buildCta() {
    VoidCallback? onTap;
    String label = _isRu ? 'Далее' : 'Next';

    switch (_current) {
      case _Step.goals:
        onTap = _goal.isNotEmpty ? _goNext : null;
      case _Step.gender:
        onTap = _gender.isNotEmpty ? _goNext : null;
      case _Step.age:
        onTap = _age != null ? _goNext : null;
      case _Step.height:
        label = _isRu ? 'Далее' : 'Next';
        onTap = _heightCtrl.text.isNotEmpty ? _handleHeightNext : null;
      case _Step.weight:
        label = _isRu ? 'Рассчитать план' : 'Calculate plan';
        onTap = _weightCtrl.text.isNotEmpty ? _handleWeightNext : null;
      case _Step.training:
        onTap = _trainingFreq.isNotEmpty ? _goNext : null;
      case _Step.modules:
        onTap = _modules.isNotEmpty ? _goNext : null;
      case _Step.result:
        label = _isRu ? 'Начать путь' : 'Start journey';
        onTap = _saveAndGoToLogin;
      default:
        onTap = _goNext;
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
        child: _ObButton(label: label, onTap: onTap),
      ),
    );
  }

  // ── Step content ───────────────────────────────────────────────────────────

  Widget _buildStep() {
    switch (_current) {
      case _Step.landing:
        return const SizedBox.shrink();

      case _Step.goals:
        return _GoalsStep(
          isRu: _isRu,
          selected: _goal,
          onSelect: (v) => setState(() { _goal = v; _goNext(); }),
        );

      case _Step.gender:
        return _GenderStep(
          isRu: _isRu,
          selected: _gender,
          onSelect: (v) => setState(() { _gender = v; _goNext(); }),
        );

      case _Step.age:
        return _AgeStep(
          isRu: _isRu,
          selected: _age,
          onSelect: (v) => setState(() { _age = v; _goNext(); }),
        );

      case _Step.height:
        return _HeightStep(
          isRu: _isRu,
          controller: _heightCtrl,
          error: _fieldError,
          onChanged: (_) => setState(() { _fieldError = null; }),
        );

      case _Step.weight:
        return _WeightStep(
          isRu: _isRu,
          goal: _goal,
          weightCtrl: _weightCtrl,
          targetCtrl: _targetWeightCtrl,
          error: _fieldError,
          onChanged: (_) => setState(() { _fieldError = null; }),
        );

      case _Step.training:
        return _TrainingStep(
          isRu: _isRu,
          selected: _trainingFreq,
          onSelect: (v) => setState(() => _trainingFreq = v),
        );

      case _Step.modules:
        return _ModulesStep(
          isRu: _isRu,
          selected: _modules,
          onToggle: (v) => setState(() {
            if (_modules.contains(v)) {
              if (_modules.length > 1) _modules.remove(v);
            } else {
              _modules.add(v);
            }
          }),
        );

      case _Step.result:
        return _ResultStep(isRu: _isRu, goal: _goalPreview, currentWeight: _weight ?? 70);
    }
  }
}

// ─── Landing ──────────────────────────────────────────────────────────────────

class _LandingStep extends StatelessWidget {
  final bool isRu;
  final VoidCallback onStart;
  final VoidCallback onLogin;

  const _LandingStep({required this.isRu, required this.onStart, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // Hero header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(28, MediaQuery.of(context).padding.top + 60, 28, 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.brandBlue, Color(0xFF7C3AED)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Icon(Icons.bolt_rounded, size: 36, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isRu ? 'Твой путь к\nлучшей форме' : 'Your path to\nbetter shape',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isRu
                      ? 'AI-тренер и нутрициолог в одном приложении'
                      : 'AI trainer and nutritionist in one app',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Feature list
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LandingFeature(icon: Icons.track_changes_rounded, text: isRu ? 'Персональный план питания на основе твоих данных' : 'Personal nutrition plan based on your data'),
                  const SizedBox(height: 16),
                  _LandingFeature(icon: Icons.fitness_center_rounded, text: isRu ? 'Тренировки подобранные под твоё оборудование' : 'Workouts tailored to your equipment'),
                  const SizedBox(height: 16),
                  _LandingFeature(icon: Icons.smart_toy_rounded, text: isRu ? 'AI ответит на любые вопросы по питанию и форме' : 'AI answers any nutrition and fitness questions'),
                ],
              ),
            ),
          ),

          // CTA
          Padding(
            padding: EdgeInsets.fromLTRB(28, 0, 28, MediaQuery.of(context).padding.bottom + 12),
            child: Column(
              children: [
                _ObButton(
                  label: isRu ? 'Начать бесплатно' : 'Start for free',
                  onTap: onStart,
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: onLogin,
                  child: Text(
                    isRu ? 'Уже есть аккаунт? Войти' : 'Have an account? Sign in',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingFeature extends StatelessWidget {
  final IconData icon;
  final String text;
  const _LandingFeature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.4)),
        ),
      ],
    );
  }
}

// ─── Goals ────────────────────────────────────────────────────────────────────

class _GoalsStep extends StatelessWidget {
  final bool isRu;
  final String selected;
  final ValueChanged<String> onSelect;
  const _GoalsStep({required this.isRu, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = [
      ('lose_weight', Icons.trending_down_rounded, isRu ? 'Сбросить вес' : 'Lose weight', isRu ? 'Дефицит калорий и план питания' : 'Calorie deficit and nutrition plan'),
      ('maintain', Icons.balance_rounded, isRu ? 'Поддержать форму' : 'Maintain shape', isRu ? 'Баланс и здоровые привычки' : 'Balance and healthy habits'),
      ('gain_muscle', Icons.fitness_center_rounded, isRu ? 'Набрать мышцы' : 'Build muscle', isRu ? 'Профицит и белковый план' : 'Surplus and protein plan'),
    ];
    return _StepScroll(
      title: isRu ? 'Какова твоя цель?' : 'What is your goal?',
      subtitle: isRu ? 'Выбери основное направление — сможешь изменить в настройках' : 'Pick your main direction — you can change in settings',
      children: options.map((o) {
        final (id, icon, name, desc) = o;
        return _SelectCard(
          icon: icon,
          name: name,
          desc: desc,
          selected: selected == id,
          onTap: () => onSelect(id),
        );
      }).toList(),
    );
  }
}

// ─── Gender ───────────────────────────────────────────────────────────────────

class _GenderStep extends StatelessWidget {
  final bool isRu;
  final String selected;
  final ValueChanged<String> onSelect;
  const _GenderStep({required this.isRu, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return _StepScroll(
      title: isRu ? 'Твой пол' : 'Your gender',
      subtitle: isRu ? 'Влияет на расчёт базового обмена веществ' : 'Affects basal metabolic rate calculation',
      children: [
        _SelectCard(
          icon: Icons.male_rounded,
          name: isRu ? 'Мужчина' : 'Male',
          desc: isRu ? 'Биологический пол' : 'Biological sex',
          selected: selected == 'male',
          onTap: () => onSelect('male'),
        ),
        _SelectCard(
          icon: Icons.female_rounded,
          name: isRu ? 'Женщина' : 'Female',
          desc: isRu ? 'Биологический пол' : 'Biological sex',
          selected: selected == 'female',
          onTap: () => onSelect('female'),
        ),
      ],
    );
  }
}

// ─── Age ──────────────────────────────────────────────────────────────────────

class _AgeStep extends StatelessWidget {
  final bool isRu;
  final int? selected;
  final ValueChanged<int> onSelect;
  const _AgeStep({required this.isRu, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const options = [('18–24', 21), ('25–34', 30), ('35–44', 40), ('45+', 50)];
    return _StepScroll(
      title: isRu ? 'Твой возраст' : 'Your age',
      subtitle: isRu ? 'Используется для расчёта калорийности' : 'Used for calorie calculation',
      children: options.map((o) {
        final (label, value) = o;
        return _SelectCard(
          icon: Icons.calendar_today_rounded,
          name: label,
          desc: isRu ? 'лет' : 'years',
          selected: selected == value,
          onTap: () => onSelect(value),
        );
      }).toList(),
    );
  }
}

// ─── Height ───────────────────────────────────────────────────────────────────

class _HeightStep extends StatelessWidget {
  final bool isRu;
  final TextEditingController controller;
  final String? error;
  final ValueChanged<String> onChanged;
  const _HeightStep({required this.isRu, required this.controller, this.error, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _StepScroll(
      title: isRu ? 'Твой рост' : 'Your height',
      subtitle: isRu ? 'В сантиметрах' : 'In centimetres',
      children: [
        _NumberField(
          controller: controller,
          hint: isRu ? 'например 175' : 'e.g. 175',
          suffix: isRu ? 'см' : 'cm',
          error: error,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ─── Weight ───────────────────────────────────────────────────────────────────

class _WeightStep extends StatelessWidget {
  final bool isRu;
  final String goal;
  final TextEditingController weightCtrl;
  final TextEditingController targetCtrl;
  final String? error;
  final ValueChanged<String> onChanged;

  const _WeightStep({
    required this.isRu,
    required this.goal,
    required this.weightCtrl,
    required this.targetCtrl,
    this.error,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final showTarget = goal != 'maintain';
    final targetLabel = goal == 'gain_muscle'
        ? (isRu ? 'Целевой вес (набор)' : 'Target weight (gain)')
        : (isRu ? 'Целевой вес (снижение)' : 'Target weight (loss)');

    return _StepScroll(
      title: isRu ? 'Твой вес' : 'Your weight',
      subtitle: isRu ? 'В килограммах' : 'In kilograms',
      children: [
        _NumberField(
          controller: weightCtrl,
          hint: isRu ? 'Текущий вес, кг' : 'Current weight, kg',
          suffix: isRu ? 'кг' : 'kg',
          error: showTarget ? null : error,
          onChanged: onChanged,
          label: isRu ? 'ТЕКУЩИЙ ВЕС' : 'CURRENT WEIGHT',
        ),
        if (showTarget) ...[
          const SizedBox(height: 14),
          _NumberField(
            controller: targetCtrl,
            hint: isRu ? 'Целевой вес, кг' : 'Target weight, kg',
            suffix: isRu ? 'кг' : 'kg',
            error: error,
            onChanged: onChanged,
            label: targetLabel.toUpperCase(),
          ),
        ],
      ],
    );
  }
}

// ─── Training ─────────────────────────────────────────────────────────────────

class _TrainingStep extends StatelessWidget {
  final bool isRu;
  final String selected;
  final ValueChanged<String> onSelect;
  const _TrainingStep({required this.isRu, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = [
      ('0', Icons.weekend_outlined, isRu ? 'Не тренируюсь' : 'No training', isRu ? 'Сидячий образ жизни' : 'Sedentary lifestyle'),
      ('1-2', Icons.directions_walk_rounded, isRu ? '1–2 раза в неделю' : '1–2 times/week', isRu ? 'Лёгкая активность' : 'Light activity'),
      ('3-4', Icons.directions_run_rounded, isRu ? '3–4 раза в неделю' : '3–4 times/week', isRu ? 'Умеренная активность' : 'Moderate activity'),
      ('daily', Icons.bolt_rounded, isRu ? 'Каждый день' : 'Every day', isRu ? 'Высокая активность' : 'High activity'),
    ];
    return _StepScroll(
      title: isRu ? 'Как часто тренируешься?' : 'How often do you train?',
      subtitle: isRu ? 'Влияет на коэффициент активности в расчёте' : 'Affects the activity multiplier in calculation',
      children: options.map((o) {
        final (id, icon, name, desc) = o;
        return _SelectCard(
          icon: icon,
          name: name,
          desc: desc,
          selected: selected == id,
          onTap: () => onSelect(id),
        );
      }).toList(),
    );
  }
}

// ─── Modules ──────────────────────────────────────────────────────────────────

class _ModulesStep extends StatelessWidget {
  final bool isRu;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  const _ModulesStep({required this.isRu, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return _StepScroll(
      title: isRu ? 'Что хочешь отслеживать?' : 'What do you want to track?',
      subtitle: isRu ? 'Включи нужные модули — приложение перестроится под тебя' : 'Enable needed modules — the app will adapt to you',
      children: [
        _SelectCard(
          icon: Icons.restaurant_rounded,
          name: isRu ? 'Питание' : 'Nutrition',
          desc: isRu ? 'Дневник, КБЖУ, AI-нутрициолог' : 'Diary, macros, AI nutritionist',
          selected: selected.contains('nutrition'),
          onTap: () => onToggle('nutrition'),
        ),
        _SelectCard(
          icon: Icons.fitness_center_rounded,
          name: isRu ? 'Тренировки' : 'Training',
          desc: isRu ? 'Программы, упражнения, AI-тренер' : 'Programs, exercises, AI trainer',
          selected: selected.contains('training'),
          onTap: () => onToggle('training'),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                isRu ? 'Можно поменять в Настройках в любой момент' : 'Can be changed in Settings at any time',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Generating ───────────────────────────────────────────────────────────────

class _GeneratingStep extends StatefulWidget {
  final bool isRu;
  final VoidCallback onDone;
  const _GeneratingStep({required this.isRu, required this.onDone});

  @override
  State<_GeneratingStep> createState() => _GeneratingStepState();
}

class _GeneratingStepState extends State<_GeneratingStep> with TickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  late final AnimationController _pulseCtrl;

  final List<String> _stepsRu = [
    'Анализируем данные',
    'Считаем базовый метаболизм',
    'Рассчитываем КБЖУ',
    'Формируем план',
  ];
  final List<String> _stepsEn = [
    'Analysing your data',
    'Calculating base metabolism',
    'Computing macros',
    'Building your plan',
  ];

  int _currentStepIdx = 0;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

    // Advance through steps
    _stepTimer = Timer.periodic(const Duration(milliseconds: 700), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _currentStepIdx = (_currentStepIdx + 1) % 4);
    });

    // Auto-advance after 3 seconds
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _pulseCtrl.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.isRu ? _stepsRu : _stepsEn;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brandBlue, Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandBlue.withValues(alpha: 0.3 + _pulseCtrl.value * 0.2),
                      blurRadius: 24 + _pulseCtrl.value * 12,
                    ),
                  ],
                ),
                child: const Center(child: Icon(Icons.auto_awesome_rounded, size: 40, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              widget.isRu ? 'Составляем твой план' : 'Building your plan',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.3),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                steps[_currentStepIdx],
                key: ValueKey(_currentStepIdx),
                style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 32),
            RotationTransition(
              turns: _spinCtrl,
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: const AlwaysStoppedAnimation(AppColors.brandBlue),
                  backgroundColor: AppColors.brandBlueSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Result ("Path to goal") ──────────────────────────────────────────────────

class _ResultStep extends StatelessWidget {
  final bool isRu;
  final NutritionGoal goal;
  final double currentWeight;
  const _ResultStep({required this.isRu, required this.goal, required this.currentWeight});

  @override
  Widget build(BuildContext context) {
    final isMaintain = (goal.targetCalories - _tdee(goal)).abs() < 80;
    final isLose = goal.targetCalories < _tdee(goal) - 80;
    final isGain = !isLose && !isMaintain;

    final directionLabel = isLose
        ? (isRu ? 'Снижение веса' : 'Weight loss')
        : isGain
            ? (isRu ? 'Набор мышечной массы' : 'Muscle gain')
            : (isRu ? 'Поддержание формы' : 'Maintain shape');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        const SizedBox(height: 12),

        // Personal plan banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), AppColors.brandBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    isRu ? 'Твой персональный план' : 'Your personal plan',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.3),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                directionLabel,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Hero kcal card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.brandBlue, Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: AppColors.brandBlue.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              Text(
                isRu ? 'Цель калорий в день' : 'Daily calorie goal',
                style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      goal.targetCalories.toString(),
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: AppColors.brandBlue,
                        height: 1,
                        letterSpacing: -2,
                      ),
                    ),
                    Text(
                      isRu ? 'ккал / день' : 'kcal / day',
                      style: const TextStyle(fontSize: 14, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Macros card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderStrong),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRu ? 'Макронутриенты' : 'Macronutrients',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _MacroChip(
                    label: isRu ? 'Белки' : 'Protein',
                    value: goal.protein,
                    unit: isRu ? 'г' : 'g',
                    color: AppColors.protein,
                    bgColor: const Color(0xFFDCFCE7),
                  ),
                  const SizedBox(width: 8),
                  _MacroChip(
                    label: isRu ? 'Жиры' : 'Fat',
                    value: goal.fat,
                    unit: isRu ? 'г' : 'g',
                    color: AppColors.fat,
                    bgColor: const Color(0xFFFEF9C3),
                  ),
                  const SizedBox(width: 8),
                  _MacroChip(
                    label: isRu ? 'Углеводы' : 'Carbs',
                    value: goal.carbs,
                    unit: isRu ? 'г' : 'g',
                    color: AppColors.carbs,
                    bgColor: const Color(0xFFE0F2FE),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Days to goal (if applicable)
        if (goal.daysToGoal != null)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Row(
              children: [
                const Icon(Icons.flag_outlined, size: 20, color: AppColors.brandBlue),
                const SizedBox(width: 12),
                Text(
                  isRu
                      ? 'До цели: ~${goal.daysToGoal} дней (${(goal.daysToGoal! / 7).round()} недель)'
                      : 'To goal: ~${goal.daysToGoal} days (${(goal.daysToGoal! / 7).round()} weeks)',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

        if (goal.daysToGoal != null) const SizedBox(height: 12),

        // Science note
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderStrong),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 15, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRu
                      ? 'Расчёт по формуле Mifflin-St Jeor (The American Journal of Clinical Nutrition, 1990). Это ориентировочные значения — скорректируй с врачом или диетологом.'
                      : 'Calculated using Mifflin-St Jeor formula (The American Journal of Clinical Nutrition, 1990). These are estimates — consult a doctor or dietitian.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Rough TDEE reverse from goal calories (to detect direction for display)
  double _tdee(NutritionGoal g) {
    // Approximate TDEE as between goal and target+500 (lose) or goal-300 (gain)
    // We don't store TDEE in NutritionGoal, so approximate from calorie count:
    // For display purpose only
    return g.targetCalories.toDouble() + (g.daysToGoal != null && g.targetCalories < 2500 ? 500 : 0);
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final Color color;
  final Color bgColor;

  const _MacroChip({required this.label, required this.value, required this.unit, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text('$value$unit', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ─── Shared layout widgets ────────────────────────────────────────────────────

class _StepScroll extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _StepScroll({required this.title, required this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      children: [
        Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.4)),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.4)),
        const SizedBox(height: 24),
        ...children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: c)),
      ],
    );
  }
}

class _SelectCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String desc;
  final bool selected;
  final VoidCallback onTap;

  const _SelectCard({required this.icon, required this.name, required this.desc, required this.selected, required this.onTap});

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
              child: Icon(icon, size: 24, color: selected ? AppColors.brandBlue : AppColors.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(color: AppColors.brandBlue, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String suffix;
  final String? error;
  final ValueChanged<String> onChanged;
  final String? label;

  const _NumberField({
    required this.controller,
    required this.hint,
    required this.suffix,
    this.error,
    required this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.8)),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}'))],
          onChanged: onChanged,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textMuted),
            suffixText: suffix,
            suffixStyle: const TextStyle(fontSize: 16, color: AppColors.textMuted),
            filled: true,
            fillColor: error != null ? const Color(0xFFFEF2F2) : AppColors.surfaceTint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: BorderSide(color: error != null ? AppColors.error : Colors.transparent),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: BorderSide(color: error != null ? AppColors.error : Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: const BorderSide(color: AppColors.brandBlue, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            errorText: error,
            errorStyle: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
        ),
      ],
    );
  }
}

// ─── Gradient CTA button ──────────────────────────────────────────────────────

class _ObButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _ObButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.38 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: onTap != null
                ? const LinearGradient(
                    colors: [AppColors.brandBlue, Color(0xFF7C3AED)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: onTap == null ? AppColors.borderStrong : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: onTap != null
                ? [BoxShadow(color: AppColors.brandBlue.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

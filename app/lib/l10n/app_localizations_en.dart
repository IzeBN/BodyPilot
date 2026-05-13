// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'KayFit';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle => 'Enter your account credentials';

  @override
  String get loginButton => 'Sign in';

  @override
  String get loginError => 'Invalid email or password';

  @override
  String get noAccount => 'No account? Register';

  @override
  String get registerTitle => 'Register';

  @override
  String get createAccountButton => 'Create account';

  @override
  String get registerError => 'Registration failed. Please try again.';

  @override
  String get emailHint => 'Email';

  @override
  String get passwordHint => 'Password';

  @override
  String get nameHint => 'Name';

  @override
  String get obModulesTitle => 'Tell us about your goals';

  @override
  String get obModulesSubtitle =>
      'Enable the modules you need — the app will adapt to you.';

  @override
  String get obModulesHint => 'You can change this in Settings at any time';

  @override
  String get nutritionModuleName => 'Nutrition';

  @override
  String get nutritionModuleDesc => 'Diary, macros, AI nutritionist';

  @override
  String get trainingModuleName => 'Training';

  @override
  String get trainingModuleDesc => 'Programs, exercises, AI trainer';

  @override
  String get obEquipTitle => 'What do you train with?';

  @override
  String get obEquipSubtitle =>
      'We\'ll build a plan for your available equipment.';

  @override
  String obEquipBanner(int count, int exercises) {
    return '$count selected — ~$exercises exercises available';
  }

  @override
  String get continueButton => 'Continue';

  @override
  String get journalTitle => 'Journal';

  @override
  String journalSubtitle(
      String dayName, int day, String month, int week, int totalWeeks) {
    return '$dayName, $month $day · Week $week of $totalWeeks';
  }

  @override
  String get sectionFood => 'Food';

  @override
  String get sectionTraining => 'Training';

  @override
  String get caloriesLabel => 'CALORIES TODAY';

  @override
  String caloriesGoal(int goal) {
    return '/ $goal kcal';
  }

  @override
  String get macroProtein => 'P';

  @override
  String get macroFat => 'F';

  @override
  String get macroCarbs => 'C';

  @override
  String foodSectionSub(int kcal, int p, int c, int f) {
    return '$kcal kcal · PFC $p/$c/$f';
  }

  @override
  String trainingSectionSub(int week, int total) {
    return 'Today · Week $week/$total';
  }

  @override
  String get addMeal => '+ Add meal';

  @override
  String nextWorkout(String workout) {
    return 'Next: $workout ›';
  }

  @override
  String get unitMin => 'min';

  @override
  String get unitExercises => 'ex.';

  @override
  String get unitKcal => 'kcal';

  @override
  String get unitG => 'g';

  @override
  String get unitKg => 'kg';

  @override
  String get unitCm => 'cm';

  @override
  String get dayMon => 'MO';

  @override
  String get dayTue => 'TU';

  @override
  String get dayWed => 'WE';

  @override
  String get dayThu => 'TH';

  @override
  String get dayFri => 'FR';

  @override
  String get daySat => 'SA';

  @override
  String get daySun => 'SU';

  @override
  String get monthJan => 'January';

  @override
  String get monthFeb => 'February';

  @override
  String get monthMar => 'March';

  @override
  String get monthApr => 'April';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'June';

  @override
  String get monthJul => 'July';

  @override
  String get monthAug => 'August';

  @override
  String get monthSep => 'September';

  @override
  String get monthOct => 'October';

  @override
  String get monthNov => 'November';

  @override
  String get monthDec => 'December';

  @override
  String get workoutDetailCta => 'Start workout';

  @override
  String get exercisesSection => 'Exercises';

  @override
  String get statMin => 'MIN';

  @override
  String get statKcal => 'KCAL';

  @override
  String get statExercises => 'EX.';

  @override
  String liveExerciseProgress(int current, int total) {
    return 'Exercise $current of $total';
  }

  @override
  String liveSetLabel(int n) {
    return 'Set $n';
  }

  @override
  String liveSetProgress(int current, int total) {
    return 'Set $current of $total';
  }

  @override
  String get liveReps => 'Repetitions';

  @override
  String get liveWeightKg => 'Weight, kg';

  @override
  String get liveSkip => 'Skip';

  @override
  String get liveDone => 'Set complete';

  @override
  String get chatTitle => 'AI assistant';

  @override
  String get chatModeNutrition => 'Nutrition';

  @override
  String get chatModeNutritionDesc => 'Calories, macros, recipes';

  @override
  String get chatModeTraining => 'Training';

  @override
  String get chatModeTrainingDesc => 'Program, form, tips';

  @override
  String get chatPlaceholderNutrition => 'What did you eat today?';

  @override
  String get chatPlaceholderTraining => 'Ask about technique…';

  @override
  String get chatNetworkError => 'Network error. Please try again.';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountSubtitle => 'Profile · settings';

  @override
  String get sectionProgram => 'PROGRAM';

  @override
  String get sectionEquipment => 'EQUIPMENT';

  @override
  String get sectionLegal => 'LEGAL & DATA';

  @override
  String get sectionBody => 'BODY PARAMETERS';

  @override
  String get sectionApp => 'APP';

  @override
  String equipmentCount(int count) {
    return '$count selected';
  }

  @override
  String get equipmentHint =>
      'Workouts are matched to your available equipment. Tap to toggle.';

  @override
  String equipmentBanner(int count) {
    return '~$count exercises available in the library';
  }

  @override
  String get equipmentExtended => 'Advanced equipment selection';

  @override
  String get equipmentExtendedSub => 'weight / types ›';

  @override
  String get rowGoal => 'Goal';

  @override
  String get rowNutrition => 'Nutrition';

  @override
  String get rowTrainings => 'Training';

  @override
  String get rowAiServices => 'AI services';

  @override
  String get rowAiServicesSub => 'OpenAI · USDA database';

  @override
  String get rowPrivacy => 'Privacy';

  @override
  String get rowPrivacySub => 'Data settings';

  @override
  String get rowPrivacyPolicy => 'Privacy Policy';

  @override
  String get rowTerms => 'Terms of Use';

  @override
  String get rowAiModels => 'AI models';

  @override
  String get rowAiModelsSub => 'Processing consent';

  @override
  String get rowAiModelsAction => 'On ›';

  @override
  String get rowExport => 'Export data';

  @override
  String get rowWeight => 'Weight';

  @override
  String get rowHeight => 'Height';

  @override
  String get rowAge => 'Age';

  @override
  String get rowNotifications => 'Notifications';

  @override
  String get rowLanguage => 'Language';

  @override
  String get rowSubscription => 'Subscription';

  @override
  String get rowDeleteAccount => 'Delete account';

  @override
  String get rowHelp => 'Help & support';

  @override
  String get logout => 'Sign out';

  @override
  String appVersion(String version) {
    return 'KayFit · v$version';
  }

  @override
  String get statsTrainings => 'workouts';

  @override
  String get statsWeeks => 'weeks';

  @override
  String get statsKgLost => 'kg';

  @override
  String proLabel(String date) {
    return '★ Pro · until $date';
  }

  @override
  String get freeLabel => 'Free plan';

  @override
  String get tabJournal => 'Journal';

  @override
  String get tabChat => 'Chat';

  @override
  String get loading => 'Loading…';

  @override
  String get errorLoading => 'Failed to load';

  @override
  String get errorNetwork => 'Network error';

  @override
  String get retry => 'Retry';

  @override
  String get addMealTitle => 'Add meal';

  @override
  String get mealTypeBreakfast => 'Breakfast';

  @override
  String get mealTypeLunch => 'Lunch';

  @override
  String get mealTypeDinner => 'Dinner';

  @override
  String get mealTypeSnack => 'Snack';

  @override
  String get foodNameLabel => 'Food name';

  @override
  String get amountLabel => 'Amount, g';

  @override
  String get caloriesFieldLabel => 'Kcal';

  @override
  String get proteinLabel => 'Protein, g';

  @override
  String get fatLabel => 'Fat, g';

  @override
  String get carbsLabel => 'Carbs, g';

  @override
  String get saveMeal => 'Add';

  @override
  String get mealSaved => 'Meal added';
}

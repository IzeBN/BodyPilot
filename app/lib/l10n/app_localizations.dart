import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @appName.
  ///
  /// In ru, this message translates to:
  /// **'KayFit'**
  String get appName;

  /// No description provided for @loginTitle.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Введите данные вашего аккаунта'**
  String get loginSubtitle;

  /// No description provided for @loginButton.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get loginButton;

  /// No description provided for @loginError.
  ///
  /// In ru, this message translates to:
  /// **'Неверный email или пароль'**
  String get loginError;

  /// No description provided for @noAccount.
  ///
  /// In ru, this message translates to:
  /// **'Нет аккаунта? Зарегистрироваться'**
  String get noAccount;

  /// No description provided for @registerTitle.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get registerTitle;

  /// No description provided for @createAccountButton.
  ///
  /// In ru, this message translates to:
  /// **'Создать аккаунт'**
  String get createAccountButton;

  /// No description provided for @registerError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка регистрации. Попробуйте снова.'**
  String get registerError;

  /// No description provided for @emailHint.
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get passwordHint;

  /// No description provided for @nameHint.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get nameHint;

  /// No description provided for @obModulesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Расскажи о своих целях'**
  String get obModulesTitle;

  /// No description provided for @obModulesSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Включи нужные модули — приложение перестроится под тебя.'**
  String get obModulesSubtitle;

  /// No description provided for @obModulesHint.
  ///
  /// In ru, this message translates to:
  /// **'Можешь поменять в Настройках в любой момент'**
  String get obModulesHint;

  /// No description provided for @nutritionModuleName.
  ///
  /// In ru, this message translates to:
  /// **'Питание'**
  String get nutritionModuleName;

  /// No description provided for @nutritionModuleDesc.
  ///
  /// In ru, this message translates to:
  /// **'Дневник, БЖУ, AI-нутрициолог'**
  String get nutritionModuleDesc;

  /// No description provided for @trainingModuleName.
  ///
  /// In ru, this message translates to:
  /// **'Тренировки'**
  String get trainingModuleName;

  /// No description provided for @trainingModuleDesc.
  ///
  /// In ru, this message translates to:
  /// **'Программы, упражнения, AI-тренер'**
  String get trainingModuleDesc;

  /// No description provided for @obEquipTitle.
  ///
  /// In ru, this message translates to:
  /// **'Чем тренируешься?'**
  String get obEquipTitle;

  /// No description provided for @obEquipSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Подберём план под доступное оборудование.'**
  String get obEquipSubtitle;

  /// No description provided for @obEquipBanner.
  ///
  /// In ru, this message translates to:
  /// **'{count} выбрано — доступно ~{exercises} упражнений'**
  String obEquipBanner(int count, int exercises);

  /// No description provided for @continueButton.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get continueButton;

  /// No description provided for @journalTitle.
  ///
  /// In ru, this message translates to:
  /// **'Журнал'**
  String get journalTitle;

  /// No description provided for @journalSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'{dayName}, {day} {month} · Неделя {week} из {totalWeeks}'**
  String journalSubtitle(
      String dayName, int day, String month, int week, int totalWeeks);

  /// No description provided for @sectionFood.
  ///
  /// In ru, this message translates to:
  /// **'Еда'**
  String get sectionFood;

  /// No description provided for @sectionTraining.
  ///
  /// In ru, this message translates to:
  /// **'Тренировки'**
  String get sectionTraining;

  /// No description provided for @caloriesLabel.
  ///
  /// In ru, this message translates to:
  /// **'КАЛОРИИ СЕГОДНЯ'**
  String get caloriesLabel;

  /// No description provided for @caloriesGoal.
  ///
  /// In ru, this message translates to:
  /// **'/ {goal} ккал'**
  String caloriesGoal(int goal);

  /// No description provided for @macroProtein.
  ///
  /// In ru, this message translates to:
  /// **'Б'**
  String get macroProtein;

  /// No description provided for @macroFat.
  ///
  /// In ru, this message translates to:
  /// **'Ж'**
  String get macroFat;

  /// No description provided for @macroCarbs.
  ///
  /// In ru, this message translates to:
  /// **'У'**
  String get macroCarbs;

  /// No description provided for @foodSectionSub.
  ///
  /// In ru, this message translates to:
  /// **'{kcal} ккал · БЖУ {p}/{c}/{f}'**
  String foodSectionSub(int kcal, int p, int c, int f);

  /// No description provided for @trainingSectionSub.
  ///
  /// In ru, this message translates to:
  /// **'На сегодня · Неделя {week}/{total}'**
  String trainingSectionSub(int week, int total);

  /// No description provided for @addMeal.
  ///
  /// In ru, this message translates to:
  /// **'+ Добавить приём пищи'**
  String get addMeal;

  /// No description provided for @nextWorkout.
  ///
  /// In ru, this message translates to:
  /// **'Следующая: {workout} ›'**
  String nextWorkout(String workout);

  /// No description provided for @unitMin.
  ///
  /// In ru, this message translates to:
  /// **'мин'**
  String get unitMin;

  /// No description provided for @unitExercises.
  ///
  /// In ru, this message translates to:
  /// **'упр.'**
  String get unitExercises;

  /// No description provided for @unitKcal.
  ///
  /// In ru, this message translates to:
  /// **'ккал'**
  String get unitKcal;

  /// No description provided for @unitG.
  ///
  /// In ru, this message translates to:
  /// **'г'**
  String get unitG;

  /// No description provided for @unitKg.
  ///
  /// In ru, this message translates to:
  /// **'кг'**
  String get unitKg;

  /// No description provided for @unitCm.
  ///
  /// In ru, this message translates to:
  /// **'см'**
  String get unitCm;

  /// No description provided for @dayMon.
  ///
  /// In ru, this message translates to:
  /// **'ПН'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In ru, this message translates to:
  /// **'ВТ'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In ru, this message translates to:
  /// **'СР'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In ru, this message translates to:
  /// **'ЧТ'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In ru, this message translates to:
  /// **'ПТ'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In ru, this message translates to:
  /// **'СБ'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In ru, this message translates to:
  /// **'ВС'**
  String get daySun;

  /// No description provided for @monthJan.
  ///
  /// In ru, this message translates to:
  /// **'января'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In ru, this message translates to:
  /// **'февраля'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In ru, this message translates to:
  /// **'марта'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In ru, this message translates to:
  /// **'апреля'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In ru, this message translates to:
  /// **'мая'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In ru, this message translates to:
  /// **'июня'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In ru, this message translates to:
  /// **'июля'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In ru, this message translates to:
  /// **'августа'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In ru, this message translates to:
  /// **'сентября'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In ru, this message translates to:
  /// **'октября'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In ru, this message translates to:
  /// **'ноября'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In ru, this message translates to:
  /// **'декабря'**
  String get monthDec;

  /// No description provided for @workoutDetailCta.
  ///
  /// In ru, this message translates to:
  /// **'Начать тренировку'**
  String get workoutDetailCta;

  /// No description provided for @exercisesSection.
  ///
  /// In ru, this message translates to:
  /// **'Упражнения'**
  String get exercisesSection;

  /// No description provided for @statMin.
  ///
  /// In ru, this message translates to:
  /// **'МИН'**
  String get statMin;

  /// No description provided for @statKcal.
  ///
  /// In ru, this message translates to:
  /// **'ККАЛ'**
  String get statKcal;

  /// No description provided for @statExercises.
  ///
  /// In ru, this message translates to:
  /// **'УПР.'**
  String get statExercises;

  /// No description provided for @liveExerciseProgress.
  ///
  /// In ru, this message translates to:
  /// **'Упражнение {current} из {total}'**
  String liveExerciseProgress(int current, int total);

  /// No description provided for @liveSetLabel.
  ///
  /// In ru, this message translates to:
  /// **'Подход {n}'**
  String liveSetLabel(int n);

  /// No description provided for @liveSetProgress.
  ///
  /// In ru, this message translates to:
  /// **'Подход {current} из {total}'**
  String liveSetProgress(int current, int total);

  /// No description provided for @liveReps.
  ///
  /// In ru, this message translates to:
  /// **'Повторения'**
  String get liveReps;

  /// No description provided for @liveWeightKg.
  ///
  /// In ru, this message translates to:
  /// **'Вес, кг'**
  String get liveWeightKg;

  /// No description provided for @liveSkip.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get liveSkip;

  /// No description provided for @liveDone.
  ///
  /// In ru, this message translates to:
  /// **'Подход выполнен'**
  String get liveDone;

  /// No description provided for @chatTitle.
  ///
  /// In ru, this message translates to:
  /// **'AI ассистент'**
  String get chatTitle;

  /// No description provided for @chatModeNutrition.
  ///
  /// In ru, this message translates to:
  /// **'Питание'**
  String get chatModeNutrition;

  /// No description provided for @chatModeNutritionDesc.
  ///
  /// In ru, this message translates to:
  /// **'Калории, БЖУ, рецепты'**
  String get chatModeNutritionDesc;

  /// No description provided for @chatModeTraining.
  ///
  /// In ru, this message translates to:
  /// **'Тренировки'**
  String get chatModeTraining;

  /// No description provided for @chatModeTrainingDesc.
  ///
  /// In ru, this message translates to:
  /// **'Программа, форма, советы'**
  String get chatModeTrainingDesc;

  /// No description provided for @chatPlaceholderNutrition.
  ///
  /// In ru, this message translates to:
  /// **'Что ты ел сегодня?'**
  String get chatPlaceholderNutrition;

  /// No description provided for @chatPlaceholderTraining.
  ///
  /// In ru, this message translates to:
  /// **'Спроси про технику…'**
  String get chatPlaceholderTraining;

  /// No description provided for @chatNetworkError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сети. Попробуйте снова.'**
  String get chatNetworkError;

  /// No description provided for @accountTitle.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт'**
  String get accountTitle;

  /// No description provided for @accountSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Профиль · настройки'**
  String get accountSubtitle;

  /// No description provided for @sectionProgram.
  ///
  /// In ru, this message translates to:
  /// **'ПРОГРАММА'**
  String get sectionProgram;

  /// No description provided for @sectionEquipment.
  ///
  /// In ru, this message translates to:
  /// **'ОБОРУДОВАНИЕ'**
  String get sectionEquipment;

  /// No description provided for @sectionLegal.
  ///
  /// In ru, this message translates to:
  /// **'ПРАВОВЫЕ И ДАННЫЕ'**
  String get sectionLegal;

  /// No description provided for @sectionBody.
  ///
  /// In ru, this message translates to:
  /// **'ПАРАМЕТРЫ ТЕЛА'**
  String get sectionBody;

  /// No description provided for @sectionApp.
  ///
  /// In ru, this message translates to:
  /// **'ПРИЛОЖЕНИЕ'**
  String get sectionApp;

  /// No description provided for @equipmentCount.
  ///
  /// In ru, this message translates to:
  /// **'{count} выбрано'**
  String equipmentCount(int count);

  /// No description provided for @equipmentHint.
  ///
  /// In ru, this message translates to:
  /// **'Тренировки подбираются под доступный инвентарь. Тапни, чтобы включить или выключить.'**
  String get equipmentHint;

  /// No description provided for @equipmentBanner.
  ///
  /// In ru, this message translates to:
  /// **'Доступно ~{count} упражнений в библиотеке'**
  String equipmentBanner(int count);

  /// No description provided for @equipmentExtended.
  ///
  /// In ru, this message translates to:
  /// **'Расширенный выбор оборудования'**
  String get equipmentExtended;

  /// No description provided for @equipmentExtendedSub.
  ///
  /// In ru, this message translates to:
  /// **'вес / типы ›'**
  String get equipmentExtendedSub;

  /// No description provided for @rowGoal.
  ///
  /// In ru, this message translates to:
  /// **'Цель'**
  String get rowGoal;

  /// No description provided for @rowNutrition.
  ///
  /// In ru, this message translates to:
  /// **'Питание'**
  String get rowNutrition;

  /// No description provided for @rowTrainings.
  ///
  /// In ru, this message translates to:
  /// **'Тренировки'**
  String get rowTrainings;

  /// No description provided for @rowAiServices.
  ///
  /// In ru, this message translates to:
  /// **'AI сервисы'**
  String get rowAiServices;

  /// No description provided for @rowAiServicesSub.
  ///
  /// In ru, this message translates to:
  /// **'OpenAI · USDA database'**
  String get rowAiServicesSub;

  /// No description provided for @rowPrivacy.
  ///
  /// In ru, this message translates to:
  /// **'Конфиденциальность'**
  String get rowPrivacy;

  /// No description provided for @rowPrivacySub.
  ///
  /// In ru, this message translates to:
  /// **'Настройки данных'**
  String get rowPrivacySub;

  /// No description provided for @rowPrivacyPolicy.
  ///
  /// In ru, this message translates to:
  /// **'Privacy Policy'**
  String get rowPrivacyPolicy;

  /// No description provided for @rowTerms.
  ///
  /// In ru, this message translates to:
  /// **'Terms of Use'**
  String get rowTerms;

  /// No description provided for @rowAiModels.
  ///
  /// In ru, this message translates to:
  /// **'AI-модели'**
  String get rowAiModels;

  /// No description provided for @rowAiModelsSub.
  ///
  /// In ru, this message translates to:
  /// **'Согласие на обработку'**
  String get rowAiModelsSub;

  /// No description provided for @rowAiModelsAction.
  ///
  /// In ru, this message translates to:
  /// **'Вкл ›'**
  String get rowAiModelsAction;

  /// No description provided for @rowExport.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт данных'**
  String get rowExport;

  /// No description provided for @rowWeight.
  ///
  /// In ru, this message translates to:
  /// **'Вес'**
  String get rowWeight;

  /// No description provided for @rowHeight.
  ///
  /// In ru, this message translates to:
  /// **'Рост'**
  String get rowHeight;

  /// No description provided for @rowAge.
  ///
  /// In ru, this message translates to:
  /// **'Возраст'**
  String get rowAge;

  /// No description provided for @rowNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get rowNotifications;

  /// No description provided for @rowLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get rowLanguage;

  /// No description provided for @rowSubscription.
  ///
  /// In ru, this message translates to:
  /// **'Подписка'**
  String get rowSubscription;

  /// No description provided for @rowDeleteAccount.
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт'**
  String get rowDeleteAccount;

  /// No description provided for @rowHelp.
  ///
  /// In ru, this message translates to:
  /// **'Помощь и поддержка'**
  String get rowHelp;

  /// No description provided for @logout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из аккаунта'**
  String get logout;

  /// No description provided for @appVersion.
  ///
  /// In ru, this message translates to:
  /// **'Кайфит · v{version}'**
  String appVersion(String version);

  /// No description provided for @statsTrainings.
  ///
  /// In ru, this message translates to:
  /// **'тренировок'**
  String get statsTrainings;

  /// No description provided for @statsWeeks.
  ///
  /// In ru, this message translates to:
  /// **'недель'**
  String get statsWeeks;

  /// No description provided for @statsKgLost.
  ///
  /// In ru, this message translates to:
  /// **'кг'**
  String get statsKgLost;

  /// No description provided for @proLabel.
  ///
  /// In ru, this message translates to:
  /// **'★ Pro · до {date}'**
  String proLabel(String date);

  /// No description provided for @freeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Бесплатный'**
  String get freeLabel;

  /// No description provided for @tabJournal.
  ///
  /// In ru, this message translates to:
  /// **'Журнал'**
  String get tabJournal;

  /// No description provided for @tabChat.
  ///
  /// In ru, this message translates to:
  /// **'Чат'**
  String get tabChat;

  /// No description provided for @loading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка…'**
  String get loading;

  /// No description provided for @errorLoading.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки'**
  String get errorLoading;

  /// No description provided for @errorNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сети'**
  String get errorNetwork;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  String get addMealTitle;
  String get mealTypeBreakfast;
  String get mealTypeLunch;
  String get mealTypeDinner;
  String get mealTypeSnack;
  String get foodNameLabel;
  String get amountLabel;
  String get caloriesFieldLabel;
  String get proteinLabel;
  String get fatLabel;
  String get carbsLabel;
  String get saveMeal;
  String get mealSaved;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'ru':
      return AppL10nRu();
  }

  throw FlutterError(
      'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

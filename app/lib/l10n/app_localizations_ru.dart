// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppL10nRu extends AppL10n {
  AppL10nRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'KayFit';

  @override
  String get loginTitle => 'Войти';

  @override
  String get loginSubtitle => 'Введите данные вашего аккаунта';

  @override
  String get loginButton => 'Войти';

  @override
  String get loginError => 'Неверный email или пароль';

  @override
  String get noAccount => 'Нет аккаунта? Зарегистрироваться';

  @override
  String get registerTitle => 'Регистрация';

  @override
  String get createAccountButton => 'Создать аккаунт';

  @override
  String get registerError => 'Ошибка регистрации. Попробуйте снова.';

  @override
  String get emailHint => 'Email';

  @override
  String get passwordHint => 'Пароль';

  @override
  String get nameHint => 'Имя';

  @override
  String get obModulesTitle => 'Расскажи о своих целях';

  @override
  String get obModulesSubtitle =>
      'Включи нужные модули — приложение перестроится под тебя.';

  @override
  String get obModulesHint => 'Можешь поменять в Настройках в любой момент';

  @override
  String get nutritionModuleName => 'Питание';

  @override
  String get nutritionModuleDesc => 'Дневник, БЖУ, AI-нутрициолог';

  @override
  String get trainingModuleName => 'Тренировки';

  @override
  String get trainingModuleDesc => 'Программы, упражнения, AI-тренер';

  @override
  String get obEquipTitle => 'Чем тренируешься?';

  @override
  String get obEquipSubtitle => 'Подберём план под доступное оборудование.';

  @override
  String obEquipBanner(int count, int exercises) {
    return '$count выбрано — доступно ~$exercises упражнений';
  }

  @override
  String get continueButton => 'Продолжить';

  @override
  String get journalTitle => 'Журнал';

  @override
  String journalSubtitle(
      String dayName, int day, String month, int week, int totalWeeks) {
    return '$dayName, $day $month · Неделя $week из $totalWeeks';
  }

  @override
  String get sectionFood => 'Еда';

  @override
  String get sectionTraining => 'Тренировки';

  @override
  String get caloriesLabel => 'КАЛОРИИ СЕГОДНЯ';

  @override
  String caloriesGoal(int goal) {
    return '/ $goal ккал';
  }

  @override
  String get macroProtein => 'Б';

  @override
  String get macroFat => 'Ж';

  @override
  String get macroCarbs => 'У';

  @override
  String foodSectionSub(int kcal, int p, int c, int f) {
    return '$kcal ккал · БЖУ $p/$c/$f';
  }

  @override
  String trainingSectionSub(int week, int total) {
    return 'На сегодня · Неделя $week/$total';
  }

  @override
  String get addMeal => '+ Добавить приём пищи';

  @override
  String nextWorkout(String workout) {
    return 'Следующая: $workout ›';
  }

  @override
  String get unitMin => 'мин';

  @override
  String get unitExercises => 'упр.';

  @override
  String get unitKcal => 'ккал';

  @override
  String get unitG => 'г';

  @override
  String get unitKg => 'кг';

  @override
  String get unitCm => 'см';

  @override
  String get dayMon => 'ПН';

  @override
  String get dayTue => 'ВТ';

  @override
  String get dayWed => 'СР';

  @override
  String get dayThu => 'ЧТ';

  @override
  String get dayFri => 'ПТ';

  @override
  String get daySat => 'СБ';

  @override
  String get daySun => 'ВС';

  @override
  String get monthJan => 'января';

  @override
  String get monthFeb => 'февраля';

  @override
  String get monthMar => 'марта';

  @override
  String get monthApr => 'апреля';

  @override
  String get monthMay => 'мая';

  @override
  String get monthJun => 'июня';

  @override
  String get monthJul => 'июля';

  @override
  String get monthAug => 'августа';

  @override
  String get monthSep => 'сентября';

  @override
  String get monthOct => 'октября';

  @override
  String get monthNov => 'ноября';

  @override
  String get monthDec => 'декабря';

  @override
  String get workoutDetailCta => 'Начать тренировку';

  @override
  String get exercisesSection => 'Упражнения';

  @override
  String get statMin => 'МИН';

  @override
  String get statKcal => 'ККАЛ';

  @override
  String get statExercises => 'УПР.';

  @override
  String liveExerciseProgress(int current, int total) {
    return 'Упражнение $current из $total';
  }

  @override
  String liveSetLabel(int n) {
    return 'Подход $n';
  }

  @override
  String liveSetProgress(int current, int total) {
    return 'Подход $current из $total';
  }

  @override
  String get liveReps => 'Повторения';

  @override
  String get liveWeightKg => 'Вес, кг';

  @override
  String get liveSkip => 'Пропустить';

  @override
  String get liveDone => 'Подход выполнен';

  @override
  String get chatTitle => 'AI ассистент';

  @override
  String get chatModeNutrition => 'Питание';

  @override
  String get chatModeNutritionDesc => 'Калории, БЖУ, рецепты';

  @override
  String get chatModeTraining => 'Тренировки';

  @override
  String get chatModeTrainingDesc => 'Программа, форма, советы';

  @override
  String get chatPlaceholderNutrition => 'Что ты ел сегодня?';

  @override
  String get chatPlaceholderTraining => 'Спроси про технику…';

  @override
  String get chatNetworkError => 'Ошибка сети. Попробуйте снова.';

  @override
  String get accountTitle => 'Аккаунт';

  @override
  String get accountSubtitle => 'Профиль · настройки';

  @override
  String get sectionProgram => 'ПРОГРАММА';

  @override
  String get sectionEquipment => 'ОБОРУДОВАНИЕ';

  @override
  String get sectionLegal => 'ПРАВОВЫЕ И ДАННЫЕ';

  @override
  String get sectionBody => 'ПАРАМЕТРЫ ТЕЛА';

  @override
  String get sectionApp => 'ПРИЛОЖЕНИЕ';

  @override
  String equipmentCount(int count) {
    return '$count выбрано';
  }

  @override
  String get equipmentHint =>
      'Тренировки подбираются под доступный инвентарь. Тапни, чтобы включить или выключить.';

  @override
  String equipmentBanner(int count) {
    return 'Доступно ~$count упражнений в библиотеке';
  }

  @override
  String get equipmentExtended => 'Расширенный выбор оборудования';

  @override
  String get equipmentExtendedSub => 'вес / типы ›';

  @override
  String get rowGoal => 'Цель';

  @override
  String get rowNutrition => 'Питание';

  @override
  String get rowTrainings => 'Тренировки';

  @override
  String get rowAiServices => 'AI сервисы';

  @override
  String get rowAiServicesSub => 'OpenAI · USDA database';

  @override
  String get rowPrivacy => 'Конфиденциальность';

  @override
  String get rowPrivacySub => 'Настройки данных';

  @override
  String get rowPrivacyPolicy => 'Privacy Policy';

  @override
  String get rowTerms => 'Terms of Use';

  @override
  String get rowAiModels => 'AI-модели';

  @override
  String get rowAiModelsSub => 'Согласие на обработку';

  @override
  String get rowAiModelsAction => 'Вкл ›';

  @override
  String get rowExport => 'Экспорт данных';

  @override
  String get rowWeight => 'Вес';

  @override
  String get rowHeight => 'Рост';

  @override
  String get rowAge => 'Возраст';

  @override
  String get rowNotifications => 'Уведомления';

  @override
  String get rowLanguage => 'Язык';

  @override
  String get rowSubscription => 'Подписка';

  @override
  String get rowDeleteAccount => 'Удалить аккаунт';

  @override
  String get rowHelp => 'Помощь и поддержка';

  @override
  String get logout => 'Выйти из аккаунта';

  @override
  String appVersion(String version) {
    return 'Кайфит · v$version';
  }

  @override
  String get statsTrainings => 'тренировок';

  @override
  String get statsWeeks => 'недель';

  @override
  String get statsKgLost => 'кг';

  @override
  String proLabel(String date) {
    return '★ Pro · до $date';
  }

  @override
  String get freeLabel => 'Бесплатный';

  @override
  String get tabJournal => 'Журнал';

  @override
  String get tabChat => 'Чат';

  @override
  String get loading => 'Загрузка…';

  @override
  String get errorLoading => 'Ошибка загрузки';

  @override
  String get errorNetwork => 'Ошибка сети';

  @override
  String get retry => 'Повторить';

  @override
  String get addMealTitle => 'Добавить приём пищи';

  @override
  String get mealTypeBreakfast => 'Завтрак';

  @override
  String get mealTypeLunch => 'Обед';

  @override
  String get mealTypeDinner => 'Ужин';

  @override
  String get mealTypeSnack => 'Перекус';

  @override
  String get foodNameLabel => 'Название блюда';

  @override
  String get amountLabel => 'Количество, г';

  @override
  String get caloriesFieldLabel => 'Ккал';

  @override
  String get proteinLabel => 'Белки, г';

  @override
  String get fatLabel => 'Жиры, г';

  @override
  String get carbsLabel => 'Углеводы, г';

  @override
  String get saveMeal => 'Добавить';

  @override
  String get mealSaved => 'Приём пищи добавлен';

  @override
  String get addSheetFood => 'Еда';

  @override
  String get addSheetFoodDesc => 'Фото, голос, текст или штрихкод';

  @override
  String get addSheetWorkout => 'Тренировка';

  @override
  String get addSheetWorkoutDesc => 'Начать или выбрать программу';

  @override
  String get addSheetWater => 'Вода';

  @override
  String get addSheetWaterDesc => 'Добавить стакан воды';

  @override
  String get addSheetWeight => 'Вес';

  @override
  String get addSheetWeightDesc => 'Записать замер веса';

  @override
  String get cancel => 'Отмена';

  @override
  String get dialogAddWater => 'Добавить воду';

  @override
  String get dialogRecordWeight => 'Записать вес';

  @override
  String get unitMl => 'мл';

  @override
  String get micNoAccess => 'Нет доступа к микрофону';

  @override
  String get recognizePhotoError => 'Не удалось распознать еду на фото';

  @override
  String get errorGeneric => 'Что-то пошло не так. Попробуйте ещё раз.';

  @override
  String get addFoodTitle => 'Добавить еду';

  @override
  String get methodPhotoTitle => 'Фото';

  @override
  String get methodPhotoDesc => 'Сфотографируй — AI распознает за 5 сек';

  @override
  String get methodVoiceTitle => 'Голос';

  @override
  String get methodVoiceDesc => '«Съел борщ 300 мл» — просто скажи';

  @override
  String get methodTextTitle => 'Текст';

  @override
  String get methodTextDesc => 'Напиши что съел — AI посчитает КБЖУ';

  @override
  String get methodBarcodeTitle => 'Штрихкод';

  @override
  String get methodBarcodeDesc => 'Сканировать упаковку продукта';

  @override
  String get textInputHint => 'Что съел? Опиши приём пищи…';

  @override
  String get voiceRecordingTitle => 'Запись…';

  @override
  String get voiceInputTitle => 'Голосовой ввод';

  @override
  String get voiceHintStop => 'Нажми, чтобы остановить запись';

  @override
  String get voiceHintStart => 'Нажми на кнопку и скажи что ел';

  @override
  String get recognizingVoice => 'Распознаём речь…';

  @override
  String get recognizingPhoto => 'Анализируем фото…';

  @override
  String get parsingStep1 => 'Разбиваем на ингредиенты';

  @override
  String get parsingStep2 => 'Ищем нутриенты в базе';

  @override
  String get parsingStep3 => 'Рассчитываем КБЖУ';

  @override
  String get parsingStep4 => 'Формируем результат';

  @override
  String get analyzingTitle => 'Анализирую';

  @override
  String get photoSourceTitle => 'Фото';

  @override
  String get photoCamera => 'Сделать фото';

  @override
  String get photoGallery => 'Выбрать из галереи';

  @override
  String get barcodeNotFound =>
      'Продукт не найден. Попробуйте другой штрихкод.';

  @override
  String get barcodeScanHint => 'Наведи камеру на штрихкод';

  @override
  String get saveError => 'Не удалось сохранить';

  @override
  String get programsTitle => 'Программы тренировок';

  @override
  String get programsEmpty => 'Нет доступных программ';

  @override
  String programSelected(String name) {
    return 'Программа \"$name\" выбрана';
  }

  @override
  String get programSelectError => 'Ошибка выбора программы';

  @override
  String get labelWeeks => 'НЕДЕЛЬ';

  @override
  String get labelType => 'ТИП';

  @override
  String get select => 'Выбрать';

  @override
  String get barcodeLoading => 'Загружаю...';

  @override
  String get retryLabel => 'Повторить';

  @override
  String get barcodeManualHint => 'Ввести код вручную';

  @override
  String get barcodeManualTitle => 'Введите штрихкод';

  @override
  String get barcodeManualFormats => 'EAN-8, EAN-13, UPC-A и другие форматы';

  @override
  String get barcodeManualPlaceholder => 'Например: 4607086562619';

  @override
  String get barcodeSearch => 'Найти';

  @override
  String recognizedCount(int count) {
    return 'РАСПОЗНАНО · $count';
  }

  @override
  String get fillFoodFields => 'Заполните название, количество и калории';

  @override
  String get foodNameHint => 'Гречка с курицей';

  @override
  String get aiRecognize => 'AI распознать';

  @override
  String get aiDetermines => 'AI определяет состав блюда';
}

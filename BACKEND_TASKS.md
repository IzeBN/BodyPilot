# Backend Tasks — Единый бэкенд KayFit + FitKeep

> Задачи организованы по эпикам. Каждая задача содержит описание **что делаем**, **зачем это нужно**, **детали реализации**.
> Оценки оставлены пустыми для заполнения вручную.

---

## Ключевые принципы

- **Логика обоих приложений сохраняется полностью.** Переносим, не переписываем.
- **Единый онбординг** — объединяем вопросы из двух квизов. Все остальные функции (дневник питания, тренировки, AI, подбор программ, оборудование, достижения и т.д.) переносятся без изменений логики.
- **Мультиязычность:** все данные, которые видит пользователь и которые берутся из БД, должны быть переведены. Используем существующую таблицу `translations` из FitnesBot. Базовый язык — `ru`. Добавляем `en`. Язык определяется из заголовка `Accept-Language`.

---

## ЭПИК 1: Unified Database & Schema

---

### TASK-BE-001 — Создать схему unified БД: таблица `users`

**Что делаем:**
Создать новую таблицу `users` в PostgreSQL, которая объединяет пользователей из обоих продуктов в единую сущность. Написать SQL-миграцию с полным набором полей.

**Зачем:**
Сейчас пользователи существуют в двух разных БД: Calories (пользователи KayFit) и FitnesBot (`all_users` — пользователи FitKeep). Для единого приложения нужна единая таблица, которая является источником правды для аутентификации и профиля.

**Детали реализации:**
```sql
CREATE TABLE users (
    id              SERIAL PRIMARY KEY,
    email           VARCHAR(256) UNIQUE NOT NULL,
    password_hash   VARCHAR(512),             -- null если только соц. сеть
    fullname        VARCHAR(128),
    telegram_user_id BIGINT UNIQUE,            -- для связи с ботом
    phone           VARCHAR(32),
    avatar_url      TEXT,
    language        VARCHAR(8) DEFAULT 'ru',
    ai_consent      BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP,
    is_deleted      BOOLEAN DEFAULT FALSE
);
```

**Оценка:** 3ч

---

### TASK-BE-002 — Создать таблицу `refresh_tokens`

**Что делаем:**
Создать таблицу для хранения refresh токенов с привязкой к пользователю. Реализовать хранение хэша токена (не plain text), поддержку нескольких устройств, флаг отзыва.

**Зачем:**
Безопасная реализация JWT refresh flow — единственный способ безопасно инвалидировать токены при logout и при компрометации. Хранение хэша вместо plain text защищает от утечки при компрометации БД.

**Детали реализации:**
```sql
CREATE TABLE refresh_tokens (
    id          SERIAL PRIMARY KEY,
    user_id     INT REFERENCES users(id) ON DELETE CASCADE,
    token_hash  VARCHAR(256) NOT NULL,    -- bcrypt hash refresh_token
    device_info VARCHAR(256),
    expires_at  TIMESTAMP NOT NULL,
    created_at  TIMESTAMP DEFAULT NOW(),
    is_revoked  BOOLEAN DEFAULT FALSE
);
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_hash ON refresh_tokens(token_hash);
```
При логине: сохранить hash(refresh_token).
При refresh: найти по hash, проверить is_revoked и expires_at, выдать новую пару и отозвать старый.

**Оценка:** 2ч

---

### TASK-BE-003 — Создать `user_nutrition_profile` и `user_training_profile`

**Что делаем:**
Создать две таблицы — профиль питания и профиль тренировок — связанные с таблицей `users`. Каждая хранит специфичные данные своего модуля.

**Зачем:**
Разделение данных по доменам позволяет независимо развивать модули nutrition и training. Пользователь может иметь только один из профилей (если подписался только на один модуль), или оба.

**Детали реализации:**
```sql
CREATE TABLE user_nutrition_profile (
    user_id             INT PRIMARY KEY REFERENCES users(id),
    goal_type           VARCHAR(32),       -- weight_loss, maintenance, muscle_gain
    current_weight_kg   FLOAT,
    target_weight_kg    FLOAT,
    height_cm           FLOAT,
    age                 INT,
    gender              VARCHAR(8),        -- male, female
    activity_level      SMALLINT,          -- 1..5
    calories_goal       INT,
    protein_goal_g      INT,
    fat_goal_g          INT,
    carbs_goal_g        INT,
    dietary_restrictions TEXT[],
    updated_at          TIMESTAMP
);

CREATE TABLE user_training_profile (
    user_id                 INT PRIMARY KEY REFERENCES users(id),
    gender                  VARCHAR(8),
    age                     INT,
    height_cm               FLOAT,
    current_weight_kg       FLOAT,
    experience_level        VARCHAR(16),   -- beginner, intermediate, advanced
    current_fat_percentage  FLOAT,
    desired_fat_percentage  FLOAT,
    preferred_duration_min  INT,
    injuries                TEXT,
    training_type_pref      VARCHAR(16),   -- strength, cardio, mixed
    training_sample_id      INT,           -- текущая программа
    trainer_id              BIGINT,
    club_id                 INT,
    select_samples          VARCHAR(32),   -- 'Required ancet' / 'Selected' / ...
    updated_at              TIMESTAMP
);
```

**Оценка:** 3ч

---

### TASK-BE-004 — Создать `subscriptions` и `subscription_plans`

**Что делаем:**
Спроектировать и создать таблицы для единой подписки: планы тарифов и активные подписки пользователей.

**Зачем:**
Сейчас подписки управляются независимо в двух продуктах. Единая подписка означает единую запись в БД, единую проверку доступа и единое управление оплатой. Пользователь платит один раз и получает доступ к обоим модулям.

**Детали реализации:**
```sql
CREATE TABLE subscription_plans (
    id                  SERIAL PRIMARY KEY,
    name                VARCHAR(64),
    term_days           INT,
    price_rub           INT,
    price_stars         INT,
    includes_nutrition  BOOLEAN DEFAULT TRUE,
    includes_training   BOOLEAN DEFAULT TRUE,
    includes_ai_chat    BOOLEAN DEFAULT TRUE,
    includes_trainer    BOOLEAN DEFAULT FALSE,
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMP DEFAULT NOW()
);

CREATE TABLE subscriptions (
    id              SERIAL PRIMARY KEY,
    user_id         INT REFERENCES users(id),
    plan_id         INT REFERENCES subscription_plans(id),
    status          VARCHAR(16),    -- trial, active, expired, cancelled
    started_at      TIMESTAMP,
    expires_at      TIMESTAMP,
    payment_type    VARCHAR(32),    -- stripe, apple, google, telegram_stars
    external_sub_id VARCHAR(256),
    auto_renew      BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_subscriptions_user ON subscriptions(user_id);
```

**Оценка:** 3ч

---

### TASK-BE-005 — Создать `chat_messages` для unified chat

**Что делаем:**
Создать таблицу для хранения истории сообщений unified чата с поддержкой разных agent_type (nutritionist, trainer, general) и conversation_id для разбивки по диалогам.

**Зачем:**
Для AI чата нужно хранить историю, чтобы подавать её в контекст LLM и давать пользователю возможность просматривать прошлые диалоги. `agent_type` позволяет разделять историю по агентам для аналитики.

**Детали реализации:**
```sql
CREATE TABLE chat_messages (
    id              SERIAL PRIMARY KEY,
    user_id         INT REFERENCES users(id),
    conversation_id UUID NOT NULL,
    role            VARCHAR(16),    -- user, assistant
    content         TEXT NOT NULL,
    agent_type      VARCHAR(16),    -- nutritionist, trainer, general
    created_at      TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_chat_messages_user_conv ON chat_messages(user_id, conversation_id);
CREATE INDEX idx_chat_messages_created ON chat_messages(created_at DESC);
```

**Оценка:** 2ч

---

### TASK-BE-006 — Создать `quiz_answers` для unified онбординга

**Что делаем:**
Создать единую таблицу для хранения ответов на вопросы онбординга. Поддерживать разные модули (common, nutrition, training) и типы ответов.

**Зачем:**
Объединение квизов из двух приложений в одной таблице с разметкой по `module` позволяет бэкенду использовать ответы для:
- расчёта КБЖУ норм (nutrition profile)
- матчинга программы тренировок
- персонализации AI агентов

**Детали реализации:**
```sql
CREATE TABLE quiz_answers (
    id              SERIAL PRIMARY KEY,
    user_id         INT REFERENCES users(id),
    question_key    VARCHAR(64) NOT NULL,
    answer_value    TEXT,
    answer_type     VARCHAR(16),    -- text, int, float, bool, choice, multichoice
    module          VARCHAR(16),    -- common, nutrition, training
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP,
    UNIQUE(user_id, question_key)   -- один ответ на вопрос
);
```

**Оценка:** 2ч

---

### TASK-BE-007 — Создать таблицы nutrition модуля (meals, foods, meal_items)

**Что делаем:**
Создать полную схему для дневника питания: таблицы `foods` (справочник продуктов), `meals` (приёмы пищи), `meal_items` (позиции внутри приёма пищи).

**Зачем:**
Весь функционал трекинга калорий (из KayFit / Calories бэкенда) должен работать в unified бэкенде. Нужно воссоздать схему из Calories, адаптировав `user_id` под новую таблицу `users`.

**Детали реализации:**
```sql
CREATE TABLE foods (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(256) NOT NULL,
    name_en         VARCHAR(256),
    barcode         VARCHAR(64) UNIQUE,
    calories_100g   FLOAT,
    protein_100g    FLOAT,
    fat_100g        FLOAT,
    carbs_100g      FLOAT,
    fiber_100g      FLOAT,
    sugar_100g      FLOAT,
    source          VARCHAR(32),    -- user, openfoodfacts, ai_recognized
    created_by      INT REFERENCES users(id),
    created_at      TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_foods_barcode ON foods(barcode);

CREATE TABLE meals (
    id          SERIAL PRIMARY KEY,
    user_id     INT REFERENCES users(id),
    meal_type   VARCHAR(16),    -- breakfast, lunch, dinner, snack
    eaten_at    TIMESTAMP,
    notes       TEXT,
    emotion     VARCHAR(32),
    created_at  TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_meals_user_date ON meals(user_id, eaten_at);

CREATE TABLE meal_items (
    id          SERIAL PRIMARY KEY,
    meal_id     INT REFERENCES meals(id) ON DELETE CASCADE,
    food_id     INT REFERENCES foods(id),
    food_name   VARCHAR(256),   -- если food_id = null (кастомный)
    quantity_g  FLOAT,
    calories    FLOAT,
    protein     FLOAT,
    fat         FLOAT,
    carbs       FLOAT
);
```

**Оценка:** 4ч

---

### TASK-BE-008 — Адаптировать таблицы FitnesBot: заменить `all_users` FK на `users`

**Что делаем:**
Изменить все внешние ключи в таблицах FitnesBot (`schedule_trainings`, `exercize_results`, `user_exercize_parameters`, `user_individual_data`, `start_quest_result` и др.), которые ссылаются на `all_users(user_id)`, — перевести их на `users(id)`.

**Зачем:**
Существующие таблицы тренировочного модуля должны работать с единой таблицей `users`. Без этой задачи невозможно связать тренировочные данные пользователя с его единым аккаунтом.

**Детали реализации:**
1. Написать миграцию: `ALTER TABLE ... ADD COLUMN internal_user_id INT REFERENCES users(id)`
2. Создать маппинг: `all_users.internal_user_id → users.id`
3. Постепенно заменить FK: старые запросы по `telegram_user_id` → lookup через `users.telegram_user_id`
4. Написать скрипт проверки целостности данных
5. После стабилизации: удалить прямые FK на `all_users` из основных таблиц

**Таблицы для изменения:**
- `start_quest_result`
- `user_individual_data`
- `user_actions`
- `user_exercize_parameters`
- `user_max_weight`
- `schedule_trainings`
- `user_chats` (заменить на `chat_messages`)
- `trainer_clients`
- `subscribers` → заменить на `subscriptions`

**Оценка:** 8ч

---

### TASK-BE-009 — Миграция пользователей из Calories + FitnesBot → unified users

**Что делаем:**
Написать и протестировать скрипт миграции пользователей из обеих существующих БД в новую unified таблицу `users`. Обработать конфликты (один email в обоих продуктах).

**Зачем:**
Существующие пользователи должны без потерь переехать в новую систему. Пользователь, у которого был аккаунт в обоих приложениях, должен получить один объединённый аккаунт. Без миграции придётся просить всех пользователей регистрироваться заново.

**Детали реализации:**
```python
# Стратегия merge:
# 1. Загрузить всех users из Calories (email + password_hash + fullname)
# 2. Загрузить всех users из FitnesBot.all_users (telegram_id + fullname)
# 3. Для каждого Calories user:
#    - INSERT INTO unified.users (email, password_hash, fullname, ...)
#    - записать mapping: user_migrations(unified_id, source='calories', original_id)
# 4. Для каждого FitnesBot user с email:
#    - Найти unified user по email
#    - Если найден: UPDATE users SET telegram_user_id = ...
#    - Если нет: INSERT (email может отсутствовать у Telegram users)
#    - записать mapping
# 5. FitnesBot users без email → INSERT с telegram_user_id, без email

CREATE TABLE user_migrations (
    id              SERIAL PRIMARY KEY,
    unified_user_id INT REFERENCES users(id),
    source          VARCHAR(16),    -- calories, fitnesbot
    original_id     VARCHAR(64),
    migrated_at     TIMESTAMP DEFAULT NOW()
);
```

**Оценка:** 10ч

---

## ЭПИК 2: Auth Service

---

### TASK-BE-010 — Реализовать unified auth endpoints

**Что делаем:**
Реализовать полный набор auth endpoints в FastAPI: register, login, refresh, logout, me, apple, delete account. Единый JWT формат для обоих бывших продуктов.

**Зачем:**
Это основа всего. Без единой авторизации невозможен единый аккаунт. Оба мобильных клиента (переработанный под unified) должны аутентифицироваться через один endpoint с одинаковым форматом токенов.

**Детали реализации:**
```
POST /api/v1/auth/register  → { access_token, refresh_token, user_id }
POST /api/v1/auth/login     → { access_token, refresh_token, user_id }
POST /api/v1/auth/apple     → { access_token, refresh_token, user_id }
POST /api/v1/auth/google    → { access_token, refresh_token, user_id }
POST /api/v1/auth/refresh   → { access_token, refresh_token }
POST /api/v1/auth/logout    body: { refresh_token }
GET  /api/v1/auth/me        → полный профиль пользователя
DELETE /api/v1/auth/account
```

Требования:
- access_token: JWT, exp 15 min, payload: { sub: user_id, type: 'access' }
- refresh_token: JWT, exp 30 days, хранится в БД (hash)
- /me должен возвращать subscription, onboarding_completed, nutrition/training profile presence
- Rate limiting: 5 req/min на /register и /login
- Dependency `get_current_user` — декодирует access_token, возвращает user

**Оценка:** 8ч

---

### TASK-BE-011 — Middleware: проверка подписки

**Что делаем:**
Реализовать FastAPI dependency `require_subscription`, которая проверяет наличие активной подписки у пользователя. Применять её ко всем платным endpoint'ам.

**Зачем:**
Нужно централизованно защищать платный функционал (AI распознавание еды, AI чат, адаптивные тренировки). Без middleware каждый handler должен сам проверять подписку, что ведёт к ошибкам и дублированию.

**Детали реализации:**
```python
async def require_subscription(user = Depends(get_current_user), db = Depends(get_db)):
    sub = await db.get_active_subscription(user.id)
    if not sub:
        raise HTTPException(402, detail="Subscription required")
    return user

# Применять:
@router.post("/chat/message")
async def send_message(user = Depends(require_subscription)):
    ...

@router.post("/nutrition/foods/recognize")
async def recognize_food(user = Depends(require_subscription)):
    ...
```

HTTP 402 Payment Required — стандартный код для paywall, мобильный клиент уже умеет его обрабатывать (PaymentRequiredException в KayFit).

**Оценка:** 2ч

---

## ЭПИК 3: Chat Router

---

### TASK-BE-012 — Реализовать Chat Intent Classifier

**Что делаем:**
Написать сервис `ChatIntentClassifier`, который определяет тип запроса пользователя: `nutritionist`, `trainer` или `general`. На первом этапе — keyword matching с fallback к LLM-классификации.

**Зачем:**
Это ключевая логика unified чата. Без классификации невозможно направить запрос к правильному AI агенту. Ошибочная маршрутизация снижает качество ответов (тренировочный бот отвечает на вопросы о калориях — плохой UX).

**Детали реализации:**
```python
class ChatIntentClassifier:
    NUTRITION_KEYWORDS = [
        'калори', 'есть', 'питание', 'рацион', 'белок', 'жир', 'углевод',
        'вес', 'диет', 'кушать', 'продукт', 'рецепт', 'похудет', 'бжу',
        'завтрак', 'обед', 'ужин', 'перекус', 'голод', 'насыщен'
    ]
    TRAINING_KEYWORDS = [
        'трен', 'упражнен', 'мышц', 'жим', 'тяга', 'приседан', 'кардио',
        'подход', 'повторен', 'программа', 'тренер', 'зал', 'качалк',
        'гантел', 'штанг', 'пробежк', 'растяжк', 'восстановлен'
    ]

    def classify(self, message: str) -> Literal['nutritionist', 'trainer', 'general']:
        msg_lower = message.lower()
        nutrition_score = sum(1 for kw in self.NUTRITION_KEYWORDS if kw in msg_lower)
        training_score = sum(1 for kw in self.TRAINING_KEYWORDS if kw in msg_lower)

        if nutrition_score > training_score:
            return 'nutritionist'
        elif training_score > nutrition_score:
            return 'trainer'
        else:
            return 'general'  # или вызов LLM для уточнения
```

**Оценка:** 4ч

---

### TASK-BE-013 — Реализовать Chat Agents (Nutritionist, Trainer, General)

**Что делаем:**
Написать три AI агента, каждый со своим system prompt и контекстом. Агенты вызывают Claude/GPT API, передавая историю переписки + профиль пользователя.

**Зачем:**
Разные агенты = разная специализация. Нутрициолог знает о питании пользователя (сколько съел, цели по КБЖУ), тренер знает о программе тренировок. Без разделения ответы будут generic и неполезными.

**Детали реализации:**
```python
class NutritionistAgent:
    async def generate(self, user_id: int, message: str, history: list) -> str:
        profile = await db.get_nutrition_profile(user_id)
        today_summary = await db.get_today_meals_summary(user_id)

        system_prompt = f"""Ты личный нутрициолог.
        Профиль пользователя: вес {profile.current_weight_kg}кг, цель {profile.goal_type},
        норма калорий {profile.calories_goal} ккал/день.
        Сегодня съедено: {today_summary.calories} ккал
        (белки {today_summary.protein}г, жиры {today_summary.fat}г, углеводы {today_summary.carbs}г).
        Отвечай на русском языке, кратко, практично."""

        return await llm_client.chat(system_prompt, message, history[-20:])

class TrainerAgent:
    async def generate(self, user_id: int, message: str, history: list) -> str:
        profile = await db.get_training_profile(user_id)
        current_sample = await db.get_current_training_sample(user_id)

        system_prompt = f"""Ты персональный тренер.
        Опыт пользователя: {profile.experience_level}.
        Текущая программа: {current_sample.title if current_sample else 'не выбрана'}.
        Ограничения/травмы: {profile.injuries or 'нет'}.
        Отвечай на русском языке, давай конкретные практические советы."""

        return await llm_client.chat(system_prompt, message, history[-20:])
```

**Оценка:** 6ч

---

### TASK-BE-014 — Реализовать Chat API endpoints

**Что делаем:**
Написать FastAPI router для чата: POST /chat/message (отправить сообщение + получить ответ), GET /chat/history, DELETE /chat/history.

**Зачем:**
Это публичный контракт с мобильным приложением. Мобильный клиент должен знать точный формат запроса и ответа, чтобы правильно отображать сообщения и тип агента (например, показывать иконку нутрициолога или тренера рядом с ответом).

**Детали реализации:**
```python
@router.post("/message", response_model=ChatResponse)
async def send_message(
    req: ChatRequest,
    user = Depends(require_subscription),
    db = Depends(get_db)
):
    # 1. Classify intent
    intent = classifier.classify(req.message)

    # 2. Get history
    conversation_id = req.conversation_id or str(uuid4())
    history = await db.get_chat_history(user.id, conversation_id, limit=20)

    # 3. Get AI response
    agent = get_agent(intent)  # NutritionistAgent | TrainerAgent | GeneralAgent
    reply = await agent.generate(user.id, req.message, history)

    # 4. Save both messages
    await db.save_chat_message(user.id, conversation_id, 'user', req.message, intent)
    await db.save_chat_message(user.id, conversation_id, 'assistant', reply, intent)

    return ChatResponse(
        reply=reply,
        agent_type=intent,
        conversation_id=conversation_id
    )

@router.get("/history", response_model=ChatHistoryResponse)
async def get_history(
    conversation_id: str | None = None,
    limit: int = 50,
    offset: int = 0,
    user = Depends(get_current_user),
    db = Depends(get_db)
):
    ...
```

**Оценка:** 5ч

---

## ЭПИК 4: Nutrition Module

---

### TASK-BE-015 — Перенести / реализовать Nutrition API endpoints

**Что делаем:**
Перенести всю логику работы с питанием из Calories бэкенда в unified backend. Реализовать endpoints для дневника питания, CRUD для приёмов пищи, поиск продуктов.

**Зачем:**
Весь функционал KayFit (дневник питания, подсчёт КБЖУ, добавление еды) должен работать через unified backend. Это один из двух основных модулей приложения.

**Endpoints для реализации:**
```
GET  /api/v1/nutrition/journal?date=YYYY-MM-DD
POST /api/v1/nutrition/meals
DELETE /api/v1/nutrition/meals/{meal_id}
PATCH /api/v1/nutrition/meals/{meal_id}
POST /api/v1/nutrition/meals/{meal_id}/items
DELETE /api/v1/nutrition/meals/{meal_id}/items/{item_id}
PATCH /api/v1/nutrition/meals/{meal_id}/items/{item_id}
GET  /api/v1/nutrition/foods/search?q=&barcode=
GET  /api/v1/nutrition/stats?from=&to=
GET  /api/v1/nutrition/goals
PATCH /api/v1/nutrition/goals
```

Логика `/journal`:
- Вернуть все meals пользователя за дату
- Для каждого meal — все meal_items с данными продукта
- Посчитать totals (сумма калорий, БЖУ) за каждый meal
- Посчитать daily_totals
- Вернуть goals из user_nutrition_profile

**Оценка:** 10ч

---

### TASK-BE-016 — Перенести AI распознавание еды

**Что делаем:**
Перенести endpoint AI распознавания еды по фото из Calories бэкенда в unified backend. Endpoint принимает изображение (base64 или multipart) и возвращает распознанный продукт с КБЖУ.

**Зачем:**
Это ключевая платная фича KayFit — пользователь фотографирует еду и получает автоматический подсчёт калорий. Должна работать в unified backend под protect подписки.

**Детали реализации:**
```
POST /api/v1/nutrition/foods/recognize
  Auth: Bearer + require_subscription
  Request: multipart/form-data { image: File }
        OR { image_base64: str }
  Response: {
    food_name: str,
    calories_100g: float,
    protein_100g: float,
    fat_100g: float,
    carbs_100g: float,
    confidence: float    # 0..1
  }
```
Вызывает Vision API (Claude Vision / GPT-4V) с промптом для определения продукта и его КБЖУ.
Результат можно кэшировать и сохранять в таблицу `foods` как source='ai_recognized'.

**Оценка:** 5ч

---

### TASK-BE-017 — Endpoint расчёта КБЖУ норм (Way to Goal)

**Что делаем:**
Реализовать endpoint, который по данным квиза пользователя рассчитывает его персональные нормы калорий, белков, жиров и углеводов, а также прогноз достижения цели по весу.

**Зачем:**
Этот расчёт нужен на экране "Way to Goal" — пользователь видит, когда он достигнет целевого веса при текущем подходе. Также результат сохраняется в `user_nutrition_profile` как цели питания.

**Детали реализации:**
```
POST /api/v1/nutrition/calculate-goals
  Request: {
    age, weight_kg, height_cm, gender,
    activity_level,          # 1..5
    goal_type,               # weight_loss, maintenance, muscle_gain
    target_weight_kg
  }
  Response: {
    bmr: int,                # базовый обмен веществ (Mifflin-St Jeor)
    tdee: int,               # total daily energy expenditure
    calories_goal: int,      # с учётом цели (дефицит/профицит)
    protein_goal_g: int,
    fat_goal_g: int,
    carbs_goal_g: int,
    weeks_to_goal: int,      # прогноз недель
    weekly_change_kg: float  # кг в неделю
  }

# Формулы:
# BMR (мужчины) = 10*weight + 6.25*height - 5*age + 5
# BMR (женщины) = 10*weight + 6.25*height - 5*age - 161
# TDEE = BMR * activity_multiplier[level]
# weight_loss: calories = TDEE - 500 (дефицит ~0.5кг/нед)
# muscle_gain: calories = TDEE + 300
# maintenance: calories = TDEE
```

**Оценка:** 4ч

---

## ЭПИК 5: Training Module

---

### TASK-BE-018 — Адаптировать Training API endpoints к unified auth

**Что делаем:**
Адаптировать все существующие FitnesBot API endpoints (тренировки, упражнения, расписание, результаты) к новой системе авторизации: заменить проверку по `telegram_user_id` + Telegram InitData на стандартный JWT Bearer.

**Зачем:**
Сейчас FitnesBot авторизует запросы через `CheckInitData` (Telegram WebApp initData). Мобильное приложение работает по JWT. Нужно унифицировать — все запросы от мобильного приложения должны идти с JWT токеном.

**Детали реализации:**
- Убрать `CheckInitData` middleware для mobile endpoints
- Добавить `Depends(get_current_user)` к защищённым routes
- `user.id` (unified) использовать вместо `telegram_user_id` для lookup в training таблицах
- Создать маппинг: unified `user.id` → `all_users.internal_user_id` через `user_migrations`

**Endpoints для адаптации:**
```
POST /api/v1/training/programs/select   (был: /selectSample)
GET  /api/v1/training/schedule
GET  /api/v1/training/{id}
GET  /api/v1/training/{id}/exercise/{eid}
POST /api/v1/training/results
POST /api/v1/training/adaptive
GET  /api/v1/training/exercises/{id}/alternatives
POST /api/v1/training/{id}/replace-exercise
GET  /api/v1/training/progress
```

**Оценка:** 8ч

---

### TASK-BE-019 — Объединить quiz/onboarding endpoints для training

**Что делаем:**
Адаптировать quiz endpoints из FitnesBot (`/quiz/answer`, `/quiz/answer/find`) под unified схему: использовать новую таблицу `quiz_answers` вместо `start_quest_result` и `user_individual_data`.

**Зачем:**
Единый онбординг означает единую таблицу для ответов. Сейчас FitnesBot использует несколько таблиц для хранения данных квиза. Нужно консолидировать в `quiz_answers` и обеспечить единый API для mobile клиента.

**Детали реализации:**
```
POST /api/v1/quiz/answer
  { question_key: 'experience_level', answer: 'beginner', module: 'training' }
  → INSERT INTO quiz_answers (user_id, question_key, answer_value, module)
    ON CONFLICT (user_id, question_key) DO UPDATE SET answer_value = ...

POST /api/v1/quiz/answers/bulk
  { answers: [...] }

GET  /api/v1/quiz/answers?keys[]=gender&keys[]=experience_level
  → SELECT * FROM quiz_answers WHERE user_id = $1 AND question_key = ANY($2)

POST /api/v1/quiz/complete
  → Запустить матчинг программы тренировок
  → Рассчитать nutrition goals
  → Вернуть next_step
```

**Оценка:** 5ч

---

### TASK-BE-020 — Equipment API (адаптация)

**Что делаем:**
Адаптировать Equipment endpoints из FitnesBot для работы с unified auth. Убедиться, что `user_equipment` корректно привязывается к `users.id`.

**Зачем:**
Оборудование — ключевой параметр для подбора упражнений. Без корректного хранения выбранного оборудования система не сможет подобрать подходящую программу и упражнения.

**Endpoints:**
```
GET /api/v1/equipment           → список всего оборудования
GET /api/v1/equipment/my        → выбранное пользователем
PUT /api/v1/equipment/my        → сохранить выбор
```

**Оценка:** 3ч

---

## ЭПИК 6: Subscription Service

---

### TASK-BE-021 — Реализовать Subscription API

**Что делаем:**
Написать полный subscription сервис: просмотр планов, покупка подписки (интеграция с платёжными системами), восстановление покупки (App Store / Google Play), проверка статуса.

**Зачем:**
Единая подписка — ключевое бизнес-требование. Пользователь платит один раз и получает доступ к обоим модулям. Без unified subscription API мобильное приложение не сможет управлять оплатой.

**Endpoints:**
```
GET  /api/v1/subscription              → текущая подписка
GET  /api/v1/subscription/plans        → доступные планы
POST /api/v1/subscription/purchase     → инициировать оплату
POST /api/v1/subscription/restore      → восстановить (Apple/Google receipt)
POST /api/v1/subscription/webhook/stripe    → Stripe webhook
POST /api/v1/subscription/webhook/apple     → Apple webhook
POST /api/v1/subscription/webhook/google    → Google webhook
```

Логика `/restore`:
- Принять receipt (Apple) или purchase_token (Google)
- Верифицировать у Apple/Google
- Обновить `subscriptions` запись
- Вернуть новый статус

**Оценка:** 12ч

---

### TASK-BE-022 — Перенести Telegram Stars оплату

**Что делаем:**
Сохранить существующую логику оплаты через Telegram Stars из FitnesBot и интегрировать её в unified subscription сервис. Stars платежи должны создавать запись в `subscriptions`.

**Зачем:**
Telegram Stars — популярный способ оплаты для Telegram-аудитории. Большая часть пользователей FitKeep пришла через Telegram бот. Нельзя терять этот канал оплаты при объединении.

**Детали реализации:**
- FitnesBot bot обрабатывает Stars платёж через pre_checkout_query / successful_payment
- После успешного платежа: вызвать internal API → создать subscription в unified БД
- `POST /api/v1/internal/subscription/activate { user_telegram_id, plan_id, payment_type: 'telegram_stars' }`
- Internal endpoint защищён internal API key, не Bearer JWT

**Оценка:** 4ч

---

## ЭПИК 7: User Profile & Onboarding

---

### TASK-BE-023 — Реализовать User Profile endpoints

**Что делаем:**
Написать endpoints для управления профилем пользователя: просмотр, обновление, управление пуш-токенами, удаление аккаунта.

**Зачем:**
Раздел "Аккаунт" в мобильном приложении полностью зависит от этих endpoints. Пользователь должен иметь возможность редактировать своё имя, фото профиля, язык приложения.

**Endpoints:**
```
GET   /api/v1/user/profile
PATCH /api/v1/user/profile         { fullname?, avatar_url?, language? }
GET   /api/v1/user/nutrition-profile
PATCH /api/v1/user/nutrition-profile
GET   /api/v1/user/training-profile
PATCH /api/v1/user/training-profile
POST  /api/v1/user/push-token      { token, platform }
DELETE /api/v1/user/push-token     { token }
POST  /api/v1/user/ai-consent      { consent: bool }
```

**Оценка:** 5ч

---

### TASK-BE-024 — Реализовать Quiz Complete логику (автоматический расчёт)

**Что делаем:**
Реализовать endpoint `POST /api/v1/quiz/complete`, который после завершения онбординг квиза:
1. Читает все ответы пользователя
2. Рассчитывает nutrition goals (КБЖУ)
3. Запускает training sample matching
4. Возвращает следующий шаг

**Зачем:**
Это переходный endpoint онбординга. Без него бэкенд не знает, что пользователь завершил квиз, и не выполняет нужные автоматические действия (расчёт калорий, подбор программы). Мобильный клиент использует `next_step` в ответе для навигации.

**Детали реализации:**
```python
@router.post("/quiz/complete")
async def complete_quiz(user = Depends(get_current_user), db = Depends(get_db)):
    answers = await db.get_all_quiz_answers(user.id)

    # 1. Рассчитать nutrition goals
    nutrition_goals = calculate_nutrition_goals(answers)
    await db.save_nutrition_profile(user.id, nutrition_goals)

    # 2. Подобрать training sample (существующая логика TrainingSampleMatching)
    training_sample = await match_training_sample(user.id, answers)
    await db.save_training_profile_sample(user.id, training_sample.id if training_sample else None)

    # 3. Определить next_step
    has_equipment = await db.has_user_equipment(user.id)
    has_body_form = await db.has_quiz_answer(user.id, 'current_fat_percentage')

    if not has_equipment:
        next_step = 'equipment'
    elif not has_body_form:
        next_step = 'body_form'
    else:
        next_step = 'main'

    return { "next_step": next_step, "training_sample_assigned": training_sample is not None }
```

**Оценка:** 5ч

---

## ЭПИК 8: Infrastructure & DevOps

---

### TASK-BE-025 — Настроить unified FastAPI приложение (main.py, config, structure)

**Что делаем:**
Создать структуру нового unified FastAPI проекта: `main.py`, конфигурация (env vars), подключение к БД (asyncpg pool), регистрация всех routers, CORS middleware, error handlers.

**Зачем:**
Это фундамент, на котором строится всё остальное. Без правильной структуры проекта невозможно добавлять новые модули и поддерживать код.

**Детали реализации:**
```
unified_backend/
├── app/
│   ├── main.py           ← FastAPI(), include_router(auth, nutrition, training, chat, ...)
│   ├── config.py         ← Pydantic BaseSettings (DB_URL, JWT_SECRET, LLM_API_KEY, ...)
│   ├── database.py       ← asyncpg create_pool, get_db dependency
│   ├── dependencies.py   ← get_current_user, require_subscription
│   └── routers/
│       └── ...
├── requirements.txt
├── .env.example
└── Dockerfile
```

**ENV variables:**
```
DATABASE_URL=postgresql://...
JWT_SECRET=...
JWT_ACCESS_EXPIRE_MIN=15
JWT_REFRESH_EXPIRE_DAYS=30
ANTHROPIC_API_KEY=...   (или OPENAI_API_KEY)
APPLE_TEAM_ID=...
GOOGLE_CLIENT_ID=...
```

**Оценка:** 4ч

---

### TASK-BE-026 — Написать миграции БД (alembic или SQL scripts)

**Что делаем:**
Написать набор SQL миграций или Alembic скриптов для развёртывания полной unified схемы БД в правильном порядке. Включить rollback скрипты.

**Зачем:**
Без управляемых миграций невозможно воспроизводимо развернуть БД на новом сервере или откатить изменения при ошибке. Порядок миграций критически важен из-за FK constraints.

**Порядок миграций:**
```
001_create_users.sql
002_create_refresh_tokens.sql
003_create_subscription_plans.sql
004_create_subscriptions.sql
005_create_user_nutrition_profile.sql
006_create_user_training_profile.sql
007_create_foods.sql
008_create_meals.sql
009_create_meal_items.sql
010_create_quiz_answers.sql
011_create_chat_messages.sql
012_create_push_tokens.sql
013_create_user_migrations.sql
014_migrate_fitnesbot_schema.sql  ← добавить internal_user_id FK
015_seed_subscription_plans.sql   ← начальные данные тарифов
```

**Оценка:** 5ч

---

### TASK-BE-027 — GitHub Actions CI/CD для unified backend

**Что делаем:**
Создать GitHub Actions workflow для автоматического деплоя unified backend. По аналогии с существующими `DeployApp.yml` и `DeployBotDev.yml` в FitnesBot.

**Зачем:**
Continuous deployment ускоряет цикл разработки и исключает ручные ошибки при деплое. Workflow должен запускать миграции БД перед запуском нового кода.

**Детали:**
```yaml
# .github/workflows/DeployUnified.yml
# Триггер: push в main
# Steps:
# 1. SSH на сервер
# 2. git pull
# 3. pip install -r requirements.txt
# 4. Запустить новые миграции
# 5. Restart FastAPI (systemd / docker)
```

**Оценка:** 3ч

---

### TASK-BE-028 — Настроить пуш-уведомления (unified)

**Что делаем:**
Реализовать сохранение FCM/APNs токенов и отправку пуш-уведомлений для unified backend. Объединить нотификации из обоих продуктов: напоминания о питании (из KayFit) + напоминания о тренировках (из FitnesBot).

**Зачем:**
Push-уведомления — важный инструмент удержания пользователей. Оба приложения использовали их. В unified приложении один пользователь должен получать уведомления о тренировках И питании через единый пуш-токен.

**Детали реализации:**
```sql
CREATE TABLE push_tokens (
    id          SERIAL PRIMARY KEY,
    user_id     INT REFERENCES users(id),
    token       TEXT NOT NULL,
    platform    VARCHAR(8),    -- ios, android
    created_at  TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, token)
);
```

Scheduler задачи (перенести из FitnesBot, добавить nutrition):
- Напоминание о тренировке (TrainingNotif) — время из расписания
- Напоминание о заполнении дневника питания — если не вносил за день
- Напоминание вернуться (если неактивен N дней)

**Оценка:** 6ч

---

## ЭПИК 9: Telegram Bot Integration

---

### TASK-BE-029 — Обновить Telegram бот: переход на unified user_id

**Что делаем:**
Адаптировать Telegram бот (FitnesBot) для работы с unified таблицей `users` вместо `all_users`. Бот должен при первом контакте создавать/находить пользователя в unified БД по `telegram_user_id`.

**Зачем:**
Telegram бот остаётся важным каналом взаимодействия для тренерской части (тренеры управляют через бот). Без адаптации бот будет работать с устаревшей `all_users` таблицей и создавать несогласованность данных.

**Детали реализации:**
- В `StartAncet` handler: при `/start` → lookup/create в `unified.users` по `telegram_user_id`
- Все обращения к БД через `telegram_user_id` → сначала резолв в `unified_user_id`
- Вспомогательный метод: `db.get_or_create_user_by_telegram(telegram_user_id, username, fullname)`

**Оценка:** 5ч

---

## ЭПИК 10: Мультиязычность (i18n / l10n)

---

### TASK-BE-030 — Перенести таблицу `translations` в unified БД и настроить индексы

**Что делаем:**
Перенести существующую таблицу `translations` из FitnesBot в unified PostgreSQL. Проверить и при необходимости добавить индексы для быстрого lookup. Таблица не изменяется — только переезжает.

**Зачем:**
Таблица `translations` уже реализует правильный паттерн entity-based переводов. Она покрывает оборудование, упражнения и другие сущности. Её нужно сделать общей для всего unified backend, а не держать только в FitnesBot.

**Детали реализации:**
```sql
-- Таблица переносится без изменений:
CREATE TABLE IF NOT EXISTS translations (
    id          SERIAL PRIMARY KEY,
    entity_type VARCHAR(32) NOT NULL,
    entity_id   INT NOT NULL,
    lang        VARCHAR(8) NOT NULL,
    field       VARCHAR(64) NOT NULL,
    value       TEXT,
    CONSTRAINT translations_unique UNIQUE (entity_type, entity_id, lang, field)
);
-- Добавить индекс если отсутствует:
CREATE INDEX IF NOT EXISTS idx_translations_lookup
    ON translations(entity_type, entity_id, lang);
```

Данные из существующей БД FitnesBot экспортируются dump'ом и импортируются в unified БД.

**Оценка:** 2ч

---

### TASK-BE-031 — Реализовать i18n dependency и утилиту применения переводов

**Что делаем:**
Написать FastAPI dependency `get_lang` для извлечения языка из заголовка `Accept-Language`. Написать утилиты `get_translations(entity_type, entity_id, lang)` и `apply_bulk_translations(items, entity_type, lang)` для переиспользования во всех endpoints.

**Зачем:**
Без централизованной утилиты каждый endpoint будет дублировать логику запроса переводов и их применения. Это источник ошибок и несогласованности. Единая утилита гарантирует одинаковый паттерн во всём API.

**Детали реализации:**
```python
# app/dependencies.py
SUPPORTED_LANGS = {'ru', 'en'}

def get_lang(accept_language: str = Header(default='ru')) -> str:
    """Извлечь язык из Accept-Language header. Fallback: 'ru'."""
    lang = accept_language.split(',')[0].split('-')[0].strip().lower()
    return lang if lang in SUPPORTED_LANGS else 'ru'

# app/services/i18n.py
async def get_translations(
    conn, entity_type: str, entity_id: int, lang: str
) -> dict[str, str]:
    """Получить переводы одной сущности. Возвращает {} для ru (базовый язык)."""
    if lang == 'ru':
        return {}
    rows = await conn.fetch(
        "SELECT field, value FROM translations "
        "WHERE entity_type=$1 AND entity_id=$2 AND lang=$3",
        entity_type, entity_id, lang
    )
    return {row['field']: row['value'] for row in rows}

async def apply_bulk_translations(
    conn, items: list[dict], entity_type: str, lang: str,
    fields: list[str]
) -> list[dict]:
    """Применить переводы к списку объектов. Modifies in-place, returns list."""
    if lang == 'ru' or not items:
        return items
    ids = [item['id'] for item in items]
    rows = await conn.fetch(
        "SELECT entity_id, field, value FROM translations "
        "WHERE entity_type=$1 AND entity_id = ANY($2) AND lang=$3",
        entity_type, ids, lang
    )
    tr_map: dict[int, dict] = {}
    for row in rows:
        tr_map.setdefault(row['entity_id'], {})[row['field']] = row['value']
    for item in items:
        item_tr = tr_map.get(item.get('id', 0), {})
        for field in fields:
            if field in item_tr:
                item[field] = item_tr[field]
    return items
```

**Оценка:** 3ч

---

### TASK-BE-032 — Применить переводы к Training Module endpoints

**Что делаем:**
Добавить применение переводов из таблицы `translations` ко всем endpoints тренировочного модуля, которые возвращают пользователю текстовые поля из БД.

**Зачем:**
Пользователь с `Accept-Language: en` должен видеть названия упражнений, групп мышц, программ тренировок и оборудования на английском языке. Без этого шага всё будет на русском вне зависимости от языка устройства.

**Endpoints и entity_type для перевода:**
```
GET /api/v1/training/{id}
  → exercises: entity_type='exercise', fields=['title', 'description', 'muscle_group']

GET /api/v1/training/programs
  → training_samples: entity_type='training_sample', fields=['title', 'description', 'interpretation', 'category']
  → exercize_samples: entity_type='exercize_sample', fields=['title', 'muscle_group']

GET /api/v1/training/{id}/exercise/{eid}
  → exercise: entity_type='exercise', fields=['title', 'description', 'muscle_group']

GET /api/v1/equipment
  → equipments: entity_type='equipment', fields=['title']
  → equipment_details: entity_type='equipment_detail', fields=['name', 'type']
  → equipment_options: entity_type='equipment_option', fields=['value']
```

**Оценка:** 4ч

---

### TASK-BE-033 — Применить переводы к Nutrition Module endpoints

**Что делаем:**
Добавить применение переводов к endpoints питания: названия продуктов из справочника `foods`.

**Зачем:**
Продукты в справочнике вводятся на русском. Пользователи с EN локалью должны видеть названия продуктов на английском, если перевод существует. Особенно актуально для продуктов, добавленных командой (не пользователем).

**Endpoints:**
```
GET /api/v1/nutrition/foods/search
  → foods: entity_type='food', fields=['name']

GET /api/v1/nutrition/journal
  → meal_items.food_name берётся из foods: entity_type='food', fields=['name']
```

**Примечание:** продукты, добавленные самим пользователем (`created_by = user.id`), не переводятся — это личные данные.

**Оценка:** 3ч

---

### TASK-BE-034 — Применить переводы к Subscription Plans и Achievements

**Что делаем:**
Переводить названия и описания тарифных планов и достижений, которые отображаются пользователю в разделах "Подписка" и "Прогресс".

**Зачем:**
Тарифные планы и достижения — это маркетинговый контент, который должен быть на языке пользователя. Достижения особенно важны для мотивации и восприятия.

**Endpoints и entity_type:**
```
GET /api/v1/subscription/plans
  → subscription_plans: entity_type='subscription_plan', fields=['name', 'description']

GET /api/v1/training/progress (achievements section)
  → achievements: entity_type='achievement', fields=['title', 'description', 'msg']
```

**Оценка:** 2ч

---

### TASK-BE-035 — Расширить quiz_translations.py вопросами unified онбординга

**Что делаем:**
Добавить EN переводы для новых вопросов unified онбординга в `quiz_translations.py`. Новые вопросы (nutrition-specific: target_weight, activity_level, dietary_restrictions) пока присутствуют только на русском.

**Зачем:**
Квиз — первое, что видит пользователь после регистрации. Отсутствие перевода квиза при EN локали — критичный UX-баг. Подход через Python dict сохраняется (он уже работает), просто расширяем его новыми вопросами.

**Детали реализации:**
```python
# Добавить EN переводы для новых вопросов онбординга:
QUIZ_TRANSLATIONS_EN = {
    # ... существующие вопросы (уже есть) ...

    # НОВЫЕ — nutrition block:
    'target_weight_kg': {
        'text': 'What is your target weight? (kg)',
        'type': 'number_input'
    },
    'activity_level': {
        'text': 'How active are you in daily life?',
        'answers': {
            1: 'Sedentary (office work)',
            2: 'Light activity (walks)',
            3: 'Moderate (3x per week)',
            4: 'Active (5x per week)',
            5: 'Very active (daily intense)',
        }
    },
    'dietary_restrictions': {
        'text': 'Do you have any dietary restrictions?',
        'answers': {
            1: 'Vegetarian',
            2: 'Vegan',
            3: 'Lactose intolerance',
            4: 'Gluten intolerance',
            5: 'Allergies (specify)',
            6: 'None',
        }
    },
}
```

**Оценка:** 2ч

---

### TASK-BE-036 — Endpoint для получения переводов (Admin / Content team)

**Что делаем:**
Создать защищённые admin endpoints для управления переводами: добавить/обновить перевод поля, получить все переводы для сущности.

**Зачем:**
Контент-команда должна иметь возможность добавлять и редактировать переводы без прямого доступа к БД. Без API придётся делать это вручную через SQL, что медленно и опасно.

**Endpoints (admin-only):**
```
GET  /api/v1/admin/translations/{entity_type}/{entity_id}
  Response: { translations: { ru: { title: '...', description: '...' }, en: { ... } } }

PUT  /api/v1/admin/translations/{entity_type}/{entity_id}/{lang}
  Request: { title?: str, description?: str, name?: str, ... }
  → UPSERT в translations table

DELETE /api/v1/admin/translations/{entity_type}/{entity_id}/{lang}
  → удалить все переводы сущности для языка
```

**Оценка:** 4ч

---

## Сводная таблица задач

| ID | Эпик | Название | Оценка |
|----|------|----------|--------|
| TASK-BE-001 | DB | Создать таблицу `users` | 3ч |
| TASK-BE-002 | DB | Создать `refresh_tokens` | 2ч |
| TASK-BE-003 | DB | Создать nutrition + training profiles | 3ч |
| TASK-BE-004 | DB | Создать subscriptions + plans | 3ч |
| TASK-BE-005 | DB | Создать `chat_messages` | 2ч |
| TASK-BE-006 | DB | Создать `quiz_answers` | 2ч |
| TASK-BE-007 | DB | Создать nutrition tables (meals, foods) | 4ч |
| TASK-BE-008 | DB | Адаптировать FitnesBot FK → unified users | 8ч |
| TASK-BE-009 | DB | Миграция пользователей из двух БД | 10ч |
| TASK-BE-010 | Auth | Unified auth endpoints | 8ч |
| TASK-BE-011 | Auth | Middleware проверки подписки | 2ч |
| TASK-BE-012 | Chat | Chat Intent Classifier | 4ч |
| TASK-BE-013 | Chat | Chat Agents (Nutritionist/Trainer/General) | 6ч |
| TASK-BE-014 | Chat | Chat API endpoints | 5ч |
| TASK-BE-015 | Nutrition | Nutrition API endpoints | 10ч |
| TASK-BE-016 | Nutrition | AI распознавание еды | 5ч |
| TASK-BE-017 | Nutrition | Расчёт КБЖУ норм (Way to Goal) | 4ч |
| TASK-BE-018 | Training | Адаптация Training API к unified auth | 8ч |
| TASK-BE-019 | Training | Unified quiz/onboarding для training | 5ч |
| TASK-BE-020 | Training | Equipment API | 3ч |
| TASK-BE-021 | Subscription | Subscription API + платёжки | 12ч |
| TASK-BE-022 | Subscription | Telegram Stars оплата | 4ч |
| TASK-BE-023 | User | User Profile endpoints | 5ч |
| TASK-BE-024 | User | Quiz Complete автоматический расчёт | 5ч |
| TASK-BE-025 | Infra | Unified FastAPI структура проекта | 4ч |
| TASK-BE-026 | Infra | Миграции БД | 5ч |
| TASK-BE-027 | Infra | GitHub Actions CI/CD | 3ч |
| TASK-BE-028 | Infra | Пуш-уведомления (unified) | 6ч |
| TASK-BE-029 | Bot | Telegram бот → unified user_id | 5ч |
| TASK-BE-030 | i18n | Перенести таблицу `translations` в unified БД | 2ч |
| TASK-BE-031 | i18n | Dependency get_lang + утилиты apply_translations | 3ч |
| TASK-BE-032 | i18n | Переводы в Training Module (exercises, programs, equipment) | 4ч |
| TASK-BE-033 | i18n | Переводы в Nutrition Module (foods) | 3ч |
| TASK-BE-034 | i18n | Переводы subscription plans + achievements | 2ч |
| TASK-BE-035 | i18n | Расширить quiz_translations.py новыми вопросами | 2ч |
| TASK-BE-036 | i18n | Admin endpoints для управления переводами | 4ч |

---

## Зависимости между задачами

```
TASK-BE-001 (users) ─────────────────────────────────────────────────┐
     │                                                               │
     ├─► TASK-BE-002 (refresh_tokens)                               │
     ├─► TASK-BE-003 (nutrition/training profiles)                   │
     ├─► TASK-BE-004 (subscriptions)                                 │
     ├─► TASK-BE-005 (chat_messages)                                 │
     ├─► TASK-BE-006 (quiz_answers)                                  │
     ├─► TASK-BE-007 (meals/foods)                                   │
     └─► TASK-BE-009 (migration) ─► TASK-BE-008 (FK adaptation)     │
                                                                     │
TASK-BE-025 (project structure) ──────────────────────────────────── │
     │                                                               │
     ├─► TASK-BE-010 (auth) ─────────────────────────────────────── ┘
     │        │
     │        └─► TASK-BE-011 (subscription middleware)
     │                 │
     ├─► TASK-BE-012 (classifier) ─┐
     ├─► TASK-BE-013 (agents)      ├─► TASK-BE-014 (chat API)
     │                             │
     ├─► TASK-BE-015 (nutrition API)
     ├─► TASK-BE-016 (AI food recognition)
     ├─► TASK-BE-017 (КБЖУ calculator)
     │
     ├─► TASK-BE-018 (training API)
     ├─► TASK-BE-019 (unified quiz)
     ├─► TASK-BE-020 (equipment)
     │
     ├─► TASK-BE-021 (subscription API)
     ├─► TASK-BE-022 (Telegram Stars)
     │
     ├─► TASK-BE-023 (user profile)
     └─► TASK-BE-024 (quiz complete) ─► зависит от 019 + 017

TASK-BE-026 (migrations) — параллельно с 001-009
TASK-BE-027 (CI/CD) — в конце
TASK-BE-028 (push) — параллельно с основными
TASK-BE-029 (bot) — параллельно с 001, 010
```

---

## Рекомендуемый порядок выполнения

**Спринт 1 (Основа):**
BE-025 → BE-001 → BE-002 → BE-003 → BE-004 → BE-005 → BE-006 → BE-007 → BE-026

**Спринт 2 (Auth + Migration):**
BE-009 → BE-008 → BE-010 → BE-011

**Спринт 3 (Chat + Core Features):**
BE-012 → BE-013 → BE-014 → BE-015 → BE-018 → BE-023

**Спринт 4 (Full Features):**
BE-016 → BE-017 → BE-019 → BE-020 → BE-021 → BE-024

**Спринт 5 (Polish + Bot + i18n):**
BE-022 → BE-028 → BE-027 → BE-029
BE-030 → BE-031 → BE-032 → BE-033 → BE-034 → BE-035 → BE-036


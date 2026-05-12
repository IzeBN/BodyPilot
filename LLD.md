# LLD — Единое приложение KayFit + FitKeep

## 1. Схема базы данных (Unified PostgreSQL)

### Принцип: чистая замена, не наращивание

Старые таблицы FitnesBot (`all_users`, `clients`, `services`, `subscribers`, `exercizes`, `schedule_trainings` и др.) **удаляются** и **заменяются** новыми. Данные мигрируют через скрипты. В итоге — одна чистая схема без legacy.

### Что удаляется → что заменяет

```
УДАЛЯЕТСЯ                       →  ЗАМЕНЯЕТСЯ НА
─────────────────────────────────────────────────────────────────
all_users                       →  users
clients                         →  user_training_profile
services                        →  subscription_plans
subscribers + auto_payments     →  subscriptions
sessions                        →  refresh_tokens
emails (таблица)                →  поле email в users
telegram_bindings               →  user_telegram
user_telegram_mapping           →  user_telegram
user_individual_data            →  quiz_answers (частично)
start_quest_result              →  quiz_answers
website_users_quiz              →  quiz_answers
user_chats                      →  chat_messages
user_fcm_tokens                 →  push_tokens
payment_offers                  →  удаляется (не нужно)
exercizes                       →  exercises         (исправлен typo)
exercize_samples                →  program_exercises (переименовано)
training_samples                →  training_programs (переименовано)
training_samples_exercizes      →  слито в program_exercises
types_of_training               →  training_types    (переименовано)
exercize_results                →  exercise_results
schedule_trainings              →  scheduled_trainings
user_exercize_parameters        →  exercise_session_params
exercize_default_parameters     →  exercise_default_params
alternative_exercizes           →  alternative_exercises
duration_exercizes              →  exercise_durations
user_equipments                 →  user_equipment
user_count_using                →  exercise_usage_stats
user_max_weights                →  exercise_personal_records
training_weights                →  слито в exercise_session_params
fitnes_clubs + fitnes_club_*    →  fitness_clubs + fitness_club_*
exercize_equipments             →  exercise_equipment_requirements
fitnes_club_equipments          →  fitness_club_equipment

ОСТАЮТСЯ БЕЗ ИЗМЕНЕНИЙ
─────────────────────────────────────────────────────────────────
trainers, trainer_directions, trainer_clients, trainer_referrers
achievements, user_achievements, user_achievement_information
files, free_urls, translations, notification_history
user_actions, user_patterns, user_admin_data, users_threads
landing_bids, exceptions, equipments, equipment_details, equipment_options
```

---

### 1.1 Полная схема unified БД (SQL)

#### БЛОК: Auth & Users

```sql
-- Единая таблица пользователей (заменяет all_users + old users + emails)
CREATE TABLE users (
    id            SERIAL PRIMARY KEY,
    email         VARCHAR(256) UNIQUE,        -- null для чисто Telegram-юзеров
    password_hash VARCHAR(512),               -- null если только соц. авторизация
    fullname      VARCHAR(128) NOT NULL,
    phone         VARCHAR(32),
    avatar_url    TEXT,
    language      VARCHAR(8)  NOT NULL DEFAULT 'ru',
    ai_consent    BOOLEAN     NOT NULL DEFAULT FALSE,
    is_deleted    BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMP   NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP
);
CREATE INDEX idx_users_email ON users(email) WHERE email IS NOT NULL;

-- Привязка Telegram аккаунта (заменяет telegram_bindings + user_telegram_mapping)
CREATE TABLE user_telegram (
    user_id          INT    PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    telegram_user_id BIGINT UNIQUE NOT NULL,
    username         VARCHAR(64),
    linked_at        TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_user_telegram_tg_id ON user_telegram(telegram_user_id);

-- Refresh токены (заменяет sessions)
CREATE TABLE refresh_tokens (
    id          SERIAL PRIMARY KEY,
    user_id     INT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  VARCHAR(256) NOT NULL,   -- SHA-256 от refresh_token
    device_info VARCHAR(256),
    expires_at  TIMESTAMP    NOT NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT NOW(),
    is_revoked  BOOLEAN      NOT NULL DEFAULT FALSE
);
CREATE INDEX idx_refresh_tokens_hash ON refresh_tokens(token_hash);
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
```

#### БЛОК: User Profiles

```sql
-- Профиль питания (новый)
CREATE TABLE user_nutrition_profile (
    user_id              INT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    goal_type            VARCHAR(32),     -- weight_loss | maintenance | muscle_gain
    current_weight_kg    NUMERIC(5,1),
    target_weight_kg     NUMERIC(5,1),
    height_cm            NUMERIC(5,1),
    age                  SMALLINT,
    gender               VARCHAR(8),      -- male | female
    activity_level       SMALLINT,        -- 1..5
    calories_goal        INT,
    protein_goal_g       INT,
    fat_goal_g           INT,
    carbs_goal_g         INT,
    dietary_restrictions VARCHAR(64)[],   -- ['vegetarian', 'lactose', ...]
    updated_at           TIMESTAMP
);

-- Профиль тренировок (заменяет clients + поля из user_individual_data)
CREATE TABLE user_training_profile (
    user_id                  INT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    gender                   VARCHAR(8),
    age                      SMALLINT,
    height_cm                NUMERIC(5,1),
    current_weight_kg        NUMERIC(5,1),
    experience_level         VARCHAR(16),   -- beginner | intermediate | advanced
    current_fat_percentage   NUMERIC(4,1),
    desired_fat_percentage   NUMERIC(4,1),
    preferred_duration_min   SMALLINT,
    injuries                 TEXT,
    training_type_pref       VARCHAR(16),   -- strength | cardio | mixed
    training_program_id      INT,           -- FK добавляется ниже
    trainer_id               BIGINT REFERENCES trainers(id),
    fitness_club_id          INT,           -- FK добавляется ниже
    onboarding_status        VARCHAR(16) NOT NULL DEFAULT 'pending',
    updated_at               TIMESTAMP      -- pending|quiz_done|equipment_done|complete
);
```

#### БЛОК: Subscription

```sql
-- Тарифные планы (заменяет services)
CREATE TABLE subscription_plans (
    id                 SERIAL PRIMARY KEY,
    name               VARCHAR(64) NOT NULL,
    term_days          INT         NOT NULL,
    price_rub          INT,
    price_stars        INT,
    includes_nutrition BOOLEAN NOT NULL DEFAULT TRUE,
    includes_training  BOOLEAN NOT NULL DEFAULT TRUE,
    includes_ai_chat   BOOLEAN NOT NULL DEFAULT TRUE,
    includes_trainer   BOOLEAN NOT NULL DEFAULT FALSE,
    is_trial           BOOLEAN NOT NULL DEFAULT FALSE,
    is_active          BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order         SMALLINT NOT NULL DEFAULT 0,
    created_at         TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Подписки пользователей (заменяет subscribers + auto_payments)
CREATE TABLE subscriptions (
    id              SERIAL PRIMARY KEY,
    user_id         INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id         INT NOT NULL REFERENCES subscription_plans(id),
    status          VARCHAR(16) NOT NULL,  -- trial|active|expired|cancelled
    started_at      TIMESTAMP   NOT NULL,
    expires_at      TIMESTAMP   NOT NULL,
    payment_type    VARCHAR(32),           -- apple|google|stripe|telegram_stars|manual
    external_sub_id VARCHAR(256),
    auto_renew      BOOLEAN NOT NULL DEFAULT TRUE,
    auto_pay_method VARCHAR(256),          -- method_id для автосписания
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_subscriptions_user   ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(user_id, status);
```

#### БЛОК: Onboarding / Quiz

```sql
-- Ответы на вопросы онбординга (заменяет start_quest_result + user_individual_data + website_users_quiz)
CREATE TABLE quiz_answers (
    id           SERIAL PRIMARY KEY,
    user_id      INT         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    question_key VARCHAR(64) NOT NULL,  -- 'gender'|'age'|'goal_type'|...
    answer_value TEXT,
    answer_type  VARCHAR(16),           -- text|int|float|bool|choice|multichoice
    module       VARCHAR(16),           -- common|nutrition|training
    created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP,
    UNIQUE (user_id, question_key)
);
CREATE INDEX idx_quiz_answers_user ON quiz_answers(user_id);
```

#### БЛОК: Nutrition

```sql
-- Справочник продуктов
CREATE TABLE foods (
    id            SERIAL PRIMARY KEY,
    name          VARCHAR(256) NOT NULL,
    name_en       VARCHAR(256),
    barcode       VARCHAR(64) UNIQUE,
    calories_100g NUMERIC(7,2),
    protein_100g  NUMERIC(6,2),
    fat_100g      NUMERIC(6,2),
    carbs_100g    NUMERIC(6,2),
    fiber_100g    NUMERIC(6,2),
    sugar_100g    NUMERIC(6,2),
    source        VARCHAR(32),  -- user|openfoodfacts|ai_recognized|admin
    created_by    INT REFERENCES users(id),
    created_at    TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_foods_barcode ON foods(barcode) WHERE barcode IS NOT NULL;
CREATE INDEX idx_foods_name    ON foods USING GIN (to_tsvector('russian', name));

-- Приёмы пищи
CREATE TABLE meals (
    id         SERIAL PRIMARY KEY,
    user_id    INT         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    meal_type  VARCHAR(16) NOT NULL,  -- breakfast|lunch|dinner|snack
    eaten_at   TIMESTAMP   NOT NULL,
    notes      TEXT,
    emotion    VARCHAR(32),
    created_at TIMESTAMP   NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_meals_user_date ON meals(user_id, eaten_at DESC);

-- Позиции в приёме пищи
CREATE TABLE meal_items (
    id         SERIAL PRIMARY KEY,
    meal_id    INT          NOT NULL REFERENCES meals(id) ON DELETE CASCADE,
    food_id    INT          REFERENCES foods(id),
    food_name  VARCHAR(256),            -- если food_id IS NULL (кастомный)
    quantity_g NUMERIC(7,1) NOT NULL,
    calories   NUMERIC(7,1),
    protein    NUMERIC(6,1),
    fat        NUMERIC(6,1),
    carbs      NUMERIC(6,1)
);
CREATE INDEX idx_meal_items_meal ON meal_items(meal_id);
```

#### БЛОК: Training (переименованные и объединённые таблицы)

```sql
-- Типы тренировок (переименовано из types_of_training)
CREATE TABLE training_types (
    id          SERIAL PRIMARY KEY,
    title       VARCHAR(64) NOT NULL,
    description VARCHAR(512)
);

-- Упражнения (переименовано из exercizes, исправлен typo)
CREATE TABLE exercises (
    id            SERIAL PRIMARY KEY,
    title         VARCHAR(256) NOT NULL,
    description   TEXT,
    title_photo   VARCHAR(256) REFERENCES files(file_id),
    video_file    VARCHAR(256) REFERENCES files(file_id),
    muscle_group  VARCHAR(32),
    documentation TEXT,
    progression   NUMERIC(5,2) DEFAULT 0,
    created_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Программы тренировок (переименовано из training_samples)
CREATE TABLE training_programs (
    id               SERIAL PRIMARY KEY,
    program_type     VARCHAR(16),   -- template|custom|trainer
    training_type_id INT REFERENCES training_types(id),
    title            VARCHAR(128) NOT NULL,
    description      TEXT,
    category         VARCHAR(64),
    male             VARCHAR(16),   -- male|female|any
    experience       VARCHAR(32),   -- beginner|intermediate|advanced
    intensity        SMALLINT,      -- 1..5
    training_count   INT,
    equipment_ids    INT[],
    created_at       TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Блоки упражнений программы (объединяет exercize_samples + training_samples_exercizes)
CREATE TABLE program_exercises (
    id                  SERIAL PRIMARY KEY,
    training_program_id INT NOT NULL REFERENCES training_programs(id) ON DELETE CASCADE,
    exercise_id         INT NOT NULL REFERENCES exercises(id),
    block_type          VARCHAR(16),  -- main|warmup|cooldown
    title               VARCHAR(128),
    duration_min        INT,
    weeks               VARCHAR(32),
    muscle_group        VARCHAR(32),
    progression         NUMERIC(5,2),
    is_mandatory        BOOLEAN  NOT NULL DEFAULT TRUE,
    sort_order          SMALLINT NOT NULL DEFAULT 0,
    title_photo         VARCHAR(256) REFERENCES files(file_id)
);
CREATE INDEX idx_program_exercises_prog ON program_exercises(training_program_id);

-- Альтернативы упражнений (переименовано из alternative_exercizes)
CREATE TABLE alternative_exercises (
    exercise_id             INT NOT NULL REFERENCES exercises(id),
    alternative_exercise_id INT NOT NULL REFERENCES exercises(id),
    PRIMARY KEY (exercise_id, alternative_exercise_id)
);

-- Требования к оборудованию для упражнения (переименовано из exercize_equipments)
CREATE TABLE exercise_equipment_requirements (
    exercise_id         INT NOT NULL REFERENCES exercises(id),
    equipment_id        INT NOT NULL REFERENCES equipments(id),
    equipment_detail_id INT REFERENCES equipment_details(id),
    equipment_option_id INT REFERENCES equipment_options(id)
);

-- Параметры упражнения по умолчанию (переименовано из exercize_default_parameters)
CREATE TABLE exercise_default_params (
    id                  SERIAL PRIMARY KEY,
    exercise_id         INT      NOT NULL REFERENCES exercises(id),
    training_program_id INT      REFERENCES training_programs(id),
    approach_number     SMALLINT NOT NULL,
    repetitions         INT,
    weight              NUMERIC(6,2),
    repetition_margin   INT,
    updated_at          TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_ex_default_params ON exercise_default_params(exercise_id, training_program_id);

-- Длительность упражнения (переименовано из duration_exercizes)
CREATE TABLE exercise_durations (
    id                  SERIAL PRIMARY KEY,
    exercise_id         INT UNIQUE NOT NULL REFERENCES exercises(id),
    repetition_duration NUMERIC(6,2),
    break_duration      NUMERIC(6,2)
);

-- Оборудование пользователя (переименовано из user_equipments)
CREATE TABLE user_equipment (
    user_id             INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    equipment_id        INT NOT NULL REFERENCES equipments(id),
    equipment_detail_id INT REFERENCES equipment_details(id),
    equipment_option_id INT REFERENCES equipment_options(id),
    PRIMARY KEY (user_id, equipment_id, equipment_detail_id)
);

-- Расписание тренировок (переименовано из schedule_trainings)
CREATE TABLE scheduled_trainings (
    id                  SERIAL PRIMARY KEY,
    user_id             INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    training_program_id INT REFERENCES training_programs(id),
    program_exercise_id INT REFERENCES program_exercises(id),
    training_date       TIMESTAMP   NOT NULL,
    status              VARCHAR(16) NOT NULL DEFAULT 'wait'  -- wait|done|skipped
);
CREATE INDEX idx_scheduled_trainings_user ON scheduled_trainings(user_id, training_date DESC);

-- Результаты упражнений (переименовано из exercize_results)
CREATE TABLE exercise_results (
    id                    SERIAL PRIMARY KEY,
    user_id               INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_id           INT NOT NULL REFERENCES exercises(id),
    scheduled_training_id INT REFERENCES scheduled_trainings(id),
    video_file            VARCHAR(256) REFERENCES files(file_id),
    succeeded             BOOLEAN,
    weight                NUMERIC(6,2),
    repeats               INT,
    approach_number       SMALLINT,
    created_at            TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_exercise_results_user ON exercise_results(user_id, created_at DESC);

-- Параметры выполнения в сессии (заменяет user_exercize_parameters + training_weights)
CREATE TABLE exercise_session_params (
    id                    SERIAL PRIMARY KEY,
    user_id               INT      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    scheduled_training_id INT      NOT NULL REFERENCES scheduled_trainings(id),
    exercise_id           INT      NOT NULL REFERENCES exercises(id),
    approach_number       SMALLINT NOT NULL,
    repetitions           INT,
    weight                NUMERIC(6,2),
    updated_at            TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_ex_session_params ON exercise_session_params(user_id, scheduled_training_id);

-- Личные рекорды (переименовано из user_max_weights)
CREATE TABLE exercise_personal_records (
    id          SERIAL PRIMARY KEY,
    user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_id INT NOT NULL REFERENCES exercises(id),
    weight      NUMERIC(6,2) NOT NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, exercise_id)
);

-- Статистика использования (переименовано из user_count_using)
CREATE TABLE exercise_usage_stats (
    user_id      INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_id  INT NOT NULL REFERENCES exercises(id),
    usage_count  INT NOT NULL DEFAULT 1,
    first_used_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, exercise_id)
);

-- FK которые зависят от training_programs и fitness_clubs
ALTER TABLE user_training_profile
    ADD CONSTRAINT fk_utp_program FOREIGN KEY (training_program_id) REFERENCES training_programs(id),
    ADD CONSTRAINT fk_utp_club    FOREIGN KEY (fitness_club_id)      REFERENCES fitness_clubs(id);
```

#### БЛОК: Fitness Clubs (переименованные таблицы)

```sql
-- Фитнес-клубы (переименовано из fitnes_clubs, исправлен typo)
CREATE TABLE fitness_clubs (
    id         SERIAL PRIMARY KEY,
    title      VARCHAR(128) NOT NULL,
    city       VARCHAR(32),
    commission INT DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
-- fitness_club_admins, fitness_club_clients, fitness_club_subscribers,
-- fitness_club_activity, fitness_club_equipment
-- → переименованы из fitnes_club_*, структура без изменений
```

#### БЛОК: Chat

```sql
-- Сообщения чата (заменяет user_chats, добавлен agent_type + conversation_id)
CREATE TABLE chat_messages (
    id              SERIAL PRIMARY KEY,
    user_id         INT         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    conversation_id UUID        NOT NULL,
    role            VARCHAR(16) NOT NULL,   -- user|assistant
    content         TEXT        NOT NULL,
    agent_type      VARCHAR(16),            -- nutritionist|trainer|general
    created_at      TIMESTAMP   NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_chat_messages_conv ON chat_messages(user_id, conversation_id, created_at);
```

#### БЛОК: Notifications

```sql
-- Push-токены (переименовано из user_fcm_tokens)
CREATE TABLE push_tokens (
    id         SERIAL PRIMARY KEY,
    user_id    INT        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token      TEXT       NOT NULL UNIQUE,
    platform   VARCHAR(8) NOT NULL,   -- ios|android
    created_at TIMESTAMP  NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);
CREATE INDEX idx_push_tokens_user ON push_tokens(user_id);
```

---

### 1.2 Диаграмма связей

```
users
  ├── user_telegram (1:1)               ← Telegram binding
  ├── refresh_tokens (1:N)              ← JWT auth
  ├── user_nutrition_profile (1:1)      ← данные питания/цели
  ├── user_training_profile (1:1)
  │       ├──► training_programs
  │       ├──► trainers
  │       └──► fitness_clubs
  ├── subscriptions (1:N)
  │       └──► subscription_plans
  ├── quiz_answers (1:N)
  ├── meals (1:N)
  │       └── meal_items ──► foods
  ├── scheduled_trainings (1:N)
  │       ├──► training_programs
  │       └──► program_exercises ──► exercises
  ├── exercise_results (1:N) ──► exercises
  ├── exercise_session_params (1:N)
  ├── exercise_personal_records (1:N)
  ├── user_equipment (1:N) ──► equipments
  ├── chat_messages (1:N)
  └── push_tokens (1:N)

training_programs ──► training_types
program_exercises ──► exercises
exercises ──► exercise_durations (1:1)
          ──► exercise_default_params (1:N)
          ──► exercise_equipment_requirements ──► equipments
          ──► alternative_exercises

[i18n] exercises, training_programs, training_types,
       equipments, foods, subscription_plans, achievements
       → все переводятся через таблицу translations
```

---

### 1.3 Сводка (старое → новое)

```
┌──────────────────────────────────────┬──────────────────────────────────────┐
│           СТАРАЯ СХЕМА               │          НОВАЯ СХЕМА                 │
│         (FitnesBot legacy)           │        (Unified, чистая)             │
├──────────────────────────────────────┼──────────────────────────────────────┤
│ all_users                            │ users                                │
│ clients                              │ user_training_profile                │
│ services                             │ subscription_plans                   │
│ subscribers + auto_payments          │ subscriptions                        │
│ sessions                             │ refresh_tokens                       │
│ emails (таблица)                     │ users.email (поле)                   │
│ telegram_bindings + mapping          │ user_telegram                        │
│ start_quest_result +                 │                                      │
│   user_individual_data +             │ quiz_answers                         │
│   website_users_quiz                 │                                      │
│ user_chats                           │ chat_messages                        │
│ user_fcm_tokens                      │ push_tokens                          │
│ exercizes                            │ exercises                            │
│ training_samples                     │ training_programs                    │
│ exercize_samples +                   │                                      │
│   training_samples_exercizes         │ program_exercises                    │
│ types_of_training                    │ training_types                       │
│ exercize_results                     │ exercise_results                     │
│ schedule_trainings                   │ scheduled_trainings                  │
│ user_exercize_parameters +           │                                      │
│   training_weights                   │ exercise_session_params              │
│ exercize_default_parameters          │ exercise_default_params              │
│ alternative_exercizes                │ alternative_exercises                │
│ duration_exercizes                   │ exercise_durations                   │
│ user_equipments                      │ user_equipment                       │
│ user_max_weights                     │ exercise_personal_records            │
│ user_count_using                     │ exercise_usage_stats                 │
│ fitnes_clubs + fitnes_club_*         │ fitness_clubs + fitness_club_*       │
│ exercize_equipments                  │ exercise_equipment_requirements      │
│ payment_offers                       │ (удалено)                            │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

---

## 2. API Design (Unified Backend)

### 2.1 Auth API

```
POST   /api/v1/auth/register
  Request:  { email, password, fullname }
  Response: { access_token, refresh_token, user_id }

POST   /api/v1/auth/login
  Request:  { email, password }
  Response: { access_token, refresh_token, user_id }

POST   /api/v1/auth/apple
  Request:  { identity_token, authorization_code, fullname? }
  Response: { access_token, refresh_token, user_id }

POST   /api/v1/auth/google
  Request:  { id_token }
  Response: { access_token, refresh_token, user_id }

POST   /api/v1/auth/refresh
  Request:  { refresh_token }
  Response: { access_token, refresh_token }

POST   /api/v1/auth/logout
  Request:  { refresh_token }
  Response: { status: 200 }

GET    /api/v1/auth/me
  Response: {
    id, email, fullname, avatar_url,
    ai_consent, language,
    subscription: { status, expires_at, plan_name },
    onboarding_completed: bool,
    nutrition_profile: { ... } | null,
    training_profile: { ... } | null
  }

DELETE /api/v1/auth/account
  Response: { status: 200 }
```

### 2.2 User API

```
GET    /api/v1/user/profile
  Response: { fullname, email, avatar_url, language, ... }

PATCH  /api/v1/user/profile
  Request:  { fullname?, avatar_url?, language? }

POST   /api/v1/user/ai-consent
  Request:  { consent: bool }

GET    /api/v1/user/nutrition-profile
  Response: { goal_type, target_weight, current_weight, calories_goal, ... }

PATCH  /api/v1/user/nutrition-profile
  Request:  { goal_type?, target_weight?, activity_level?, ... }

GET    /api/v1/user/training-profile
  Response: { experience_level, injuries, equipment_ids, ... }

PATCH  /api/v1/user/training-profile

POST   /api/v1/user/push-token
  Request:  { token, platform }

DELETE /api/v1/user/push-token
  Request:  { token }
```

### 2.3 Chat API (Unified)

```
POST   /api/v1/chat/message
  Request: {
    message: str,
    conversation_id: str | null  ← null = новый диалог
    context?: {
      last_meal?: {...}       ← опционально, для нутрициолога
      last_training?: {...}   ← опционально, для тренера
    }
  }
  Response: {
    reply: str,
    agent_type: 'nutritionist' | 'trainer' | 'general',
    conversation_id: str
  }

GET    /api/v1/chat/history?conversation_id=&limit=&offset=
  Response: {
    messages: [
      { id, role, content, agent_type, created_at }
    ],
    total: int
  }

DELETE /api/v1/chat/history
  Response: { status: 200 }
```

### 2.4 Nutrition API

```
GET    /api/v1/nutrition/journal?date=YYYY-MM-DD
  Response: {
    date: str,
    meals: [ { id, meal_type, eaten_at, items: [...], totals: {calories, protein, fat, carbs} } ],
    daily_totals: { calories, protein, fat, carbs },
    goals: { calories, protein, fat, carbs }
  }

POST   /api/v1/nutrition/meals
  Request:  { meal_type, eaten_at, notes?, emotion? }
  Response: { id, ... }

DELETE /api/v1/nutrition/meals/{meal_id}

POST   /api/v1/nutrition/meals/{meal_id}/items
  Request:  { food_id?, name?, quantity_g, calories?, protein?, fat?, carbs? }
  Response: { id, ... }

DELETE /api/v1/nutrition/meals/{meal_id}/items/{item_id}

PATCH  /api/v1/nutrition/meals/{meal_id}/items/{item_id}
  Request:  { quantity_g }

GET    /api/v1/nutrition/foods/search?q=&barcode=
  Response: { foods: [ { id, name, barcode, calories_100g, ... } ] }

POST   /api/v1/nutrition/foods/recognize
  Request:  { image_base64 } | multipart/form-data
  Response: { food_name, calories_100g, protein_100g, fat_100g, carbs_100g, confidence }

GET    /api/v1/nutrition/stats?from=YYYY-MM-DD&to=YYYY-MM-DD
  Response: { daily: [ { date, calories, protein, fat, carbs } ] }

GET    /api/v1/nutrition/goals
PATCH  /api/v1/nutrition/goals
  Request:  { calories_goal, protein_goal, fat_goal, carbs_goal }
```

### 2.5 Training API

```
GET    /api/v1/training/programs
  Response: { programs: [...], current_program_id, interpretation }

POST   /api/v1/training/programs/select
  Request:  { sample_id }

GET    /api/v1/training/schedule
  Response: { trainings: [ { id, date, status, exercises } ] }

GET    /api/v1/training/{training_id}
  Response: { id, title, exercises, duration, muscle_group, schedule }

GET    /api/v1/training/{training_id}/exercise/{exercise_id}
  Response: { exercise, default_params, user_params, alternatives }

POST   /api/v1/training/results
  Request:  { training_id, exercise_id, approaches: [...], training_complete }

POST   /api/v1/training/adaptive
  Request:  { training_id, training_type, equipments, new_training_time }

GET    /api/v1/training/exercises/{exercise_id}/alternatives
  Response: { alternatives: [...] }

POST   /api/v1/training/{training_id}/replace-exercise
  Request:  { old_exercise_id, new_exercise_id }

GET    /api/v1/training/progress?from=&to=
  Response: { weekly_results: [...], personal_records: [...] }
```

### 2.6 Equipment API

```
GET    /api/v1/equipment
  Response: { equipments: [ { id, title, details: [...] } ] }

GET    /api/v1/equipment/my
  Response: { choices: [ { equipment_id, detail_id, option_id } ] }

PUT    /api/v1/equipment/my
  Request:  { equipments: [ { equipment_id, detail_id, option_id } ] }
```

### 2.7 Quiz / Onboarding API

```
POST   /api/v1/quiz/answer
  Request:  { question_key, answer, answer_type, module }
  Response: { status: 200 }

POST   /api/v1/quiz/answers/bulk
  Request:  { answers: [ { question_key, answer, module } ] }
  Response: { status: 200 }

GET    /api/v1/quiz/answers?keys[]=gender&keys[]=age
  Response: { answers: { gender: 'male', age: 25, ... } }

POST   /api/v1/quiz/complete
  Response: {
    training_program_assigned: bool,
    nutrition_goals_calculated: bool,
    next_step: 'equipment' | 'body_form' | 'main'
  }
```

### 2.8 Subscription API

```
GET    /api/v1/subscription
  Response: {
    status, plan_name, expires_at, auto_renew,
    includes_nutrition, includes_training, includes_trainer
  }

GET    /api/v1/subscription/plans
  Response: { plans: [ { id, name, term_days, price_rub, price_stars, ... } ] }

POST   /api/v1/subscription/purchase
  Request:  { plan_id, payment_method, email? }
  Response: { payment_url?, status }

POST   /api/v1/subscription/restore
  Request:  { receipt_data } | { purchase_token }
  Response: { status, expires_at }
```

---

## 3. Chat Router — Детальная логика

### 3.1 Классификация интента

```
┌──────────────────────────────────────────────────────────┐
│                  Chat Router Flow                         │
│                                                          │
│  user_message + user_context (profile, history)          │
│           │                                              │
│           ▼                                              │
│  ┌─────────────────────────────────────────────────┐    │
│  │              Intent Classifier                   │    │
│  │                                                 │    │
│  │  Способ 1 (простой): keyword matching           │    │
│  │    nutrition_keywords = [                       │    │
│  │      'калори', 'есть', 'питание', 'рацион',     │    │
│  │      'белок', 'жир', 'углевод', 'вес', 'диет',  │    │
│  │      'кушать', 'продукт', 'рецепт', 'похудет'   │    │
│  │    ]                                            │    │
│  │    training_keywords = [                        │    │
│  │      'трен', 'упражнен', 'мышц', 'жим',         │    │
│  │      'тяга', 'приседан', 'кардио', 'подход',    │    │
│  │      'повторен', 'программа', 'тренер', 'зал'   │    │
│  │    ]                                            │    │
│  │                                                 │    │
│  │  Способ 2 (умный): LLM classify prompt          │    │
│  │    "Классифицируй запрос как nutrition/         │    │
│  │     training/general. Запрос: {message}"        │    │
│  └───────────────┬─────────────────────────────────┘    │
│                  │                                       │
│         ┌────────┼────────────┐                          │
│         ▼        ▼            ▼                          │
│      nutrition  training   general                       │
│         │        │            │                          │
│         ▼        ▼            ▼                          │
│   Nutritionist Trainer AI  General AI                    │
│   System Prompt System Prompt System Prompt              │
│         │        │            │                          │
│         └────────┴────────────┘                          │
│                  │                                       │
│          Claude/GPT API call                             │
│          + user history (last 20 messages)               │
│          + user profile context                          │
│                  │                                       │
│                  ▼                                       │
│         Response + agent_type label                      │
└──────────────────────────────────────────────────────────┘
```

### 3.2 System Prompts

```
NUTRITIONIST_SYSTEM_PROMPT:
  "Ты личный нутрициолог. Помогаешь пользователю с питанием,
   расчётом КБЖУ, составлением рациона.
   Профиль пользователя: {user_nutrition_profile}.
   Сегодня съедено: {today_meals_summary}.
   Отвечай на русском языке, кратко и по делу."

TRAINER_SYSTEM_PROMPT:
  "Ты персональный тренер. Помогаешь с тренировками, техникой
   упражнений, программами.
   Профиль пользователя: {user_training_profile}.
   Текущая программа: {current_training_sample}.
   Отвечай на русском языке, кратко и по делу."

GENERAL_SYSTEM_PROMPT:
  "Ты AI-ассистент фитнес-приложения. Помогаешь с вопросами
   о здоровье, мотивации, здоровом образе жизни.
   Отвечай на русском языке."
```

---

## 4. Аутентификация — детальный flow

### 4.1 JWT Token Flow

```
┌─────────────────────────────────────────────────────────┐
│                JWT Authentication Flow                   │
│                                                         │
│  1. Login/Register:                                     │
│     Client → POST /auth/login → Server                  │
│     Server генерирует:                                  │
│       access_token  (JWT, exp: 15 min)                  │
│       refresh_token (JWT, exp: 30 days)                 │
│     refresh_token сохраняется в БД (hash) с device_info │
│                                                         │
│  2. Запросы к API:                                      │
│     Client: Authorization: Bearer {access_token}        │
│     Server: проверяет JWT signature + expiry            │
│                                                         │
│  3. Refresh (auto, при 401):                            │
│     Client → POST /auth/refresh {refresh_token}         │
│     Server: проверяет refresh_token в БД                │
│     Server: генерирует новую пару токенов               │
│     Server: инвалидирует старый refresh_token           │
│     Server → { access_token, refresh_token }            │
│                                                         │
│  4. Logout:                                             │
│     Client → POST /auth/logout {refresh_token}          │
│     Server: помечает refresh_token как revoked          │
│                                                         │
│  5. Защита от race condition (одновременный refresh):   │
│     Используется Completer паттерн (уже реализован      │
│     в обоих мобильных клиентах — перенести без изменений)
└─────────────────────────────────────────────────────────┘
```

### 4.2 Миграция пользователей

```
┌─────────────────────────────────────────────────────────────┐
│              User Migration Strategy                         │
│                                                             │
│  Проблема: два отдельных аккаунта у одного человека         │
│  (один в KayFit, другой в FitKeep)                         │
│                                                             │
│  Решение:                                                   │
│  1. Для новых пользователей: один аккаунт в unified backend │
│                                                             │
│  2. Для существующих пользователей:                         │
│     a) Если email совпадает → merge (объединить профили)    │
│     b) Если только KayFit → перенести в unified             │
│     c) Если только FitKeep → перенести в unified            │
│                                                             │
│  Migration Script:                                          │
│  unified_users ← merge(calories_users, fitnesbot_users)     │
│  conflict resolution: email уникален → один аккаунт         │
│                                                             │
│  Таблица миграции:                                          │
│  user_migrations(                                           │
│    unified_user_id,                                         │
│    source: 'calories' | 'fitnesbot',                        │
│    original_id,                                             │
│    migrated_at                                              │
│  )                                                          │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. Мобильное приложение — детальная архитектура

### 5.1 Структура проекта (Flutter)

```
lib/
├── main.dart
├── app.dart
├── router.dart                  ← новый unified router
│
├── core/
│   ├── api/
│   │   └── api_client.dart      ← один клиент → unified backend
│   ├── auth/
│   │   ├── auth_provider.dart   ← unified auth (из KayFit, доработать)
│   │   └── auth_state.dart
│   ├── config/
│   │   └── app_config.dart      ← baseUrl = unified backend URL
│   ├── analytics/
│   ├── notifications/
│   ├── locale/
│   └── storage/
│
├── features/
│   │
│   ├── auth/                    ← перенести из KayFit (email + social)
│   │   └── screens/
│   │       ├── login_screen.dart
│   │       ├── register_screen.dart
│   │       └── email_auth_screen.dart
│   │
│   ├── onboarding/              ← новый единый онбординг
│   │   └── screens/
│   │       └── onboarding_screen.dart
│   │
│   ├── dashboard/               ← новый главный экран (пользователь делает сам)
│   │   └── screens/
│   │       └── dashboard_screen.dart
│   │
│   ├── nutrition/               ← из KayFit
│   │   ├── screens/
│   │   │   ├── journal_screen.dart
│   │   │   ├── edit_meal_screen.dart
│   │   │   └── add_meal/
│   │   │       ├── add_meal_sheet.dart
│   │   │       ├── barcode_scanner_screen.dart
│   │   │       └── recognition_result_sheet.dart
│   │   ├── providers/
│   │   └── models/ (Meal, Ingredient, Nutrients, Stats)
│   │
│   ├── training/                ← из FitKeep
│   │   ├── screens/
│   │   │   ├── trains_screen.dart
│   │   │   ├── train_detail_screen.dart
│   │   │   ├── workout_exercise_screen.dart
│   │   │   └── trains_generating_screen.dart
│   │   ├── providers/
│   │   └── models/ (Training, Exercise, Equipment)
│   │
│   ├── chat/                    ← НОВЫЙ unified chat
│   │   ├── screens/
│   │   │   └── unified_chat_screen.dart
│   │   ├── providers/
│   │   │   └── chat_provider.dart
│   │   └── models/
│   │       └── chat_message.dart (agent_type добавить)
│   │
│   ├── account/                 ← НОВЫЙ раздел (merge Settings из обоих)
│   │   ├── screens/
│   │   │   ├── account_screen.dart  ← главный экран аккаунта
│   │   │   ├── profile_screen.dart
│   │   │   ├── goals_screen.dart    ← из KayFit
│   │   │   ├── subscription_screen.dart ← из FitKeep + KayFit merge
│   │   │   ├── settings_screen.dart
│   │   │   └── documents_screen.dart
│   │   └── providers/
│   │
│   ├── quiz/                    ← из FitKeep (расширить вопросами)
│   │   └── screens/quiz_screen.dart
│   │
│   ├── equipment/               ← из FitKeep
│   │   └── screens/equipment_screen.dart
│   │
│   ├── body_form/               ← из FitKeep
│   │   └── screens/body_form_screen.dart
│   │
│   ├── way_to_goal/             ← оба, merge
│   │   └── screens/way_to_goal_screen.dart
│   │
│   └── ai_consent/              ← оба, один файл
│       └── screens/ai_consent_screen.dart
│
└── shared/
    ├── models/                  ← merge всех freezed моделей
    ├── widgets/
    │   ├── bottom_nav.dart      ← НОВЫЙ (5 вкладок)
    │   └── ...
    └── theme/
        └── app_theme.dart       ← unified theme
```

### 5.2 Unified Bottom Navigation

```
┌──────────────────────────────────────────────────────────┐
│                  ScaffoldWithBottomNav                    │
│                                                          │
│  branches:                                               │
│  [0] /home          → DashboardScreen                    │
│  [1] /training      → TrainsScreen (из FitKeep)          │
│  [2] /nutrition     → JournalScreen (из KayFit)          │
│  [3] /chat          → UnifiedChatScreen (новый)          │
│  [4] /account       → AccountScreen (новый)              │
│                                                          │
│  BottomNavigationBar items:                              │
│  🏠 Home | 🏋 Workout | 🥗 Nutrition | 💬 Chat | 👤 Account
└──────────────────────────────────────────────────────────┘
```

### 5.3 Unified Router (GoRouter)

```dart
// Публичные маршруты (без auth)
/onboarding
/login
/register
/email-auth

// Setup flow (после auth)
/ai-consent
/quiz
/equipment?setup=true
/body-form
/way-to-goal
/trains-generating

// Main Shell (5 вкладок)
/home              → DashboardScreen
/training          → TrainsScreen
/training/:id      → TrainDetailScreen
/training/:tid/exercise/:eid → WorkoutExerciseScreen
/nutrition         → JournalScreen
/nutrition/meal/:id/edit → EditMealScreen
/chat              → UnifiedChatScreen
/account           → AccountScreen
/account/profile   → ProfileScreen
/account/goals     → GoalsScreen
/account/subscription → SubscriptionScreen
/account/settings  → SettingsScreen
```

### 5.4 Auth State Machine (Unified)

```
                    ┌──────────┐
                    │ UNKNOWN  │ ← начальное состояние
                    └────┬─────┘
                         │ checkSession()
              ┌──────────┴──────────┐
              │                     │
              ▼                     ▼
    ┌──────────────────┐   ┌─────────────────┐
    │ UNAUTHENTICATED  │   │  AUTHENTICATED  │
    │                  │   │                 │
    │ redirect:        │   │ sub-states:     │
    │ /onboarding      │   │ - quizRequired  │
    │   (если новый)   │   │ - equipmentReq  │
    │ /login           │   │ - onboardingOK  │
    └──────────────────┘   └────────┬────────┘
                                    │
                     ┌──────────────┼──────────────┐
                     │              │              │
                     ▼              ▼              ▼
              quizRequired   equipmentReq   onboardingDone
              → /ai-consent  → /equipment   → /home
              → /quiz
```

---

## 6. Unified Auth Provider (State)

```dart
// Единый auth state объединяет оба предыдущих
class UnifiedAuthState {
  AuthStatus status;          // unknown / authenticated / unauthenticated

  // Профиль (из /api/v1/auth/me)
  UserProfile? user;

  // Setup flow flags
  bool aiConsentRequired;     // ai_consent == false
  bool quizRequired;          // quiz не пройден
  bool equipmentRequired;     // equipment не настроен
  bool bodyFormRequired;      // body form не заполнен
  bool onboardingDone;        // весь онбординг пройден

  // Subscription
  bool hasSubscription;
  String? subscriptionPlan;
  DateTime? subscriptionExpires;

  // Nutrition profile presence
  bool hasNutritionProfile;

  // Training profile presence
  bool hasTrainingProfile;
}
```

---

## 7. Onboarding Quiz — детальный список вопросов и API

### 7.1 Вопросы с ключами

```
Группа: common (обязательны для всех)
  gender                 → 'male' | 'female'
  age                    → int
  height_cm              → float
  current_weight_kg      → float
  main_goal              → 'weight_loss' | 'maintenance' | 'muscle_gain'

Группа: nutrition
  target_weight_kg       → float
  activity_level         → 1..5
  dietary_restrictions   → str[] (вегетарианец, аллергия и т.д.)

Группа: training
  current_fat_percentage → float (0-60)
  desired_fat_percentage → float (0-60)
  experience_level       → 'beginner' | 'intermediate' | 'advanced'
  preferred_duration_min → int (20, 30, 45, 60, 90)
  injuries               → str (текст или пусто)
  training_type_pref     → 'strength' | 'cardio' | 'mixed'

Пост-квиз (отдельные экраны):
  equipments             → [ { equipment_id, detail_id, option_id } ]
  body_fat_visual        → str (body form screen)
```

### 7.2 После квиза — автоматические действия на бэкенде

```
POST /api/v1/quiz/complete
  Backend делает:
  1. Читает все quiz_answers пользователя
  2. Считает nutrition goals (calories, protein, fat, carbs)
     по формуле Миффлина-Сан Жеора + TDEE + цель
  3. Сохраняет в user_nutrition_profile
  4. Запускает training_sample_matching
     (подбор программы тренировок по experience, goal, gender)
  5. Возвращает next_step
```

---

## 8. Subscription — единая логика

```
┌───────────────────────────────────────────────────────────┐
│              Единая подписка — Логика доступа              │
│                                                           │
│  hasSubscription = TRUE:                                  │
│    ✓ Полный доступ к Nutrition (AI распознавание, чат)    │
│    ✓ Полный доступ к Training (программы, AI подбор)      │
│    ✓ AI Chat (nutritionist + trainer)                     │
│    ✓ Статистика и прогресс                                │
│                                                           │
│  hasSubscription = FALSE (Free tier):                     │
│    ✓ Базовый дневник питания (ручной ввод)                │
│    ✓ Просмотр тренировок (без AI подбора)                 │
│    ✗ AI распознавание еды                                 │
│    ✗ AI Chat                                              │
│    ✗ Адаптивные программы                                 │
│                                                           │
│  Проверка подписки:                                       │
│    GET /api/v1/auth/me → subscription.expires_at          │
│    expires_at > NOW() → активна                           │
│    Проверяется на каждый auth/me + при входе в платный    │
│    функционал                                             │
└───────────────────────────────────────────────────────────┘
```

---

## 9. Диаграмма взаимодействия компонентов

```
┌─────────┐     ┌─────────┐     ┌─────────────────────────────┐
│  Mobile  │     │ Unified │     │        PostgreSQL DB         │
│   App    │     │  API    │     │                             │
│(Flutter) │     │(FastAPI)│     │  users                      │
│          │     │         │     │  user_nutrition_profile     │
│ Auth     ├────►│ /auth/* ├────►│  user_training_profile      │
│ Provider │◄────│         │◄────│  refresh_tokens             │
│          │     │         │     │                             │
│ Chat     ├────►│ /chat/* │     │  chat_messages              │
│ Screen   │◄────│ Intent  ├────►│                             │
│          │     │ Router  │     │  ┌────────────────────┐     │
│          │     │    │    │     │  │  Claude/GPT API     │     │
│          │     │    └────┼─────┼─►│  (nutritionist/    │     │
│          │     │         │◄────┼──│   trainer/general) │     │
│          │     │         │     │  └────────────────────┘     │
│ Nutrition├────►│/nutrition│    │  meals, foods, meal_items   │
│ Module   │◄────│         │◄────│                             │
│          │     │         │     │                             │
│ Training ├────►│/training│     │  training_samples           │
│ Module   │◄────│         │◄────│  exercize_samples           │
│          │     │         │     │  schedule_trainings         │
│          │     │         │     │  exercize_results           │
│ Account  ├────►│/subscr..│     │  subscriptions              │
│ Screen   │◄────│/user/*  │◄────│  subscription_plans        │
│          │     │         │     │                             │
└─────────┘     └────┬────┘     └─────────────────────────────┘
                      │
                      │  (для Telegram бота)
                      ▼
              ┌───────────────┐
              │ Telegram Bot  │
              │  (aiogram)    │
              │  (тренеры,    │
              │   управление) │
              └───────────────┘
```

---

## 9а. Мультиязычность (i18n / l10n)

### Принцип: таблица `translations` (уже существует в FitnesBot)

В FitnesBot уже реализована таблица переводов — используем её без изменений как основу для unified backend.

```sql
-- Существующая таблица (переносится в unified БД без изменений)
CREATE TABLE IF NOT EXISTS translations (
    id          SERIAL PRIMARY KEY,
    entity_type VARCHAR(32) NOT NULL,   -- тип сущности
    entity_id   INT NOT NULL,           -- ID сущности
    lang        VARCHAR(8) NOT NULL,    -- 'ru', 'en', 'kk', ...
    field       VARCHAR(64) NOT NULL,   -- поле: 'title', 'description', 'name', ...
    value       TEXT,                   -- переведённое значение
    CONSTRAINT translations_unique UNIQUE (entity_type, entity_id, lang, field)
);
CREATE INDEX idx_translations_lookup ON translations(entity_type, entity_id, lang);
```

### Какие сущности переводятся

```
entity_type           → entity_id → fields
─────────────────────────────────────────────────────────────────
'exercise'            → exercises.id          → title, description, muscle_group
'training_sample'     → training_samples.id   → title, description, category, interpretation
'exercize_sample'     → exercize_samples.id   → title, muscle_group
'equipment'           → equipments.id         → title
'equipment_detail'    → equipment_details.id  → name, type
'equipment_option'    → equipment_options.id  → value
'training_type'       → types_of_training.id  → title, description
'food'                → foods.id              → name
'subscription_plan'   → subscription_plans.id → name, description
'achievement'         → achievements.id       → title, description, msg
'quiz_question'       → (question_key)        → text (статичный квиз хранится в коде + переводы в translations)
```

### Как язык определяется в запросе

```
1. Мобильный клиент отправляет заголовок: Accept-Language: ru
   (уже реализовано в FitKeepMobile ApiClient interceptor)

2. Backend dependency get_lang():
   def get_lang(accept_language: str = Header(default='ru')) -> str:
       lang = accept_language.split(',')[0].split('-')[0].strip().lower()
       return lang if lang in SUPPORTED_LANGS else 'ru'
   SUPPORTED_LANGS = {'ru', 'en'}

3. Все endpoints, возвращающие переводимые данные, принимают:
   lang: str = Depends(get_lang)
```

### Паттерн применения переводов в API

```python
# Пример: GET /api/v1/training/{id}
async def get_training(training_id: int, lang: str = Depends(get_lang), db = Depends(get_db)):
    training = await db.get_training(training_id)
    translations = await db.get_translations('exercise', training_id, lang)

    # Применяем переводы поверх оригинала (fallback = оригинальное значение на ru)
    training['title'] = translations.get('title', training['title'])
    training['description'] = translations.get('description', training['description'])
    return training

# Утилита в db:
async def get_translations(entity_type: str, entity_id: int, lang: str) -> dict:
    if lang == 'ru':
        return {}   # ru — базовый язык, хранится в основных полях таблиц
    rows = await conn.fetch(
        "SELECT field, value FROM translations WHERE entity_type=$1 AND entity_id=$2 AND lang=$3",
        entity_type, entity_id, lang
    )
    return {row['field']: row['value'] for row in rows}
```

### Паттерн bulk-переводов (для списков)

```python
# Пример: GET /api/v1/equipment — возвращает список, нужны переводы для каждого
async def get_equipment_with_translations(items: list, entity_type: str, lang: str) -> list:
    if lang == 'ru':
        return items
    ids = [item['id'] for item in items]
    rows = await conn.fetch(
        """SELECT entity_id, field, value FROM translations
           WHERE entity_type=$1 AND entity_id = ANY($2) AND lang=$3""",
        entity_type, ids, lang
    )
    # Группируем по entity_id
    tr_map: dict[int, dict] = {}
    for row in rows:
        tr_map.setdefault(row['entity_id'], {})[row['field']] = row['value']

    for item in items:
        item_tr = tr_map.get(item['id'], {})
        for field in ('title', 'description', 'name'):
            if field in item_tr:
                item[field] = item_tr[field]
    return items
```

### Формат ответа API (с переводами)

```json
// GET /api/v1/equipment (Accept-Language: en)
{
  "equipments": [
    {
      "id": 1,
      "title": "Barbell",          ← переведено из translations
      "title_photo": "...",
      "details": [
        {
          "id": 3,
          "name": "Olympic bar",   ← переведено
          "type": "bar",
          "options": [
            { "id": 7, "value": "20 kg" }
          ]
        }
      ]
    }
  ]
}
```

### Квиз — статичные переводы (quiz_translations.py)

Вопросы квиза хранятся в коде (Python dict) с переводами по языкам — подход уже реализован в FitnesBot через `quiz_translations.py`. В unified backend этот подход **сохраняется** для вопросов квиза. Для новых вопросов онбординга добавляем EN переводы в тот же файл.

```python
# unified_backend/app/services/quiz_translations.py
TRANSLATIONS = {
    'ru': { ... },   # базовый язык
    'en': { ... },   # уже частично есть, расширить
}

def get_quiz_for_lang(lang: str) -> dict:
    return TRANSLATIONS.get(lang, TRANSLATIONS['ru'])
```

### Поддерживаемые языки (v1)

| Язык | Код | Статус |
|------|-----|--------|
| Русский | `ru` | Базовый (обязателен) |
| Английский | `en` | Поддерживается |

---

## 10. Файлы которые нужно создать / изменить

### Backend (новый unified сервис)
```
unified_backend/
├── app/
│   ├── main.py              ← FastAPI app
│   ├── config.py            ← settings
│   ├── database.py          ← asyncpg pool
│   ├── dependencies.py      ← get_current_user, get_db
│   └── routers/
│       ├── auth.py
│       ├── user.py
│       ├── chat.py          ← НОВЫЙ
│       ├── nutrition.py     ← из Calories
│       ├── training.py      ← из FitnesBot
│       ├── equipment.py     ← из FitnesBot
│       ├── quiz.py          ← unified
│       └── subscription.py  ← unified
├── models/
│   ├── user.py              ← SQLAlchemy / dataclasses
│   ├── nutrition.py
│   ├── training.py
│   └── subscription.py
├── services/
│   ├── auth_service.py
│   ├── chat_router.py       ← НОВЫЙ: intent classifier + agents
│   ├── nutrition_service.py
│   ├── training_service.py
│   └── subscription_service.py
├── migrations/
│   ├── 001_create_unified_users.sql
│   ├── 002_create_nutrition_tables.sql
│   ├── 003_migrate_fitnesbot_schema.sql
│   ├── 004_create_chat_table.sql
│   └── 005_create_subscription_plans.sql
└── requirements.txt
```

### Mobile App
```
lib/
├── router.dart              ← полностью переписать
├── core/api/api_client.dart ← новый baseUrl
├── core/auth/auth_provider.dart ← unified state
├── features/chat/           ← новый модуль
├── features/account/        ← новый модуль
└── shared/widgets/bottom_nav.dart ← 5 вкладок
```

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─── USERS & AUTH ─────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS users (
    id                  SERIAL PRIMARY KEY,
    email               VARCHAR(255) UNIQUE,
    password_hash       VARCHAR(255),
    fullname            VARCHAR(255),
    telegram_user_id    BIGINT UNIQUE,
    ai_consent          BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sessions (
    id                  SERIAL PRIMARY KEY,
    user_id             INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    refresh_token_hash  VARCHAR(255) NOT NULL UNIQUE,
    expires_at          TIMESTAMPTZ NOT NULL,
    ip                  VARCHAR(45),
    user_agent          TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_fcm_tokens (
    id          SERIAL PRIMARY KEY,
    user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token       TEXT NOT NULL,
    platform    VARCHAR(20),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, token)
);

-- ─── PROFILES ─────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS nutrition_profiles (
    user_id             INT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    gender              VARCHAR(10),
    birth_date          DATE,
    height_cm           SMALLINT,
    weight_kg           NUMERIC(5,1),
    target_weight_kg    NUMERIC(5,1),
    activity_level      SMALLINT,
    goal                VARCHAR(30),
    dietary_restrictions TEXT,
    calories_goal       INT,
    protein_goal        SMALLINT,
    fat_goal            SMALLINT,
    carbs_goal          SMALLINT,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS training_profiles (
    user_id                 INT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    experience              VARCHAR(20),
    training_type           VARCHAR(30),
    preferred_duration_min  SMALLINT,
    injuries                TEXT,
    current_fat_pct         SMALLINT,
    target_fat_pct          SMALLINT,
    training_days           SMALLINT[],
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── SUBSCRIPTION ─────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS subscription_plans (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    description     TEXT,
    price_rub       NUMERIC(10,2),
    duration_days   INT,
    is_trial        BOOLEAN NOT NULL DEFAULT FALSE,
    features        JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS subscriptions (
    id              SERIAL PRIMARY KEY,
    user_id         INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id         INT REFERENCES subscription_plans(id),
    status          VARCHAR(20) NOT NULL DEFAULT 'active',
    payment_type    VARCHAR(30),
    cost_rub        NUMERIC(10,2),
    start_date      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_date        TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS auto_payments (
    id                  SERIAL PRIMARY KEY,
    subscription_id     INT NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
    payment_token       TEXT NOT NULL,
    provider            VARCHAR(30) NOT NULL DEFAULT 'yookassa',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── TRAINING ─────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS training_types (
    id          SERIAL PRIMARY KEY,
    title       VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS exercises (
    id                  SERIAL PRIMARY KEY,
    title               VARCHAR(255) NOT NULL,
    description         TEXT,
    photo_url           TEXT,
    video_url           TEXT,
    muscle_group        VARCHAR(100),
    documentation       TEXT,
    progression_level   VARCHAR(50),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS training_programs (
    id                  SERIAL PRIMARY KEY,
    sample_type         TEXT NOT NULL,
    training_type_id    INT REFERENCES training_types(id),
    title               VARCHAR(255) NOT NULL,
    description         TEXT,
    equipment_ids       INT[],
    training_count      SMALLINT NOT NULL,
    gender              VARCHAR(10),
    experience          VARCHAR(20),
    intensity           VARCHAR(20),
    category            VARCHAR(50),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS program_workouts (
    id                  SERIAL PRIMARY KEY,
    program_id          INT NOT NULL REFERENCES training_programs(id) ON DELETE CASCADE,
    title               VARCHAR(255) NOT NULL,
    photo_url           TEXT,
    duration_min        SMALLINT,
    week_range          VARCHAR(20),
    muscle_group        VARCHAR(100),
    progression_level   VARCHAR(50),
    position            SMALLINT
);

CREATE TABLE IF NOT EXISTS workout_exercises (
    id              SERIAL PRIMARY KEY,
    workout_id      INT NOT NULL REFERENCES program_workouts(id) ON DELETE CASCADE,
    exercise_id     INT NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    is_mandatory    BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (workout_id, exercise_id)
);

CREATE TABLE IF NOT EXISTS exercise_defaults (
    id                  SERIAL PRIMARY KEY,
    exercise_id         INT NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    workout_id          INT REFERENCES program_workouts(id) ON DELETE SET NULL,
    approach_number     SMALLINT NOT NULL,
    repetitions         SMALLINT NOT NULL,
    weight              NUMERIC(6,2),
    repetition_margin   SMALLINT DEFAULT 0,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (exercise_id, workout_id, approach_number)
);

CREATE TABLE IF NOT EXISTS alternative_exercises (
    exercise_id     INT NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    alternative_id  INT NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    PRIMARY KEY (exercise_id, alternative_id)
);

-- ─── USER TRAINING DATA ───────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS user_programs (
    id              SERIAL PRIMARY KEY,
    user_id         INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    program_id      INT NOT NULL REFERENCES training_programs(id),
    assigned_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    assigned_by     VARCHAR(20) NOT NULL DEFAULT 'system'
);

CREATE TABLE IF NOT EXISTS user_schedules (
    id              SERIAL PRIMARY KEY,
    user_id         INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    program_id      INT NOT NULL REFERENCES training_programs(id),
    workout_id      INT NOT NULL REFERENCES program_workouts(id),
    scheduled_date  DATE NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS exercise_results (
    id              SERIAL PRIMARY KEY,
    user_id         INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    schedule_id     INT NOT NULL REFERENCES user_schedules(id) ON DELETE CASCADE,
    exercise_id     INT NOT NULL REFERENCES exercises(id),
    approach_number SMALLINT NOT NULL,
    repetitions     SMALLINT,
    weight          NUMERIC(6,2),
    video_url       TEXT,
    succeeded       BOOLEAN,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, schedule_id, exercise_id, approach_number)
);

CREATE TABLE IF NOT EXISTS user_exercise_params (
    id              SERIAL PRIMARY KEY,
    user_id         INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    schedule_id     INT NOT NULL REFERENCES user_schedules(id) ON DELETE CASCADE,
    exercise_id     INT NOT NULL REFERENCES exercises(id),
    approach_number SMALLINT NOT NULL,
    repetitions     SMALLINT,
    weight          NUMERIC(6,2),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, schedule_id, exercise_id, approach_number)
);

CREATE TABLE IF NOT EXISTS user_max_weights (
    id          SERIAL PRIMARY KEY,
    user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_id INT NOT NULL REFERENCES exercises(id),
    weight      NUMERIC(6,2) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── EQUIPMENT ────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS equipment_categories (
    id          SERIAL PRIMARY KEY,
    title       VARCHAR(100) NOT NULL,
    photo_url   TEXT
);

CREATE TABLE IF NOT EXISTS equipment_items (
    id          SERIAL PRIMARY KEY,
    category_id INT NOT NULL REFERENCES equipment_categories(id) ON DELETE CASCADE,
    title       VARCHAR(100) NOT NULL,
    photo_url   TEXT
);

CREATE TABLE IF NOT EXISTS equipment_options (
    id      SERIAL PRIMARY KEY,
    item_id INT NOT NULL REFERENCES equipment_items(id) ON DELETE CASCADE,
    title   VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS user_equipment (
    id          SERIAL PRIMARY KEY,
    user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id INT NOT NULL REFERENCES equipment_categories(id),
    item_id     INT NOT NULL REFERENCES equipment_items(id),
    option_id   INT REFERENCES equipment_options(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, item_id)
);

-- ─── NUTRITION ────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS foods (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(255) NOT NULL,
    barcode         VARCHAR(50) UNIQUE,
    calories        NUMERIC(7,2) NOT NULL,
    protein         NUMERIC(6,2),
    fat             NUMERIC(6,2),
    carbs           NUMERIC(6,2),
    fiber           NUMERIC(6,2),
    sugar           NUMERIC(6,2),
    sodium          NUMERIC(7,2),
    serving_size    NUMERIC(7,2),
    serving_unit    VARCHAR(20),
    source          VARCHAR(50),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS meal_logs (
    id          SERIAL PRIMARY KEY,
    user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    log_date    DATE NOT NULL,
    meal_type   VARCHAR(20) NOT NULL,
    food_id     INT REFERENCES foods(id),
    food_name   VARCHAR(255),
    amount_g    NUMERIC(7,2) NOT NULL,
    calories    NUMERIC(7,2) NOT NULL,
    protein     NUMERIC(6,2),
    fat         NUMERIC(6,2),
    carbs       NUMERIC(6,2),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS nutrition_goals (
    id          SERIAL PRIMARY KEY,
    user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    calories    INT NOT NULL,
    protein_g   SMALLINT,
    fat_g       SMALLINT,
    carbs_g     SMALLINT,
    water_ml    SMALLINT,
    valid_from  DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── CHAT ─────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS chat_messages (
    id          SERIAL PRIMARY KEY,
    user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    thread_id   VARCHAR(100),
    role        VARCHAR(20) NOT NULL,
    content     TEXT NOT NULL,
    agent_type  VARCHAR(20),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── QUIZ / ONBOARDING ────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS quiz_answers (
    id              SERIAL PRIMARY KEY,
    user_id         INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    question_key    VARCHAR(50) NOT NULL,
    answer_type     VARCHAR(30) NOT NULL,
    answer          TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, question_key)
);

-- ─── MISC ─────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS landing_bids (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(255),
    email       VARCHAR(255),
    phone       VARCHAR(50),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_actions (
    id          SERIAL PRIMARY KEY,
    user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action      VARCHAR(255) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_patterns (
    user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pkey        VARCHAR(100) NOT NULL,
    pvalue      TEXT NOT NULL,
    PRIMARY KEY (user_id, pkey)
);

CREATE TABLE IF NOT EXISTS translations (
    entity_type VARCHAR(50)  NOT NULL,
    entity_id   INT          NOT NULL,
    lang        VARCHAR(5)   NOT NULL,
    field       VARCHAR(50)  NOT NULL,
    value       TEXT         NOT NULL,
    PRIMARY KEY (entity_type, entity_id, lang, field)
);

-- ─── INDEXES ──────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_expires_at ON sessions(expires_at);
CREATE INDEX IF NOT EXISTS idx_meal_logs_user_date ON meal_logs(user_id, log_date);
CREATE INDEX IF NOT EXISTS idx_user_schedules_user_date ON user_schedules(user_id, scheduled_date);
CREATE INDEX IF NOT EXISTS idx_exercise_results_user_schedule ON exercise_results(user_id, schedule_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_user ON chat_messages(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_quiz_answers_user ON quiz_answers(user_id);
CREATE INDEX IF NOT EXISTS idx_user_actions_user ON user_actions(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_foods_barcode ON foods(barcode);
CREATE INDEX IF NOT EXISTS idx_training_programs_type ON training_programs(sample_type);
CREATE INDEX IF NOT EXISTS idx_translations_lookup ON translations(entity_type, entity_id, lang);

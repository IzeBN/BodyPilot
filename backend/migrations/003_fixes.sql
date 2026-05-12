-- ─── NUTRITION GOALS: unique constraint for proper upsert ──────────────────
-- Ensures one row per user per day so upsert works correctly instead of
-- silently inserting unlimited duplicate rows.
ALTER TABLE nutrition_goals
    ADD CONSTRAINT IF NOT EXISTS nutrition_goals_user_date_uq UNIQUE (user_id, valid_from);

-- ─── EXERCISE DURATION DEFAULTS ────────────────────────────────────────────
-- Referenced in training_service.get_exercise_detail but missing from schema.
CREATE TABLE IF NOT EXISTS duration_exercizes (
    exercise_id          INT     PRIMARY KEY REFERENCES exercises(id) ON DELETE CASCADE,
    repetition_duration  SMALLINT NOT NULL DEFAULT 5,   -- seconds per rep
    break_duration       SMALLINT NOT NULL DEFAULT 30   -- seconds between sets
);

-- ─── USER EXERCISE OVERRIDES ───────────────────────────────────────────────
-- Per-user per-schedule exercise replacements.
-- Fixes a critical data-integrity bug: previously replace_exercise_in_schedule
-- mutated the shared workout_exercises table, affecting ALL users with the
-- same workout. Now overrides are isolated per user.
CREATE TABLE IF NOT EXISTS user_exercise_overrides (
    id               SERIAL    PRIMARY KEY,
    user_id          INT       NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    schedule_id      INT       NOT NULL REFERENCES user_schedules(id) ON DELETE CASCADE,
    old_exercise_id  INT       NOT NULL REFERENCES exercises(id),
    new_exercise_id  INT       NOT NULL REFERENCES exercises(id),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, schedule_id, old_exercise_id)
);

CREATE INDEX IF NOT EXISTS idx_user_exercise_overrides_schedule
    ON user_exercise_overrides(user_id, schedule_id);

-- ─── WEBHOOK IDEMPOTENCY ───────────────────────────────────────────────────
-- Replaces in-memory _processed_payments dict that didn't survive restarts.
CREATE TABLE IF NOT EXISTS processed_webhook_events (
    event_id    VARCHAR(100) PRIMARY KEY,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

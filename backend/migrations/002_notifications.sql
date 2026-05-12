CREATE TABLE IF NOT EXISTS notification_history (
    id              SERIAL PRIMARY KEY,
    title           TEXT NOT NULL,
    body            TEXT NOT NULL,
    data            JSONB,
    sent_by         INT REFERENCES users(id) ON DELETE SET NULL,
    target_user_ids INT[],
    all_users       BOOLEAN NOT NULL DEFAULT FALSE,
    sent_count      INT NOT NULL DEFAULT 0,
    failed_count    INT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS admin_users (
    user_id     INT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    role        VARCHAR(30) NOT NULL DEFAULT 'admin',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS training_tasks (
    id          VARCHAR(36) PRIMARY KEY,
    user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status      VARCHAR(20) NOT NULL DEFAULT 'running',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE user_schedules
    ADD COLUMN IF NOT EXISTS interpretation TEXT,
    ADD COLUMN IF NOT EXISTS stages         TEXT;

CREATE INDEX IF NOT EXISTS idx_notification_history_created ON notification_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_training_tasks_user ON training_tasks(user_id);

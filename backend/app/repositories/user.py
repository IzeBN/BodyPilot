import asyncpg
from app.repositories.base import BaseRepository

# Whitelisted columns protect against accidental or malicious column injection
# via dynamic f-string SQL building.
_ALLOWED_USER_FIELDS = frozenset({"fullname", "email"})

_ALLOWED_NUTRITION_FIELDS = frozenset({
    "gender", "birth_date", "height_cm", "weight_kg", "target_weight_kg",
    "activity_level", "goal", "dietary_restrictions",
    "calories_goal", "protein_goal", "fat_goal", "carbs_goal",
})

_ALLOWED_TRAINING_FIELDS = frozenset({
    "experience", "training_type", "preferred_duration_min",
    "injuries", "current_fat_pct", "target_fat_pct", "training_days",
})


def _check_fields(fields: dict, allowed: frozenset, table: str) -> None:
    bad = set(fields) - allowed
    if bad:
        raise ValueError(f"Disallowed fields for {table}: {bad}")


class UserRepository(BaseRepository):

    async def get_profile(self, user_id: int) -> asyncpg.Record | None:
        async with self.pool.acquire() as conn:
            return await conn.fetchrow(
                "SELECT * FROM users WHERE id = $1", user_id
            )

    async def update_profile(self, user_id: int, **fields) -> None:
        if not fields:
            return
        _check_fields(fields, _ALLOWED_USER_FIELDS, "users")
        sets = ", ".join(f"{k} = ${i+2}" for i, k in enumerate(fields))
        async with self.pool.acquire() as conn:
            await conn.execute(
                f"UPDATE users SET {sets}, updated_at = NOW() WHERE id = $1",
                user_id, *fields.values(),
            )

    async def upsert_nutrition_profile(self, user_id: int, **fields) -> None:
        if not fields:
            return
        _check_fields(fields, _ALLOWED_NUTRITION_FIELDS, "nutrition_profiles")
        cols = list(fields.keys())
        vals = list(fields.values())
        placeholders = ", ".join(f"${i+2}" for i in range(len(cols)))
        col_names = ", ".join(cols)
        updates = ", ".join(f"{c} = EXCLUDED.{c}" for c in cols)
        async with self.pool.acquire() as conn:
            await conn.execute(
                f"""INSERT INTO nutrition_profiles (user_id, {col_names})
                    VALUES ($1, {placeholders})
                    ON CONFLICT (user_id) DO UPDATE SET {updates}, updated_at = NOW()""",
                user_id, *vals,
            )

    async def get_nutrition_profile(self, user_id: int) -> asyncpg.Record | None:
        async with self.pool.acquire() as conn:
            return await conn.fetchrow(
                "SELECT * FROM nutrition_profiles WHERE user_id = $1", user_id
            )

    async def upsert_training_profile(self, user_id: int, **fields) -> None:
        if not fields:
            return
        _check_fields(fields, _ALLOWED_TRAINING_FIELDS, "training_profiles")
        cols = list(fields.keys())
        vals = list(fields.values())
        placeholders = ", ".join(f"${i+2}" for i in range(len(cols)))
        col_names = ", ".join(cols)
        updates = ", ".join(f"{c} = EXCLUDED.{c}" for c in cols)
        async with self.pool.acquire() as conn:
            await conn.execute(
                f"""INSERT INTO training_profiles (user_id, {col_names})
                    VALUES ($1, {placeholders})
                    ON CONFLICT (user_id) DO UPDATE SET {updates}, updated_at = NOW()""",
                user_id, *vals,
            )

    async def get_training_profile(self, user_id: int) -> asyncpg.Record | None:
        async with self.pool.acquire() as conn:
            return await conn.fetchrow(
                "SELECT * FROM training_profiles WHERE user_id = $1", user_id
            )

    async def add_action(self, user_id: int, action: str) -> None:
        async with self.pool.acquire() as conn:
            last = await conn.fetchval(
                """SELECT id FROM user_actions WHERE user_id = $1 AND action = $2
                   AND created_at > NOW() - INTERVAL '30 seconds'""",
                user_id, action,
            )
            if not last:
                await conn.execute(
                    "INSERT INTO user_actions (user_id, action) VALUES ($1, $2)",
                    user_id, action,
                )

    async def get_actions(self, user_id: int, limit: int = 50) -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            return await conn.fetch(
                "SELECT * FROM user_actions WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2",
                user_id, limit,
            )

    async def upsert_pattern(self, user_id: int, pkey: str, pvalue: str) -> None:
        async with self.pool.acquire() as conn:
            await conn.execute(
                """INSERT INTO user_patterns (user_id, pkey, pvalue) VALUES ($1, $2, $3)
                   ON CONFLICT (user_id, pkey) DO UPDATE SET pvalue = EXCLUDED.pvalue""",
                user_id, pkey, pvalue,
            )

    async def get_all_patterns(self, user_id: int) -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            return await conn.fetch(
                "SELECT pkey, pvalue FROM user_patterns WHERE user_id = $1", user_id
            )

    async def get_full_profile(self, user_id: int) -> dict:
        async with self.pool.acquire() as conn:
            user = await conn.fetchrow("SELECT * FROM users WHERE id = $1", user_id)
            nutrition = await conn.fetchrow(
                "SELECT * FROM nutrition_profiles WHERE user_id = $1", user_id
            )
            training = await conn.fetchrow(
                "SELECT * FROM training_profiles WHERE user_id = $1", user_id
            )
            subscription = await conn.fetchrow(
                """SELECT s.*, p.name plan_name FROM subscriptions s
                   JOIN subscription_plans p ON p.id = s.plan_id
                   WHERE s.user_id = $1 AND s.status = 'active' ORDER BY s.end_date DESC LIMIT 1""",
                user_id,
            )
            return {
                "user": dict(user) if user else None,
                "nutrition_profile": dict(nutrition) if nutrition else None,
                "training_profile": dict(training) if training else None,
                "subscription": dict(subscription) if subscription else None,
            }

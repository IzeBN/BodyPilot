import asyncpg
import json
from app.repositories.base import BaseRepository


class NotificationsRepository(BaseRepository):

    async def save_history(
        self,
        title: str,
        body: str,
        data: dict | None,
        sent_by: int,
        target_user_ids: list[int] | None,
        all_users: bool,
        sent_count: int,
        failed_count: int,
    ) -> int:
        async with self.pool.acquire() as conn:
            return await conn.fetchval(
                """INSERT INTO notification_history
                       (title, body, data, sent_by, target_user_ids, all_users, sent_count, failed_count)
                   VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id""",
                title, body,
                json.dumps(data) if data else None,
                sent_by, target_user_ids, all_users, sent_count, failed_count,
            )

    async def get_history(self, limit: int = 50) -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            return await conn.fetch(
                "SELECT * FROM notification_history ORDER BY created_at DESC LIMIT $1", limit
            )

    async def upsert_task(self, task_id: str, user_id: int, status: str) -> None:
        async with self.pool.acquire() as conn:
            await conn.execute(
                """INSERT INTO training_tasks (id, user_id, status)
                   VALUES ($1, $2, $3)
                   ON CONFLICT (id) DO UPDATE SET status = EXCLUDED.status, updated_at = NOW()""",
                task_id, user_id, status,
            )

    async def get_task(self, task_id: str) -> asyncpg.Record | None:
        async with self.pool.acquire() as conn:
            return await conn.fetchrow(
                "SELECT * FROM training_tasks WHERE id = $1", task_id
            )

    async def is_admin(self, user_id: int) -> bool:
        from app.config import get_settings
        s = get_settings()
        return user_id in s.admin_ids

    async def get_all_users_for_admin(self) -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            return await conn.fetch(
                """SELECT u.id, u.email, u.fullname, u.telegram_user_id, u.created_at,
                          s.status subscription_status, s.end_date subscription_end
                   FROM users u
                   LEFT JOIN subscriptions s ON s.user_id = u.id AND s.status = 'active'
                   ORDER BY u.created_at DESC"""
            )

    async def get_user_actions_for_admin(self, user_id: int) -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            return await conn.fetch(
                "SELECT * FROM user_actions WHERE user_id = $1 ORDER BY created_at DESC",
                user_id,
            )

    async def get_user_chat_for_admin(self, user_id: int) -> dict:
        async with self.pool.acquire() as conn:
            user = await conn.fetchrow("SELECT * FROM users WHERE id = $1", user_id)
            nutrition = await conn.fetchrow(
                "SELECT * FROM nutrition_profiles WHERE user_id = $1", user_id
            )
            training = await conn.fetchrow(
                "SELECT * FROM training_profiles WHERE user_id = $1", user_id
            )
            schedule = await conn.fetch(
                """SELECT us.*, pw.title workout_title, pw.muscle_group
                   FROM user_schedules us
                   JOIN program_workouts pw ON pw.id = us.workout_id
                   WHERE us.user_id = $1 ORDER BY us.scheduled_date""",
                user_id,
            )
            equipment = await conn.fetch(
                """SELECT ue.*, ec.title category_title, ei.title item_title
                   FROM user_equipment ue
                   JOIN equipment_categories ec ON ec.id = ue.category_id
                   JOIN equipment_items ei ON ei.id = ue.item_id
                   WHERE ue.user_id = $1""",
                user_id,
            )
            quiz = await conn.fetch(
                "SELECT * FROM quiz_answers WHERE user_id = $1 ORDER BY question_key",
                user_id,
            )
        return {
            "user": dict(user) if user else None,
            "nutrition_profile": dict(nutrition) if nutrition else None,
            "training_profile": dict(training) if training else None,
            "schedule": [dict(r) for r in schedule],
            "equipment": [dict(r) for r in equipment],
            "quiz": [dict(r) for r in quiz],
        }

    async def get_chat_messages_for_admin(self, user_id: int) -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            return await conn.fetch(
                "SELECT * FROM chat_messages WHERE user_id = $1 ORDER BY created_at",
                user_id,
            )

    async def get_analytics(self, start_date, end_date) -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            return await conn.fetch(
                """SELECT
                       date_trunc('day', u.created_at)::date reg_date,
                       COUNT(DISTINCT u.id) new_users,
                       COUNT(DISTINCT s.user_id) new_subscribers,
                       COUNT(DISTINCT er.user_id) active_trainers
                   FROM users u
                   LEFT JOIN subscriptions s ON s.user_id = u.id
                       AND s.created_at BETWEEN $1 AND $2
                   LEFT JOIN exercise_results er ON er.user_id = u.id
                       AND er.created_at BETWEEN $1 AND $2
                   WHERE u.created_at BETWEEN $1 AND $2
                   GROUP BY 1 ORDER BY 1""",
                start_date, end_date,
            )

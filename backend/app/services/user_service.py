import datetime
import calendar
from fastapi import HTTPException

from app.repositories.user import UserRepository
from app.repositories.auth import AuthRepository


class UserService:
    def __init__(self, user_repo: UserRepository, auth_repo: AuthRepository) -> None:
        self._repo = user_repo
        self._auth = auth_repo

    async def get_full_profile(self, user_id: int) -> dict:
        profile = await self._repo.get_full_profile(user_id)
        if not profile.get("user"):
            raise HTTPException(404, detail="User not found")
        return profile

    async def update_profile(self, user_id: int, fields: dict) -> None:
        if not fields:
            return
        await self._repo.update_profile(user_id, **fields)

    async def upsert_nutrition_profile(self, user_id: int, fields: dict) -> None:
        await self._repo.upsert_nutrition_profile(user_id, **fields)

    async def get_nutrition_profile(self, user_id: int) -> dict:
        row = await self._repo.get_nutrition_profile(user_id)
        return dict(row) if row else {}

    async def upsert_training_profile(self, user_id: int, fields: dict) -> None:
        await self._repo.upsert_training_profile(user_id, **fields)

    async def get_training_profile(self, user_id: int) -> dict:
        row = await self._repo.get_training_profile(user_id)
        return dict(row) if row else {}

    async def add_action(self, user_id: int, action: str) -> None:
        await self._repo.add_action(user_id, action)

    async def get_weekly_progress(self, user_id: int) -> dict:
        today = datetime.date.today()
        week_day = calendar.weekday(today.year, today.month, today.day)
        start_date = today - datetime.timedelta(days=week_day)
        end_date = start_date + datetime.timedelta(days=6)

        pool = self._repo.pool
        async with pool.acquire() as conn:
            rows = await conn.fetch(
                """SELECT scheduled_date, status FROM user_schedules
                   WHERE user_id = $1 AND scheduled_date BETWEEN $2 AND $3""",
                user_id, start_date, end_date,
            )
            name_rows = await conn.fetch(
                """SELECT us.scheduled_date, tp.title
                   FROM user_schedules us
                   JOIN training_programs tp ON tp.id = us.program_id
                   WHERE us.user_id = $1 AND us.scheduled_date BETWEEN $2 AND $3""",
                user_id, start_date, end_date,
            )
        name_map = {r["scheduled_date"]: r["title"] for r in name_rows}
        progress_map = {r["scheduled_date"]: r["status"] for r in rows}
        days = []
        for i in range(7):
            d = start_date + datetime.timedelta(days=i)
            days.append({
                "date": str(d),
                "status": progress_map.get(d, "none"),
                "workout_name": name_map.get(d),
            })
        return {
            "week_start": str(start_date),
            "days": days,
        }

    async def clear_training_data(self, user_id: int) -> None:
        pool = self._repo.pool
        async with pool.acquire() as conn:
            async with conn.transaction():
                await conn.execute("DELETE FROM exercise_results WHERE user_id = $1", user_id)
                await conn.execute("DELETE FROM user_schedules WHERE user_id = $1", user_id)
                await conn.execute("DELETE FROM user_programs WHERE user_id = $1", user_id)
        await self._repo.add_action(user_id, "Cleared training data")

    async def register_fcm_token(self, user_id: int, token: str, platform: str) -> None:
        if platform not in ("android", "ios"):
            raise HTTPException(400, detail="platform must be 'android' or 'ios'")
        await self._auth.upsert_fcm_token(user_id, token, platform)

    async def update_ai_consent(self, user_id: int, consent: bool) -> None:
        await self._auth.update_ai_consent(user_id, consent)

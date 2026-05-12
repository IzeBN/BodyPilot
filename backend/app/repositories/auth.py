import asyncpg
from datetime import datetime, timezone
from app.repositories.base import BaseRepository


class AuthRepository(BaseRepository):

    async def get_user_by_email(self, email: str) -> asyncpg.Record | None:
        async with self.pool.acquire() as conn:
            return await conn.fetchrow(
                "SELECT id, email, password_hash, fullname, ai_consent FROM users WHERE email = $1",
                email.lower(),
            )

    async def get_user_by_id(self, user_id: int) -> asyncpg.Record | None:
        async with self.pool.acquire() as conn:
            return await conn.fetchrow(
                "SELECT id, email, fullname, telegram_user_id, ai_consent FROM users WHERE id = $1",
                user_id,
            )

    async def get_user_by_telegram_id(self, telegram_user_id: int) -> asyncpg.Record | None:
        async with self.pool.acquire() as conn:
            return await conn.fetchrow(
                "SELECT id, email, fullname, telegram_user_id, ai_consent FROM users WHERE telegram_user_id = $1",
                telegram_user_id,
            )

    async def create_user(self, email: str, password_hash: str, fullname: str | None) -> int:
        async with self.pool.acquire() as conn:
            return await conn.fetchval(
                """INSERT INTO users (email, password_hash, fullname)
                   VALUES ($1, $2, $3) RETURNING id""",
                email.lower(), password_hash, fullname,
            )

    async def create_telegram_user(self, telegram_user_id: int, fullname: str | None) -> int:
        async with self.pool.acquire() as conn:
            return await conn.fetchval(
                """INSERT INTO users (telegram_user_id, fullname)
                   VALUES ($1, $2)
                   ON CONFLICT (telegram_user_id) DO UPDATE SET fullname = EXCLUDED.fullname
                   RETURNING id""",
                telegram_user_id, fullname,
            )

    async def create_session(
        self, user_id: int, refresh_token_hash: str, expires_at: datetime,
        ip: str | None = None, user_agent: str | None = None,
    ) -> None:
        async with self.pool.acquire() as conn:
            await conn.execute(
                """INSERT INTO sessions (user_id, refresh_token_hash, expires_at, ip, user_agent)
                   VALUES ($1, $2, $3, $4, $5)""",
                user_id, refresh_token_hash, expires_at, ip, user_agent,
            )

    async def get_session_by_token_hash(self, token_hash: str) -> asyncpg.Record | None:
        async with self.pool.acquire() as conn:
            return await conn.fetchrow(
                """SELECT id, user_id, expires_at FROM sessions
                   WHERE refresh_token_hash = $1""",
                token_hash,
            )

    async def delete_session(self, token_hash: str) -> None:
        async with self.pool.acquire() as conn:
            await conn.execute(
                "DELETE FROM sessions WHERE refresh_token_hash = $1", token_hash
            )

    async def delete_expired_sessions(self) -> None:
        async with self.pool.acquire() as conn:
            await conn.execute(
                "DELETE FROM sessions WHERE expires_at < NOW()"
            )

    async def upsert_fcm_token(self, user_id: int, token: str, platform: str) -> None:
        async with self.pool.acquire() as conn:
            await conn.execute(
                """INSERT INTO user_fcm_tokens (user_id, token, platform)
                   VALUES ($1, $2, $3)
                   ON CONFLICT (user_id, token) DO NOTHING""",
                user_id, token, platform,
            )

    async def delete_user(self, user_id: int) -> None:
        async with self.pool.acquire() as conn:
            await conn.execute("DELETE FROM users WHERE id = $1", user_id)

    async def update_ai_consent(self, user_id: int, consent: bool) -> None:
        async with self.pool.acquire() as conn:
            await conn.execute(
                "UPDATE users SET ai_consent = $1, updated_at = NOW() WHERE id = $2",
                consent, user_id,
            )

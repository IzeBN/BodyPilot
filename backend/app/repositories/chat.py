import asyncpg
from app.repositories.base import BaseRepository


class ChatRepository(BaseRepository):

    async def add_message(
        self, user_id: int, thread_id: str, role: str,
        content: str, agent_type: "str | None" = None,
    ) -> int:
        async with self.pool.acquire() as conn:
            return await conn.fetchval(
                """INSERT INTO chat_messages (user_id, thread_id, role, content, agent_type)
                   VALUES ($1, $2, $3, $4, $5) RETURNING id""",
                user_id, thread_id, role, content, agent_type,
            )

    async def get_history(
        self, user_id: int, thread_id: "str | None" = None, limit: int = 50
    ) -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            if thread_id:
                return await conn.fetch(
                    """SELECT * FROM chat_messages
                       WHERE user_id = $1 AND thread_id = $2
                       ORDER BY created_at DESC LIMIT $3""",
                    user_id, thread_id, limit,
                )
            return await conn.fetch(
                """SELECT * FROM chat_messages WHERE user_id = $1
                   ORDER BY created_at DESC LIMIT $2""",
                user_id, limit,
            )

    async def get_thread_context(
        self, user_id: int, thread_id: str, limit: int = 20
    ) -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            return await conn.fetch(
                """SELECT role, content FROM chat_messages
                   WHERE user_id = $1 AND thread_id = $2
                   ORDER BY created_at DESC LIMIT $3""",
                user_id, thread_id, limit,
            )

    async def delete_history(self, user_id: int) -> None:
        async with self.pool.acquire() as conn:
            await conn.execute(
                "DELETE FROM chat_messages WHERE user_id = $1", user_id
            )

    async def delete_history_by_agent(self, user_id: int, agent_type: str) -> None:
        async with self.pool.acquire() as conn:
            await conn.execute(
                "DELETE FROM chat_messages WHERE user_id = $1 AND agent_type = $2",
                user_id, agent_type,
            )

import asyncpg
from app.repositories.base import BaseRepository


class QuizRepository(BaseRepository):

    async def upsert_answer(
        self, user_id: int, question_key: str, answer_type: str, answer: str
    ) -> None:
        async with self.pool.acquire() as conn:
            await conn.execute(
                """INSERT INTO quiz_answers (user_id, question_key, answer_type, answer)
                   VALUES ($1, $2, $3, $4)
                   ON CONFLICT (user_id, question_key)
                   DO UPDATE SET answer = EXCLUDED.answer, answer_type = EXCLUDED.answer_type,
                                 updated_at = NOW()""",
                user_id, question_key, answer_type, answer,
            )

    async def get_answers(self, user_id: int, keys: list[str] | None = None) -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            if keys:
                return await conn.fetch(
                    "SELECT * FROM quiz_answers WHERE user_id = $1 AND question_key = ANY($2)",
                    user_id, keys,
                )
            return await conn.fetch(
                "SELECT * FROM quiz_answers WHERE user_id = $1 ORDER BY created_at",
                user_id,
            )

    async def get_answer(self, user_id: int, question_key: str) -> asyncpg.Record | None:
        async with self.pool.acquire() as conn:
            return await conn.fetchrow(
                "SELECT * FROM quiz_answers WHERE user_id = $1 AND question_key = $2",
                user_id, question_key,
            )

from asyncpg import Pool
from app.repositories.quiz import QuizRepository
from app.repositories.user import UserRepository


class QuizService:
    def __init__(self, quiz_repo: QuizRepository, user_repo: UserRepository, pool: Pool) -> None:
        self._quiz = quiz_repo
        self._users = user_repo
        self._pool = pool

    async def save_answer(self, user_id: int, question_key: str, answer_type: str, answer) -> None:
        answer_str = (
            answer if isinstance(answer, str)
            else "%".join(str(v) for v in answer) if isinstance(answer, list)
            else str(answer)
        )
        await self._quiz.upsert_answer(user_id, question_key, answer_type, answer_str)
        await self._users.add_action(user_id, f"Quiz answer: {question_key}")

    async def find_answers(self, user_id: int, keys: list[str]) -> list[dict]:
        rows = await self._quiz.get_answers(user_id, keys)
        return [dict(r) for r in rows]

    async def get_all_answers(self, user_id: int) -> list[dict]:
        rows = await self._quiz.get_answers(user_id)
        return [dict(r) for r in rows]

    async def request_consultation(self, user_id: int, date: str, time: str) -> None:
        from app.config import get_settings
        import httpx

        s = get_settings()
        async with self._pool.acquire() as conn:
            user = await conn.fetchrow("SELECT * FROM users WHERE id = $1", user_id)

        if s.telegram_bot_token and s.telegram_users_chat_id:
            name = (user["fullname"] if user else None) or f"ID:{user_id}"
            text = (
                f"<b>Запрос консультации</b>\n"
                f"Пользователь: {name} (ID: {user_id})\n"
                f"Дата: {date}, Время: {time}"
            )
            async with httpx.AsyncClient() as client:
                try:
                    await client.post(
                        f"https://api.telegram.org/bot{s.telegram_bot_token}/sendMessage",
                        json={"chat_id": s.telegram_users_chat_id, "text": text, "parse_mode": "HTML"},
                        timeout=5,
                    )
                except Exception:
                    pass

        await self._users.add_action(user_id, f"Consultation requested: {date} {time}")

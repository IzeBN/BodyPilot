from asyncpg import Pool
from app.repositories.chat import ChatRepository
from app.repositories.user import UserRepository
from app.services.chat_router import (
    process_chat_message,
    process_training_message,
    process_nutrition_message,
)


class ChatService:
    def __init__(self, chat_repo: ChatRepository, user_repo: UserRepository, pool: Pool) -> None:
        self._chat = chat_repo
        self._users = user_repo
        self._pool = pool

    # ── Training chat ─────────────────────────────────────────────────────────

    async def send_training_message(self, user_id: int, message: str, thread_id: "str | None") -> dict:
        result = await process_training_message(user_id, message, thread_id, self._pool)
        await self._users.add_action(user_id, "Sent training chat message")
        return result

    async def get_training_history(self, user_id: int, thread_id: "str | None", limit: int) -> list[dict]:
        if not thread_id:
            thread_id = f"training_{user_id}"
        rows = await self._chat.get_history(user_id, thread_id, limit)
        return [dict(r) for r in reversed(rows)]

    async def clear_training_history(self, user_id: int) -> None:
        await self._chat.delete_history_by_agent(user_id, "training")
        await self._users.add_action(user_id, "Cleared training chat history")

    # ── Nutrition chat ────────────────────────────────────────────────────────

    async def send_nutrition_message(self, user_id: int, message: str, thread_id: "str | None") -> dict:
        result = await process_nutrition_message(user_id, message, thread_id, self._pool)
        await self._users.add_action(user_id, "Sent nutrition chat message")
        return result

    async def get_nutrition_history(self, user_id: int, thread_id: "str | None", limit: int) -> list[dict]:
        if not thread_id:
            thread_id = f"nutrition_{user_id}"
        rows = await self._chat.get_history(user_id, thread_id, limit)
        return [dict(r) for r in reversed(rows)]

    async def clear_nutrition_history(self, user_id: int) -> None:
        await self._chat.delete_history_by_agent(user_id, "nutrition")
        await self._users.add_action(user_id, "Cleared nutrition chat history")

    # ── Legacy (keeps existing tests passing) ─────────────────────────────────

    async def send_message(self, user_id: int, message: str, thread_id: "str | None") -> dict:
        result = await process_chat_message(user_id, message, thread_id, self._pool)
        await self._users.add_action(user_id, f"Sent chat message (agent: {result['agent_type']})")
        return result

    async def get_history(self, user_id: int, thread_id: "str | None", limit: int) -> list[dict]:
        rows = await self._chat.get_history(user_id, thread_id, limit)
        return [dict(r) for r in reversed(rows)]

    async def clear_history(self, user_id: int) -> None:
        await self._chat.delete_history(user_id)
        await self._users.add_action(user_id, "Cleared chat history")

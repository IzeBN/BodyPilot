from asyncpg import Pool
from fastapi import HTTPException

from app.repositories.notifications import NotificationsRepository
from app.repositories.chat import ChatRepository
from app.services.fcm import FCMService


class AdminService:
    def __init__(
        self,
        notifications_repo: NotificationsRepository,
        chat_repo: ChatRepository,
        pool: Pool,
    ) -> None:
        self._notif = notifications_repo
        self._chat = chat_repo
        self._pool = pool

    async def send_push(
        self,
        admin_id: int,
        title: str,
        body: str,
        user_ids: list[int] | None,
        all_users: bool,
        data: dict | None,
    ) -> dict:
        if not user_ids and not all_users:
            raise HTTPException(400, detail="Specify user_ids or set all_users=true")

        fcm = FCMService(pool=self._pool)
        if all_users:
            result = await fcm.send_to_all_users(title, body, data)
        else:
            result = await fcm.send_to_users(user_ids, title, body, data)

        await self._notif.save_history(
            title=title, body=body, data=data, sent_by=admin_id,
            target_user_ids=user_ids, all_users=all_users,
            sent_count=result["success_count"], failed_count=result["failure_count"],
        )
        return {"sent": result["success_count"], "failed": result["failure_count"]}

    async def get_notification_history(self, limit: int) -> list[dict]:
        rows = await self._notif.get_history(limit)
        return [dict(r) for r in rows]

    async def get_all_users(self) -> list[dict]:
        rows = await self._notif.get_all_users_for_admin()
        return [dict(r) for r in rows]

    async def get_user_actions(self, user_id: int) -> list[dict]:
        rows = await self._notif.get_user_actions_for_admin(user_id)
        return [dict(r) for r in rows]

    async def get_user_full_data(self, user_id: int) -> dict:
        return await self._notif.get_user_chat_for_admin(user_id)

    async def get_user_messages(self, user_id: int) -> list[dict]:
        rows = await self._notif.get_chat_messages_for_admin(user_id)
        return [dict(r) for r in rows]

    async def send_telegram_message(self, admin_id: int, user_id: int, msg: str | None, image_data: bytes | None, image_filename: str | None, image_content_type: str | None) -> None:
        from app.config import get_settings
        import httpx

        s = get_settings()
        if not s.telegram_bot_token:
            raise HTTPException(400, detail="Telegram bot not configured")

        async with self._pool.acquire() as conn:
            tg_id: int | None = await conn.fetchval(
                "SELECT telegram_user_id FROM users WHERE id = $1", user_id
            )
        if not tg_id:
            raise HTTPException(400, detail="User has no Telegram account linked")

        bot_url = f"https://api.telegram.org/bot{s.telegram_bot_token}"
        try:
            async with httpx.AsyncClient() as client:
                if image_data and image_content_type and image_content_type.startswith("image/"):
                    await client.post(
                        f"{bot_url}/sendPhoto",
                        data={"chat_id": tg_id, "caption": msg or ""},
                        files={"photo": (image_filename or "image.jpg", image_data, image_content_type)},
                    )
                    message_text = f"[Image]{' - ' + msg if msg else ''}"
                else:
                    if not msg:
                        raise HTTPException(400, detail="Text required when no image")
                    await client.post(
                        f"{bot_url}/sendMessage",
                        json={"chat_id": tg_id, "text": msg, "parse_mode": "HTML"},
                    )
                    message_text = msg
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(400, detail=str(e))

        await self._chat.add_message(user_id, f"support-{user_id}", "support", message_text)

    async def get_analytics(self, start_date, end_date) -> list[dict]:
        rows = await self._notif.get_analytics(start_date, end_date)
        return [dict(r) for r in rows]

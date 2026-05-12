import asyncio
import logging
import os
from typing import Optional

logger = logging.getLogger("FCM")

_firebase_initialized = False
_fcm_app = None


def _init_firebase() -> bool:
    global _firebase_initialized, _fcm_app
    if _firebase_initialized:
        return _fcm_app is not None
    path = os.environ.get("FIREBASE_CREDENTIALS_PATH", "")
    if not path or not os.path.exists(path):
        logger.warning("FCM_SERVICE_ACCOUNT_PATH missing — push notifications disabled")
        _firebase_initialized = True
        return False
    try:
        import firebase_admin
        from firebase_admin import credentials
        cred = credentials.Certificate(path)
        _fcm_app = firebase_admin.initialize_app(cred)
        _firebase_initialized = True
        logger.info("Firebase Admin SDK initialized")
        return True
    except Exception as e:
        logger.error(f"Firebase init failed: {e}")
        _firebase_initialized = True
        return False


class FCMService:
    def __init__(self, pool=None):
        self.pool = pool
        self._ready = _init_firebase()

    async def send_to_token(self, token: str, title: str, body: str, data: Optional[dict] = None) -> bool:
        if not self._ready:
            return False
        try:
            from firebase_admin import messaging
            msg = messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                data={str(k): str(v) for k, v in (data or {}).items()},
                token=token,
            )
            loop = asyncio.get_running_loop()
            await loop.run_in_executor(None, messaging.send, msg)
            return True
        except Exception as e:
            logger.error(f"send_to_token failed: {e}")
            return False

    async def send_to_tokens(self, tokens: list[str], title: str, body: str, data: Optional[dict] = None) -> dict:
        if not self._ready:
            return {"success_count": 0, "failure_count": len(tokens), "invalid_tokens": []}
        if not tokens:
            return {"success_count": 0, "failure_count": 0, "invalid_tokens": []}
        from firebase_admin import messaging
        total_success = 0
        total_failure = 0
        invalid_tokens: list[str] = []
        loop = asyncio.get_running_loop()
        for i in range(0, len(tokens), 500):
            batch = tokens[i : i + 500]
            try:
                multicast = messaging.MulticastMessage(
                    notification=messaging.Notification(title=title, body=body),
                    data={str(k): str(v) for k, v in (data or {}).items()},
                    tokens=batch,
                )
                response = await asyncio.get_running_loop().run_in_executor(None, messaging.send_each_for_multicast, multicast)
                total_success += response.success_count
                total_failure += response.failure_count
                for idx, send_resp in enumerate(response.responses):
                    if not send_resp.success:
                        exc = send_resp.exception
                        if exc and hasattr(exc, "code") and exc.code in (
                            "registration-token-not-registered",
                            "invalid-registration-token",
                        ):
                            invalid_tokens.append(batch[idx])
            except Exception as e:
                logger.error(f"send_to_tokens batch failed: {e}")
                total_failure += len(batch)
        return {"success_count": total_success, "failure_count": total_failure, "invalid_tokens": invalid_tokens}

    async def _get_user_tokens(self, user_id: int) -> list[str]:
        if not self.pool:
            return []
        async with self.pool.acquire() as conn:
            rows = await conn.fetch("SELECT token FROM user_fcm_tokens WHERE user_id = $1", user_id)
            return [r["token"] for r in rows]

    async def _delete_invalid_tokens(self, tokens: list[str]) -> None:
        if not self.pool or not tokens:
            return
        async with self.pool.acquire() as conn:
            await conn.execute("DELETE FROM user_fcm_tokens WHERE token = ANY($1)", tokens)

    async def send_to_user(self, user_id: int, title: str, body: str, data: Optional[dict] = None) -> bool:
        tokens = await self._get_user_tokens(user_id)
        if not tokens:
            return False
        result = await self.send_to_tokens(tokens, title, body, data)
        await self._delete_invalid_tokens(result.get("invalid_tokens", []))
        return result["success_count"] > 0

    async def send_to_all_users(self, title: str, body: str, data: Optional[dict] = None) -> dict:
        if not self._ready or not self.pool:
            return {"success_count": 0, "failure_count": 0}
        total_success = 0
        total_failure = 0
        offset = 0
        while True:
            async with self.pool.acquire() as conn:
                rows = await conn.fetch(
                    "SELECT token FROM user_fcm_tokens ORDER BY id LIMIT 500 OFFSET $1", offset
                )
            if not rows:
                break
            tokens = [r["token"] for r in rows]
            result = await self.send_to_tokens(tokens, title, body, data)
            total_success += result["success_count"]
            total_failure += result["failure_count"]
            await self._delete_invalid_tokens(result.get("invalid_tokens", []))
            if len(rows) < 500:
                break
            offset += 500
        return {"success_count": total_success, "failure_count": total_failure}

    async def send_to_users(self, user_ids: list[int], title: str, body: str, data: Optional[dict] = None) -> dict:
        sent = 0
        failed = 0
        for user_id in user_ids:
            ok = await self.send_to_user(user_id, title, body, data)
            if ok:
                sent += 1
            else:
                failed += 1
        return {"success_count": sent, "failure_count": failed}

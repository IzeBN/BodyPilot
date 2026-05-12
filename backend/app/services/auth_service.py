from datetime import datetime, timezone
from fastapi import HTTPException

from app.repositories.auth import AuthRepository
from app.services.auth import (
    hash_password, verify_password, hash_token,
    create_access_token, create_refresh_token, refresh_token_expires_at,
)


class AuthService:
    def __init__(self, repo: AuthRepository) -> None:
        self._repo = repo

    async def register(
        self, email: str, password: str, fullname: str | None,
        ip: str | None = None, user_agent: str | None = None,
    ) -> dict:
        if len(password) < 8:
            raise HTTPException(400, detail="Password must be at least 8 characters")
        if await self._repo.get_user_by_email(email):
            raise HTTPException(409, detail="Email already registered")
        user_id = await self._repo.create_user(email, hash_password(password), fullname)
        return await self._issue_tokens(user_id, ip, user_agent)

    async def login(
        self, email: str, password: str,
        ip: str | None = None, user_agent: str | None = None,
    ) -> dict:
        user = await self._repo.get_user_by_email(email)
        if not user or not verify_password(password, user["password_hash"]):
            raise HTTPException(401, detail="Invalid credentials")
        return await self._issue_tokens(user["id"], ip, user_agent)

    async def refresh(self, refresh_token: str) -> dict:
        token_hash = hash_token(refresh_token)
        session = await self._repo.get_session_by_token_hash(token_hash)
        if not session:
            raise HTTPException(401, detail="Invalid refresh token")
        expires_at = session["expires_at"]
        if expires_at.tzinfo is None:
            expires_at = expires_at.replace(tzinfo=timezone.utc)
        if expires_at < datetime.now(timezone.utc):
            await self._repo.delete_session(token_hash)
            raise HTTPException(401, detail="Refresh token expired")
        return {"access_token": create_access_token(session["user_id"]), "token_type": "bearer"}

    async def logout(self, refresh_token: str) -> None:
        await self._repo.delete_session(hash_token(refresh_token))

    async def get_me(self, user_id: int) -> dict:
        user = await self._repo.get_user_by_id(user_id)
        if not user:
            raise HTTPException(404, detail="User not found")
        return dict(user)

    async def delete_account(self, user_id: int) -> None:
        await self._repo.delete_user(user_id)

    async def update_ai_consent(self, user_id: int, consent: bool) -> None:
        await self._repo.update_ai_consent(user_id, consent)

    async def register_fcm_token(self, user_id: int, token: str, platform: str) -> None:
        if platform not in ("android", "ios"):
            raise HTTPException(400, detail="platform must be 'android' or 'ios'")
        await self._repo.upsert_fcm_token(user_id, token, platform)

    async def _issue_tokens(
        self, user_id: int,
        ip: str | None = None, user_agent: str | None = None,
    ) -> dict:
        access = create_access_token(user_id)
        refresh = create_refresh_token()
        await self._repo.create_session(user_id, hash_token(refresh), refresh_token_expires_at(), ip, user_agent)
        return {"access_token": access, "refresh_token": refresh, "token_type": "bearer"}

"""
Unit tests for AuthService.
All repository calls are mocked — no database required.
"""
import pytest
from datetime import datetime, timezone, timedelta
from unittest.mock import AsyncMock, patch
from fastapi import HTTPException

from app.services.auth_service import AuthService
from app.services.auth import hash_password, verify_password, hash_token


# ─── Helpers ──────────────────────────────────────────────────────────────────

def _future() -> datetime:
    return datetime.now(timezone.utc) + timedelta(days=30)


def _make_user(user_id: int = 1, password: str = "password123") -> dict:
    return {
        "id": user_id,
        "email": "test@example.com",
        "password_hash": hash_password(password),
        "fullname": "Test User",
        "ai_consent": False,
        "telegram_user_id": None,
    }


# ─── register ─────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_register_success(mock_auth_repo):
    mock_auth_repo.get_user_by_email.return_value = None
    mock_auth_repo.create_user.return_value = 1
    service = AuthService(mock_auth_repo)

    result = await service.register("new@example.com", "securepass", "John")

    assert "access_token" in result
    assert "refresh_token" in result
    assert result["token_type"] == "bearer"
    mock_auth_repo.create_user.assert_awaited_once()
    mock_auth_repo.create_session.assert_awaited_once()


@pytest.mark.asyncio
async def test_register_duplicate_email(mock_auth_repo):
    mock_auth_repo.get_user_by_email.return_value = _make_user()
    service = AuthService(mock_auth_repo)

    with pytest.raises(HTTPException) as exc_info:
        await service.register("existing@example.com", "securepass", None)
    assert exc_info.value.status_code == 409


@pytest.mark.asyncio
async def test_register_short_password(mock_auth_repo):
    service = AuthService(mock_auth_repo)

    with pytest.raises(HTTPException) as exc_info:
        await service.register("new@example.com", "short", None)
    assert exc_info.value.status_code == 400
    mock_auth_repo.create_user.assert_not_awaited()


# ─── login ────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_login_success(mock_auth_repo):
    user = _make_user(password="mypassword")
    mock_auth_repo.get_user_by_email.return_value = user
    service = AuthService(mock_auth_repo)

    result = await service.login("test@example.com", "mypassword")

    assert "access_token" in result
    assert "refresh_token" in result
    mock_auth_repo.create_session.assert_awaited_once()


@pytest.mark.asyncio
async def test_login_wrong_password(mock_auth_repo):
    mock_auth_repo.get_user_by_email.return_value = _make_user(password="correct")
    service = AuthService(mock_auth_repo)

    with pytest.raises(HTTPException) as exc_info:
        await service.login("test@example.com", "wrong")
    assert exc_info.value.status_code == 401


@pytest.mark.asyncio
async def test_login_unknown_email(mock_auth_repo):
    mock_auth_repo.get_user_by_email.return_value = None
    service = AuthService(mock_auth_repo)

    with pytest.raises(HTTPException) as exc_info:
        await service.login("nobody@example.com", "anypass")
    assert exc_info.value.status_code == 401


# ─── refresh ──────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_refresh_success(mock_auth_repo):
    raw_token = "sometoken"
    mock_auth_repo.get_session_by_token_hash.return_value = {
        "id": 1, "user_id": 1, "expires_at": _future()
    }
    service = AuthService(mock_auth_repo)

    result = await service.refresh(raw_token)

    assert "access_token" in result
    mock_auth_repo.get_session_by_token_hash.assert_awaited_once_with(hash_token(raw_token))


@pytest.mark.asyncio
async def test_refresh_invalid_token(mock_auth_repo):
    mock_auth_repo.get_session_by_token_hash.return_value = None
    service = AuthService(mock_auth_repo)

    with pytest.raises(HTTPException) as exc_info:
        await service.refresh("bad_token")
    assert exc_info.value.status_code == 401


@pytest.mark.asyncio
async def test_refresh_expired_token(mock_auth_repo):
    expired = datetime.now(timezone.utc) - timedelta(seconds=1)
    mock_auth_repo.get_session_by_token_hash.return_value = {
        "id": 1, "user_id": 1, "expires_at": expired
    }
    service = AuthService(mock_auth_repo)

    with pytest.raises(HTTPException) as exc_info:
        await service.refresh("expired_token")
    assert exc_info.value.status_code == 401
    mock_auth_repo.delete_session.assert_awaited_once()


# ─── logout ───────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_logout(mock_auth_repo):
    service = AuthService(mock_auth_repo)
    await service.logout("token123")
    mock_auth_repo.delete_session.assert_awaited_once_with(hash_token("token123"))


# ─── get_me ───────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_get_me_found(mock_auth_repo):
    mock_auth_repo.get_user_by_id.return_value = {
        "id": 1, "email": "a@b.com", "fullname": "Alice", "telegram_user_id": None, "ai_consent": True
    }
    service = AuthService(mock_auth_repo)

    result = await service.get_me(1)
    assert result["id"] == 1


@pytest.mark.asyncio
async def test_get_me_not_found(mock_auth_repo):
    mock_auth_repo.get_user_by_id.return_value = None
    service = AuthService(mock_auth_repo)

    with pytest.raises(HTTPException) as exc_info:
        await service.get_me(999)
    assert exc_info.value.status_code == 404


# ─── register_fcm_token ───────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_register_fcm_invalid_platform(mock_auth_repo):
    service = AuthService(mock_auth_repo)

    with pytest.raises(HTTPException) as exc_info:
        await service.register_fcm_token(1, "token", "windows")
    assert exc_info.value.status_code == 400


@pytest.mark.asyncio
async def test_register_fcm_valid(mock_auth_repo):
    service = AuthService(mock_auth_repo)
    await service.register_fcm_token(1, "device_token", "ios")
    mock_auth_repo.upsert_fcm_token.assert_awaited_once_with(1, "device_token", "ios")

"""
Integration tests for AuthRepository against a real PostgreSQL database.
Each test runs inside a transaction that is rolled back on teardown.
"""
import pytest
import pytest_asyncio
from datetime import datetime, timezone, timedelta

from app.repositories.auth import AuthRepository
from app.services.auth import hash_password, hash_token


@pytest_asyncio.fixture
async def repo(pool_fixture):
    return AuthRepository(pool_fixture)


# ─── create_user / get_user_by_email ─────────────────────────────────────────

@pytest.mark.asyncio
async def test_create_and_get_user_by_email(repo):
    pw_hash = hash_password("testpass123")
    user_id = await repo.create_user("repo_test@example.com", pw_hash, "Repo Test")
    assert isinstance(user_id, int) and user_id > 0

    user = await repo.get_user_by_email("repo_test@example.com")
    assert user is not None
    assert user["id"] == user_id
    assert user["fullname"] == "Repo Test"


@pytest.mark.asyncio
async def test_get_user_by_email_not_found(repo):
    user = await repo.get_user_by_email("nobody@nonexistent.invalid")
    assert user is None


@pytest.mark.asyncio
async def test_create_user_email_is_lowercased(repo):
    await repo.create_user("UpperCase@Example.COM", hash_password("x1234567"), None)
    user = await repo.get_user_by_email("uppercase@example.com")
    assert user is not None


# ─── get_user_by_id ───────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_get_user_by_id(repo):
    uid = await repo.create_user("byid@example.com", hash_password("pass12345"), "ById User")
    user = await repo.get_user_by_id(uid)
    assert user["id"] == uid


@pytest.mark.asyncio
async def test_get_user_by_id_not_found(repo):
    user = await repo.get_user_by_id(999_999_999)
    assert user is None


# ─── sessions ─────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_create_and_get_session(repo):
    uid = await repo.create_user("session@example.com", hash_password("pass12345"), None)
    raw_token = "my_test_refresh_token_abc"
    token_hash = hash_token(raw_token)
    expires_at = datetime.now(timezone.utc) + timedelta(days=30)

    await repo.create_session(uid, token_hash, expires_at)

    session = await repo.get_session_by_token_hash(token_hash)
    assert session is not None
    assert session["user_id"] == uid


@pytest.mark.asyncio
async def test_delete_session(repo):
    uid = await repo.create_user("delsess@example.com", hash_password("pass12345"), None)
    raw_token = "token_to_delete"
    token_hash = hash_token(raw_token)
    expires_at = datetime.now(timezone.utc) + timedelta(days=30)

    await repo.create_session(uid, token_hash, expires_at)
    await repo.delete_session(token_hash)

    session = await repo.get_session_by_token_hash(token_hash)
    assert session is None


# ─── update_ai_consent ────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_update_ai_consent(repo):
    uid = await repo.create_user("consent@example.com", hash_password("pass12345"), None)
    user_before = await repo.get_user_by_id(uid)
    assert user_before["ai_consent"] is False

    await repo.update_ai_consent(uid, True)
    user_after = await repo.get_user_by_id(uid)
    assert user_after["ai_consent"] is True


# ─── delete_user ──────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_delete_user(repo):
    uid = await repo.create_user("deleteme@example.com", hash_password("pass12345"), None)
    await repo.delete_user(uid)
    user = await repo.get_user_by_id(uid)
    assert user is None


# ─── upsert_fcm_token ────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_upsert_fcm_token(repo):
    uid = await repo.create_user("fcm@example.com", hash_password("pass12345"), None)
    # Should not raise
    await repo.upsert_fcm_token(uid, "device_token_xyz", "android")
    # Idempotent — second call should not raise
    await repo.upsert_fcm_token(uid, "device_token_xyz", "android")

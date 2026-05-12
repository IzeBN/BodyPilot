"""API tests for /api/v1/auth endpoints."""
import pytest
from fastapi import HTTPException


# ─── POST /auth/register ─────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_register_success(client, mock_auth_svc):
    resp = await client.post("/api/v1/auth/register", json={
        "email": "new@example.com",
        "password": "password123",
        "fullname": "Test User",
    })
    assert resp.status_code == 201
    data = resp.json()
    assert "access_token" in data
    assert "refresh_token" in data
    mock_auth_svc.register.assert_awaited_once()


@pytest.mark.asyncio
async def test_register_invalid_email(client):
    resp = await client.post("/api/v1/auth/register", json={
        "email": "not-an-email",
        "password": "password123",
    })
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_register_short_password(client):
    resp = await client.post("/api/v1/auth/register", json={
        "email": "ok@example.com",
        "password": "short",
    })
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_register_duplicate_email(client, mock_auth_svc):
    mock_auth_svc.register.side_effect = HTTPException(409, "Email already registered")
    resp = await client.post("/api/v1/auth/register", json={
        "email": "dup@example.com",
        "password": "password123",
    })
    assert resp.status_code == 409


# ─── POST /auth/login ─────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_login_success(client, mock_auth_svc):
    resp = await client.post("/api/v1/auth/login", json={
        "email": "user@example.com",
        "password": "password123",
    })
    assert resp.status_code == 200
    data = resp.json()
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_login_wrong_credentials(client, mock_auth_svc):
    mock_auth_svc.login.side_effect = HTTPException(401, "Invalid credentials")
    resp = await client.post("/api/v1/auth/login", json={
        "email": "user@example.com",
        "password": "wrongpass",
    })
    assert resp.status_code == 401


# ─── POST /auth/refresh ───────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_refresh_success(client, mock_auth_svc):
    resp = await client.post("/api/v1/auth/refresh", json={"refresh_token": "some_opaque_token"})
    assert resp.status_code == 200
    assert "access_token" in resp.json()


# ─── POST /auth/logout ────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_logout(client, mock_auth_svc):
    resp = await client.post("/api/v1/auth/logout", json={"refresh_token": "some_token"})
    assert resp.status_code == 200
    assert resp.json() == {"ok": True}


# ─── GET /auth/me ─────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_me_returns_user(client, mock_auth_svc):
    resp = await client.get("/api/v1/auth/me")
    assert resp.status_code == 200
    data = resp.json()
    assert data["id"] == 1
    assert data["email"] == "u@test.com"


# ─── DELETE /auth/account ────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_delete_account(client, mock_auth_svc):
    resp = await client.delete("/api/v1/auth/account")
    assert resp.status_code == 200
    assert resp.json() == {"ok": True}
    mock_auth_svc.delete_account.assert_awaited_once_with(1)


# ─── POST /auth/ai-consent ───────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_ai_consent(client, mock_auth_svc):
    resp = await client.post("/api/v1/auth/ai-consent", json={"consent": True})
    assert resp.status_code == 200
    mock_auth_svc.update_ai_consent.assert_awaited_once_with(1, True)

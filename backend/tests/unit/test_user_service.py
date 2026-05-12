"""Unit tests for UserService."""
import pytest
from fastapi import HTTPException
from unittest.mock import AsyncMock, MagicMock

from app.services.user_service import UserService


@pytest.fixture
def service(mock_user_repo, mock_auth_repo, mock_pool):
    svc = UserService(mock_user_repo, mock_auth_repo)
    mock_user_repo.pool = mock_pool
    return svc


# ─── get_full_profile ─────────────────────────────────────────────────────────

async def test_get_full_profile_success(service, mock_user_repo):
    result = await service.get_full_profile(1)
    assert result["user"]["id"] == 1


async def test_get_full_profile_not_found(service, mock_user_repo):
    mock_user_repo.get_full_profile.return_value = {"user": None}
    with pytest.raises(HTTPException) as exc:
        await service.get_full_profile(999)
    assert exc.value.status_code == 404


# ─── update_profile ───────────────────────────────────────────────────────────

async def test_update_profile_empty_skips_repo(service, mock_user_repo):
    await service.update_profile(1, {})
    mock_user_repo.update_profile.assert_not_awaited()


async def test_update_profile_with_fields(service, mock_user_repo):
    await service.update_profile(1, {"fullname": "Alice"})
    mock_user_repo.update_profile.assert_awaited_once_with(1, fullname="Alice")


async def test_update_profile_email(service, mock_user_repo):
    await service.update_profile(1, {"email": "new@example.com"})
    mock_user_repo.update_profile.assert_awaited_once_with(1, email="new@example.com")


# ─── upsert_nutrition_profile ─────────────────────────────────────────────────

async def test_upsert_nutrition_profile(service, mock_user_repo):
    fields = {"weight_kg": 75.0, "height_cm": 180}
    await service.upsert_nutrition_profile(1, fields)
    mock_user_repo.upsert_nutrition_profile.assert_awaited_once_with(1, **fields)


# ─── get_nutrition_profile ────────────────────────────────────────────────────

async def test_get_nutrition_profile_none(service, mock_user_repo):
    mock_user_repo.get_nutrition_profile.return_value = None
    result = await service.get_nutrition_profile(1)
    assert result == {}


async def test_get_nutrition_profile_returns_data(service, mock_user_repo):
    mock_user_repo.get_nutrition_profile.return_value = {"user_id": 1, "weight_kg": 70.0}
    result = await service.get_nutrition_profile(1)
    assert result["weight_kg"] == 70.0


# ─── upsert_training_profile ──────────────────────────────────────────────────

async def test_upsert_training_profile(service, mock_user_repo):
    fields = {"experience": "beginner", "training_type": "strength"}
    await service.upsert_training_profile(1, fields)
    mock_user_repo.upsert_training_profile.assert_awaited_once_with(1, **fields)


# ─── get_training_profile ─────────────────────────────────────────────────────

async def test_get_training_profile_none(service, mock_user_repo):
    mock_user_repo.get_training_profile.return_value = None
    result = await service.get_training_profile(1)
    assert result == {}


async def test_get_training_profile_returns_data(service, mock_user_repo):
    mock_user_repo.get_training_profile.return_value = {"user_id": 1, "experience": "intermediate"}
    result = await service.get_training_profile(1)
    assert result["experience"] == "intermediate"


# ─── add_action ───────────────────────────────────────────────────────────────

async def test_add_action(service, mock_user_repo):
    await service.add_action(1, "opened_app")
    mock_user_repo.add_action.assert_awaited_once_with(1, "opened_app")


# ─── update_ai_consent ────────────────────────────────────────────────────────

async def test_update_ai_consent_true(service, mock_auth_repo):
    await service.update_ai_consent(1, True)
    mock_auth_repo.update_ai_consent.assert_awaited_once_with(1, True)


async def test_update_ai_consent_false(service, mock_auth_repo):
    await service.update_ai_consent(1, False)
    mock_auth_repo.update_ai_consent.assert_awaited_once_with(1, False)


# ─── register_fcm_token ───────────────────────────────────────────────────────

async def test_register_fcm_invalid_platform(service):
    with pytest.raises(HTTPException) as exc:
        await service.register_fcm_token(1, "tok", "desktop")
    assert exc.value.status_code == 400


async def test_register_fcm_android(service, mock_auth_repo):
    await service.register_fcm_token(1, "device_token", "android")
    mock_auth_repo.upsert_fcm_token.assert_awaited_once_with(1, "device_token", "android")


async def test_register_fcm_ios(service, mock_auth_repo):
    await service.register_fcm_token(1, "apple_token", "ios")
    mock_auth_repo.upsert_fcm_token.assert_awaited_once_with(1, "apple_token", "ios")


# ─── clear_training_data ─────────────────────────────────────────────────────

async def test_clear_training_data(service, mock_user_repo, mock_pool, mock_conn):
    """Should execute 3 DELETE statements within a transaction."""
    mock_user_repo.pool = mock_pool

    await service.clear_training_data(1)

    # 3 DELETE calls: exercise_results, user_schedules, user_programs
    assert mock_conn.execute.await_count == 3
    mock_user_repo.add_action.assert_awaited_once()


async def test_clear_training_data_logs_action(service, mock_user_repo, mock_pool):
    mock_user_repo.pool = mock_pool
    await service.clear_training_data(42)
    mock_user_repo.add_action.assert_awaited_once_with(42, "Cleared training data")


# ─── get_weekly_progress ─────────────────────────────────────────────────────

async def test_get_weekly_progress_empty(service, mock_user_repo, mock_pool, mock_conn):
    mock_user_repo.pool = mock_pool
    mock_conn.fetch.return_value = []

    result = await service.get_weekly_progress(1)

    assert "progress" in result
    assert len(result["progress"]) == 7
    for v in result["progress"].values():
        assert v == "none"


async def test_get_weekly_progress_with_data(service, mock_user_repo, mock_pool, mock_conn):
    import datetime
    today = datetime.date.today()
    import calendar
    wd = calendar.weekday(today.year, today.month, today.day)
    monday = today - datetime.timedelta(days=wd)
    tuesday = monday + datetime.timedelta(days=1)

    mock_user_repo.pool = mock_pool
    mock_conn.fetch.return_value = [
        {"scheduled_date": tuesday, "status": "completed"}
    ]

    result = await service.get_weekly_progress(1)
    assert result["progress"]["1"] == "completed"

"""API tests for /api/v1/user endpoints."""
import pytest


@pytest.mark.asyncio
async def test_get_profile(client, mock_user_svc):
    resp = await client.get("/api/v1/user/profile")
    assert resp.status_code == 200
    data = resp.json()
    assert data["user"]["id"] == 1


@pytest.mark.asyncio
async def test_update_profile(client, mock_user_svc):
    resp = await client.patch("/api/v1/user/profile", json={"fullname": "New Name"})
    assert resp.status_code == 200
    mock_user_svc.update_profile.assert_awaited_once_with(1, {"fullname": "New Name"})


@pytest.mark.asyncio
async def test_upsert_nutrition_profile(client, mock_user_svc):
    resp = await client.post("/api/v1/user/nutrition-profile", json={
        "weight_kg": 80.0,
        "goal": "lose_weight",
        "activity_level": 3,
    })
    assert resp.status_code == 200
    assert resp.json() == {"ok": True}


@pytest.mark.asyncio
async def test_upsert_training_profile(client, mock_user_svc):
    resp = await client.post("/api/v1/user/training-profile", json={
        "experience": "beginner",
        "training_days": [0, 2, 4],
    })
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_get_weekly_progress(client, mock_user_svc):
    mock_user_svc.get_weekly_progress.return_value = {
        "user_id": 1, "today_weekday": 0, "progress": {"0": "none"}
    }
    resp = await client.get("/api/v1/user/progress")
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_clear_training(client, mock_user_svc):
    resp = await client.post("/api/v1/user/clear")
    assert resp.status_code == 200
    mock_user_svc.clear_training_data.assert_awaited_once_with(1)


@pytest.mark.asyncio
async def test_ai_consent_true(client, mock_user_svc):
    resp = await client.post("/api/v1/user/ai-consent", json={"consent": True})
    assert resp.status_code == 200
    mock_user_svc.update_ai_consent.assert_awaited_once_with(1, True)

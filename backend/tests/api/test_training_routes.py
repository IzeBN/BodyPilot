"""API tests for /api/v1/training endpoints."""
import pytest
from fastapi import HTTPException


@pytest.mark.asyncio
async def test_get_programs(client):
    resp = await client.get("/api/v1/training/programs")
    assert resp.status_code == 200
    assert resp.json() == []


@pytest.mark.asyncio
async def test_get_programs_filtered(client, mock_training_svc):
    mock_training_svc.get_programs.return_value = [
        {"id": 1, "title": "Fat Loss", "category": "fat_loss"}
    ]
    resp = await client.get("/api/v1/training/programs?category=fat_loss")
    assert resp.status_code == 200
    assert len(resp.json()) == 1


@pytest.mark.asyncio
async def test_get_schedule(client, mock_training_svc):
    resp = await client.get("/api/v1/training/schedule")
    assert resp.status_code == 200
    data = resp.json()
    assert "schedule" in data


@pytest.mark.asyncio
async def test_select_program(client, mock_training_svc):
    resp = await client.post("/api/v1/training/programs/select", json={"program_id": 5})
    assert resp.status_code == 200
    mock_training_svc.select_program.assert_awaited_once_with(1, 5)


@pytest.mark.asyncio
async def test_select_program_not_found(client, mock_training_svc):
    mock_training_svc.select_program.side_effect = HTTPException(404, "Program not found")
    resp = await client.post("/api/v1/training/programs/select", json={"program_id": 999})
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_add_results(client, mock_training_svc):
    resp = await client.post("/api/v1/training/results", json={
        "schedule_id": 1,
        "exercise_id": 10,
        "approaches": [
            {"approach_number": 1, "repetitions": 10, "weight": 50.0},
            {"approach_number": 2, "repetitions": 8, "weight": 55.0},
        ],
        "training_complete": False,
    })
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_add_results_invalid_body(client):
    resp = await client.post("/api/v1/training/results", json={
        "schedule_id": 1,
        "exercise_id": 10,
        # missing approaches
    })
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_generate_program(client, mock_training_svc):
    resp = await client.post("/api/v1/training/programs/generate")
    assert resp.status_code == 200
    data = resp.json()
    assert "task_id" in data


@pytest.mark.asyncio
async def test_get_task_status(client, mock_training_svc):
    resp = await client.get("/api/v1/training/programs/generate/abc/status")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "success"


@pytest.mark.asyncio
async def test_replace_exercises(client, mock_training_svc):
    resp = await client.post("/api/v1/training/schedule/1/replace-exercises", json={
        "replacements": [{"old_exercise_id": 10, "new_exercise_id": 20}]
    })
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_last_week_results(client, mock_training_svc):
    mock_training_svc.get_last_week_results.return_value = []
    resp = await client.get("/api/v1/training/results/last-week")
    assert resp.status_code == 200

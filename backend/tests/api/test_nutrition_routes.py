"""API tests for /api/v1/nutrition endpoints."""
import pytest
from fastapi import HTTPException


@pytest.mark.asyncio
async def test_add_meal_success(client, mock_nutrition_svc):
    resp = await client.post("/api/v1/nutrition/meals", json={
        "log_date": "2025-05-01",
        "meal_type": "breakfast",
        "food_name": "Овсянка",
        "amount_g": 200,
        "calories": 300,
        "protein": 10.0,
        "fat": 5.0,
        "carbs": 50.0,
    })
    assert resp.status_code == 201
    assert resp.json() == {"id": 1}


@pytest.mark.asyncio
async def test_add_meal_invalid_type(client):
    resp = await client.post("/api/v1/nutrition/meals", json={
        "log_date": "2025-05-01",
        "meal_type": "midnight_snack",  # not in Literal
        "amount_g": 100,
        "calories": 100,
    })
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_get_meals(client, mock_nutrition_svc):
    resp = await client.get("/api/v1/nutrition/meals?log_date=2025-05-01")
    assert resp.status_code == 200
    data = resp.json()
    assert "meals" in data
    assert "summary" in data


@pytest.mark.asyncio
async def test_get_meals_missing_date(client):
    resp = await client.get("/api/v1/nutrition/meals")
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_delete_meal(client, mock_nutrition_svc):
    resp = await client.delete("/api/v1/nutrition/meals/5")
    assert resp.status_code == 200
    mock_nutrition_svc.delete_meal.assert_awaited_once_with(5, 1)


@pytest.mark.asyncio
async def test_search_foods(client, mock_nutrition_svc):
    mock_nutrition_svc.search_foods.return_value = [{"id": 1, "name": "Яблоко", "calories": 52}]
    resp = await client.get("/api/v1/nutrition/foods/search?q=яблоко")
    assert resp.status_code == 200
    assert len(resp.json()) == 1


@pytest.mark.asyncio
async def test_food_by_barcode_not_found(client, mock_nutrition_svc):
    mock_nutrition_svc.get_food_by_barcode.side_effect = HTTPException(404, "Food not found")
    resp = await client.get("/api/v1/nutrition/foods/barcode/9999999")
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_upsert_goals(client, mock_nutrition_svc):
    resp = await client.post("/api/v1/nutrition/goals", json={
        "calories": 2000,
        "protein_g": 150,
        "fat_g": 60,
        "carbs_g": 200,
    })
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_get_goals(client, mock_nutrition_svc):
    mock_nutrition_svc.get_goals.return_value = {"calories": 2000, "protein_g": 150}
    resp = await client.get("/api/v1/nutrition/goals")
    assert resp.status_code == 200
    assert resp.json()["calories"] == 2000


@pytest.mark.asyncio
async def test_get_stats(client, mock_nutrition_svc):
    mock_nutrition_svc.get_stats.return_value = [
        {"log_date": "2025-05-01", "total_calories": 1800}
    ]
    resp = await client.get("/api/v1/nutrition/stats?date_from=2025-05-01&date_to=2025-05-07")
    assert resp.status_code == 200
    assert len(resp.json()) == 1


@pytest.mark.asyncio
async def test_get_stats_missing_dates(client):
    resp = await client.get("/api/v1/nutrition/stats")
    assert resp.status_code == 422

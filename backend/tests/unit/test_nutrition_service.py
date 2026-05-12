"""Unit tests for NutritionService."""
import pytest
from datetime import date
from fastapi import HTTPException

from app.services.nutrition_service import NutritionService


@pytest.fixture
def service(mock_nutrition_repo):
    return NutritionService(mock_nutrition_repo)


# ─── add_meal ─────────────────────────────────────────────────────────────────

async def test_add_meal_returns_id(service, mock_nutrition_repo):
    mock_nutrition_repo.add_meal.return_value = 7
    result = await service.add_meal(1, {
        "log_date": date.today(), "meal_type": "breakfast",
        "food_id": None, "food_name": "Овсянка",
        "amount_g": 200, "calories": 300, "protein": 10, "fat": 5, "carbs": 50,
    })
    assert result == {"id": 7}
    mock_nutrition_repo.add_meal.assert_awaited_once()


async def test_add_meal_calls_repo_with_correct_args(service, mock_nutrition_repo):
    today = date.today()
    await service.add_meal(1, {
        "log_date": today, "meal_type": "lunch",
        "food_id": 5, "food_name": None,
        "amount_g": 150, "calories": 250, "protein": 20, "fat": 8, "carbs": 30,
    })
    call_args = mock_nutrition_repo.add_meal.call_args
    # Positional: user_id, log_date, meal_type, food_id, food_name, amount_g, cal, prot, fat, carbs
    assert call_args.args == (1, today, "lunch", 5, None, 150, 250, 20, 8, 30)


# ─── get_meals ────────────────────────────────────────────────────────────────

async def test_get_meals_returns_structure(service, mock_nutrition_repo):
    mock_nutrition_repo.get_meals_by_date.return_value = [
        {"id": 1, "food_name": "Apple", "calories": 52}
    ]
    mock_nutrition_repo.get_daily_summary.return_value = {
        "total_calories": 52, "total_protein": 0.3,
        "total_fat": 0.2, "total_carbs": 14, "meal_count": 1,
    }
    result = await service.get_meals(1, date.today())
    assert len(result["meals"]) == 1
    assert result["summary"]["total_calories"] == 52


async def test_get_meals_empty(service, mock_nutrition_repo):
    result = await service.get_meals(1, date.today())
    assert result["meals"] == []
    assert result["summary"]["meal_count"] == 0


# ─── edit_meal ────────────────────────────────────────────────────────────────

async def test_edit_meal_not_found(service, mock_nutrition_repo):
    mock_nutrition_repo.get_meal_by_id.return_value = None
    with pytest.raises(HTTPException) as exc:
        await service.edit_meal(99, 1, {"calories": 400})
    assert exc.value.status_code == 404


async def test_edit_meal_calls_update(service, mock_nutrition_repo):
    mock_nutrition_repo.get_meal_by_id.return_value = {"id": 1, "user_id": 1}
    await service.edit_meal(1, 1, {"calories": 400})
    mock_nutrition_repo.update_meal.assert_awaited_once_with(1, 1, calories=400)


async def test_edit_meal_empty_fields_skips_update(service, mock_nutrition_repo):
    mock_nutrition_repo.get_meal_by_id.return_value = {"id": 1}
    await service.edit_meal(1, 1, {})
    mock_nutrition_repo.update_meal.assert_not_awaited()


# ─── delete_meal ─────────────────────────────────────────────────────────────

async def test_delete_meal_not_found(service, mock_nutrition_repo):
    mock_nutrition_repo.get_meal_by_id.return_value = None
    with pytest.raises(HTTPException) as exc:
        await service.delete_meal(99, 1)
    assert exc.value.status_code == 404


async def test_delete_meal_success(service, mock_nutrition_repo):
    mock_nutrition_repo.get_meal_by_id.return_value = {"id": 1}
    await service.delete_meal(1, 1)
    mock_nutrition_repo.delete_meal.assert_awaited_once_with(1, 1)


# ─── search_foods ─────────────────────────────────────────────────────────────

async def test_search_foods_empty(service, mock_nutrition_repo):
    result = await service.search_foods("xyz", 10)
    assert result == []


async def test_search_foods_returns_results(service, mock_nutrition_repo):
    mock_nutrition_repo.search_foods.return_value = [
        {"id": 1, "name": "Яблоко", "calories_per_100g": 52}
    ]
    result = await service.search_foods("яблоко", 20)
    assert len(result) == 1
    assert result[0]["name"] == "Яблоко"
    mock_nutrition_repo.search_foods.assert_awaited_once_with("яблоко", 20)


# ─── get_food_by_barcode ─────────────────────────────────────────────────────

async def test_barcode_not_found(service, mock_nutrition_repo):
    mock_nutrition_repo.get_food_by_barcode.return_value = None
    with pytest.raises(HTTPException) as exc:
        await service.get_food_by_barcode("0000000")
    assert exc.value.status_code == 404


async def test_barcode_found(service, mock_nutrition_repo):
    mock_nutrition_repo.get_food_by_barcode.return_value = {"id": 5, "name": "Milk", "calories_per_100g": 60}
    result = await service.get_food_by_barcode("4607095820026")
    assert result["name"] == "Milk"


# ─── upsert_goals ─────────────────────────────────────────────────────────────

async def test_upsert_goals(service, mock_nutrition_repo):
    data = {"calories": 2000, "protein_g": 150, "fat_g": 70, "carbs_g": 250, "water_ml": 2500}
    await service.upsert_goals(1, data)
    mock_nutrition_repo.upsert_nutrition_goals.assert_awaited_once_with(
        1, 2000, 150, 70, 250, 2500
    )


async def test_upsert_goals_minimal(service, mock_nutrition_repo):
    await service.upsert_goals(1, {"calories": 1800, "protein_g": None, "fat_g": None, "carbs_g": None, "water_ml": None})
    mock_nutrition_repo.upsert_nutrition_goals.assert_awaited_once_with(1, 1800, None, None, None, None)


# ─── get_goals ────────────────────────────────────────────────────────────────

async def test_get_goals_none(service, mock_nutrition_repo):
    mock_nutrition_repo.get_nutrition_goals.return_value = None
    result = await service.get_goals(1)
    assert result == {}


async def test_get_goals_returns_data(service, mock_nutrition_repo):
    mock_nutrition_repo.get_nutrition_goals.return_value = {"calories": 2000, "protein_g": 150}
    result = await service.get_goals(1)
    assert result["calories"] == 2000


# ─── get_stats ────────────────────────────────────────────────────────────────

async def test_get_stats_invalid_range(service):
    with pytest.raises(HTTPException) as exc:
        await service.get_stats(1, date(2025, 5, 10), date(2025, 5, 1))
    assert exc.value.status_code == 400


async def test_get_stats_same_date_ok(service, mock_nutrition_repo):
    today = date.today()
    await service.get_stats(1, today, today)
    mock_nutrition_repo.get_stats_range.assert_awaited_once_with(1, today, today)


async def test_get_stats_valid(service, mock_nutrition_repo):
    mock_nutrition_repo.get_stats_range.return_value = [
        {"log_date": date(2025, 5, 1), "total_calories": 1800}
    ]
    result = await service.get_stats(1, date(2025, 5, 1), date(2025, 5, 7))
    assert len(result) == 1
    assert result[0]["total_calories"] == 1800

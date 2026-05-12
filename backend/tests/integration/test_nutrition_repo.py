"""Integration tests for NutritionRepository."""
import pytest
import pytest_asyncio
from datetime import date

from app.repositories.auth import AuthRepository
from app.repositories.nutrition import NutritionRepository
from app.services.auth import hash_password


@pytest_asyncio.fixture
async def repo(pool_fixture):
    return NutritionRepository(pool_fixture)


@pytest_asyncio.fixture
async def user_id(pool_fixture):
    auth = AuthRepository(pool_fixture)
    return await auth.create_user("nutri@example.com", hash_password("pass12345"), None)


# ─── add_meal ─────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_add_and_get_meal(repo, user_id):
    today = date.today()
    meal_id = await repo.add_meal(
        user_id, today, "breakfast", None, "Овсянка", 200, 300, 10, 5, 55
    )
    assert meal_id > 0

    meals = await repo.get_meals_by_date(user_id, today)
    assert any(m["id"] == meal_id for m in meals)


@pytest.mark.asyncio
async def test_get_daily_summary(repo, user_id):
    today = date.today()
    await repo.add_meal(user_id, today, "lunch", None, "Рис", 200, 250, 5, 2, 50)
    await repo.add_meal(user_id, today, "dinner", None, "Курица", 150, 300, 30, 5, 0)

    summary = await repo.get_daily_summary(user_id, today)
    assert summary["meal_count"] >= 2
    assert summary["total_calories"] >= 550


# ─── update_meal ─────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_update_meal(repo, user_id):
    today = date.today()
    meal_id = await repo.add_meal(user_id, today, "snack", None, "Яблоко", 100, 52, 0.3, 0.2, 14)
    await repo.update_meal(meal_id, user_id, calories=60)
    meal = await repo.get_meal_by_id(meal_id, user_id)
    assert float(meal["calories"]) == 60


# ─── delete_meal ─────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_delete_meal(repo, user_id):
    today = date.today()
    meal_id = await repo.add_meal(user_id, today, "snack", None, "Банан", 120, 110, 1, 0.5, 28)
    await repo.delete_meal(meal_id, user_id)
    meal = await repo.get_meal_by_id(meal_id, user_id)
    assert meal is None


# ─── upsert_nutrition_goals ──────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_upsert_goals_creates_entry(repo, user_id):
    await repo.upsert_nutrition_goals(user_id, 2000, 150, 60, 200, 2500)
    goals = await repo.get_nutrition_goals(user_id)
    assert goals is not None
    assert goals["calories"] == 2000


@pytest.mark.asyncio
async def test_upsert_goals_updates_existing(repo, user_id):
    await repo.upsert_nutrition_goals(user_id, 2000, 150, 60, 200, 2500)
    await repo.upsert_nutrition_goals(user_id, 1800, 120, 55, 180, 2000)
    goals = await repo.get_nutrition_goals(user_id)
    assert goals["calories"] == 1800  # Updated, not inserted again


# ─── search_foods ─────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_search_foods_empty(repo):
    results = await repo.search_foods("zzz_nonexistent_food_xyz", 10)
    assert results == []


# ─── get_stats_range ─────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_get_stats_range(repo, user_id):
    today = date.today()
    await repo.add_meal(user_id, today, "breakfast", None, "Тест", 100, 400, 20, 10, 50)
    stats = await repo.get_stats_range(user_id, today, today)
    assert len(stats) == 1
    assert float(stats[0]["total_calories"]) >= 400

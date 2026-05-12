"""
Shared test fixtures.

Unit tests mock repositories with AsyncMock — no DB required.
Integration tests (tests/integration/) use a real PostgreSQL instance.
API tests (tests/api/) use httpx.AsyncClient against the ASGI app.
"""
import pytest
from unittest.mock import AsyncMock, MagicMock


# ─── Helper: asyncpg-like connection context manager ─────────────────────────

def _make_conn():
    """Build an AsyncMock connection with transaction() support."""
    conn = AsyncMock()
    conn.fetchrow.return_value = None
    conn.fetchval.return_value = None
    conn.fetch.return_value = []
    conn.execute.return_value = None

    # conn.transaction() must return an async context manager (not a coroutine)
    txn_cm = MagicMock()
    txn_cm.__aenter__ = AsyncMock(return_value=MagicMock())
    txn_cm.__aexit__ = AsyncMock(return_value=False)
    conn.transaction = MagicMock(return_value=txn_cm)

    return conn


# ─── DB pool mock ─────────────────────────────────────────────────────────────

@pytest.fixture
def mock_conn():
    return _make_conn()


@pytest.fixture
def mock_pool(mock_conn):
    """
    pool.acquire() must be usable as `async with pool.acquire() as conn:`.
    In asyncpg, pool.acquire() returns an object that is *both* awaitable
    and an async context manager — it is NOT an async function itself.
    """
    pool = MagicMock()

    # acquire_cm is the object returned by pool.acquire()
    acquire_cm = MagicMock()
    acquire_cm.__aenter__ = AsyncMock(return_value=mock_conn)
    acquire_cm.__aexit__ = AsyncMock(return_value=False)

    pool.acquire = MagicMock(return_value=acquire_cm)
    return pool


# ─── AUTH mocks ───────────────────────────────────────────────────────────────

@pytest.fixture
def mock_auth_repo():
    repo = AsyncMock()
    repo.get_user_by_email.return_value = None
    repo.get_user_by_id.return_value = None
    repo.create_user.return_value = 1
    repo.create_session.return_value = None
    repo.get_session_by_token_hash.return_value = None
    repo.delete_session.return_value = None
    repo.delete_user.return_value = None
    repo.update_ai_consent.return_value = None
    repo.upsert_fcm_token.return_value = None
    return repo


# ─── USER mocks ───────────────────────────────────────────────────────────────

@pytest.fixture
def mock_user_repo():
    repo = AsyncMock()
    repo.get_full_profile.return_value = {
        "user": {"id": 1, "email": "user@test.com", "fullname": "Test", "ai_consent": False, "telegram_user_id": None},
        "nutrition_profile": None,
        "training_profile": None,
        "subscription": None,
    }
    repo.update_profile.return_value = None
    repo.upsert_nutrition_profile.return_value = None
    repo.upsert_training_profile.return_value = None
    repo.get_nutrition_profile.return_value = None
    repo.get_training_profile.return_value = None
    repo.add_action.return_value = None
    return repo


# ─── TRAINING mocks ───────────────────────────────────────────────────────────

@pytest.fixture
def mock_training_repo():
    repo = AsyncMock()
    repo.get_programs.return_value = []
    repo.get_program_by_id.return_value = None
    repo.get_program_workouts.return_value = []
    repo.get_workout_exercises.return_value = []
    repo.get_programs_for_matching.return_value = []
    repo.assign_program.return_value = 1
    repo.get_user_active_program.return_value = None
    repo.get_user_schedule.return_value = []
    repo.get_schedule_by_id.return_value = None
    repo.update_schedule_status.return_value = None
    repo.update_schedule_date.return_value = None
    repo.upsert_exercise_result.return_value = None
    repo.add_max_weight.return_value = None
    repo.get_schedule_exercises.return_value = []
    repo.get_alternatives.return_value = []
    repo.replace_exercise_in_schedule.return_value = None
    repo.get_last_week_results.return_value = []
    repo.get_exercise_by_id.return_value = None
    repo.create_schedule_entries.return_value = None
    return repo


# ─── NUTRITION mocks ─────────────────────────────────────────────────────────

@pytest.fixture
def mock_nutrition_repo():
    repo = AsyncMock()
    repo.add_meal.return_value = 42
    repo.get_meals_by_date.return_value = []
    repo.get_daily_summary.return_value = {
        "total_calories": 0, "total_protein": 0,
        "total_fat": 0, "total_carbs": 0, "meal_count": 0,
    }
    repo.get_meal_by_id.return_value = None
    repo.update_meal.return_value = None
    repo.delete_meal.return_value = None
    repo.search_foods.return_value = []
    repo.get_food_by_barcode.return_value = None
    repo.upsert_nutrition_goals.return_value = None
    repo.get_nutrition_goals.return_value = None
    repo.get_stats_range.return_value = []
    return repo


# ─── QUIZ mocks ───────────────────────────────────────────────────────────────

@pytest.fixture
def mock_quiz_repo():
    repo = AsyncMock()
    repo.upsert_answer.return_value = None
    repo.get_answers.return_value = []
    repo.get_answer.return_value = None
    return repo


# ─── EQUIPMENT mocks ─────────────────────────────────────────────────────────

@pytest.fixture
def mock_equipment_repo():
    repo = AsyncMock()
    repo.get_all_categories.return_value = []
    repo.get_items_by_category.return_value = []
    repo.get_user_equipment.return_value = []
    repo.replace_user_equipment.return_value = None
    return repo


# ─── SUBSCRIPTION mocks ───────────────────────────────────────────────────────

@pytest.fixture
def mock_subscription_repo():
    repo = AsyncMock()
    repo.get_plans.return_value = []
    repo.get_plan_by_id.return_value = None
    repo.get_active_subscription.return_value = None
    repo.create_subscription.return_value = 1
    repo.cancel_subscription.return_value = None
    repo.add_landing_bid.return_value = None
    return repo


# ─── NOTIFICATIONS mock ───────────────────────────────────────────────────────

@pytest.fixture
def mock_notifications_repo():
    repo = AsyncMock()
    repo.upsert_task.return_value = None
    repo.get_task.return_value = None
    repo.is_admin.return_value = False
    repo.get_history.return_value = []
    repo.save_history.return_value = 1
    repo.get_all_users_for_admin.return_value = []
    repo.get_analytics.return_value = []
    return repo


# ─── CHAT mocks ───────────────────────────────────────────────────────────────

@pytest.fixture
def mock_chat_repo():
    repo = AsyncMock()
    repo.get_history.return_value = []
    repo.delete_history.return_value = None
    repo.delete_history_by_agent.return_value = None
    return repo


# ─── FOOD RECOGNITION helpers ────────────────────────────────────────────────

@pytest.fixture
def fake_items_parsed():
    return [
        {"name": "Гречка", "name_en": "buckwheat", "weight_grams": 200.0},
        {"name": "Яйцо", "name_en": "egg", "weight_grams": 55.0},
    ]


@pytest.fixture
def fake_enriched():
    return [
        {
            "name": "Гречка", "name_en": "buckwheat", "weight_grams": 200.0,
            "calories_per_100g": 343.0, "protein_per_100g": 13.0, "fat_per_100g": 3.4,
            "carbs_per_100g": 71.5, "fiber_per_100g": 2.7, "sugar_per_100g": None,
            "sugar_alcohols_per_100g": None, "saturated_fat_per_100g": None,
            "unsaturated_fat_per_100g": None, "glycemic_index": 54,
            **{k + "_per_100g": None for k in (
                "sodium_mg", "calcium_mg", "iron_mg", "potassium_mg", "magnesium_mg",
                "phosphorus_mg", "zinc_mg", "selenium_mcg", "manganese_mg", "copper_mg",
                "cholesterol_mg", "vitamin_a_mcg", "vitamin_c_mg", "vitamin_d_mcg",
                "vitamin_e_mg", "vitamin_k_mcg", "vitamin_b1_mg", "vitamin_b2_mg",
                "vitamin_b3_mg", "vitamin_b5_mg", "vitamin_b6_mg", "vitamin_b7_mcg",
                "vitamin_b9_mcg", "vitamin_b12_mcg",
            )},
            "source": "local_db", "source_url": None,
        },
        {
            "name": "Яйцо", "name_en": "egg", "weight_grams": 55.0,
            "calories_per_100g": 155.0, "protein_per_100g": 13.0, "fat_per_100g": 11.0,
            "carbs_per_100g": 1.1, "fiber_per_100g": None, "sugar_per_100g": None,
            "sugar_alcohols_per_100g": None, "saturated_fat_per_100g": None,
            "unsaturated_fat_per_100g": None, "glycemic_index": None,
            **{k + "_per_100g": None for k in (
                "sodium_mg", "calcium_mg", "iron_mg", "potassium_mg", "magnesium_mg",
                "phosphorus_mg", "zinc_mg", "selenium_mcg", "manganese_mg", "copper_mg",
                "cholesterol_mg", "vitamin_a_mcg", "vitamin_c_mg", "vitamin_d_mcg",
                "vitamin_e_mg", "vitamin_k_mcg", "vitamin_b1_mg", "vitamin_b2_mg",
                "vitamin_b3_mg", "vitamin_b5_mg", "vitamin_b6_mg", "vitamin_b7_mcg",
                "vitamin_b9_mcg", "vitamin_b12_mcg",
            )},
            "source": "local_db", "source_url": None,
        },
    ]

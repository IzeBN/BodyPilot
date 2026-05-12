"""
API test fixtures.

Uses FastAPI's dependency override mechanism to inject mock services,
so no real DB or external services are needed.
"""
import pytest
import pytest_asyncio
from unittest.mock import AsyncMock, MagicMock
from httpx import AsyncClient, ASGITransport

from app.main import app
from app.dependencies import (
    get_auth_service, get_user_service, get_training_service,
    get_nutrition_service, get_chat_service, get_equipment_service,
    get_quiz_service, get_subscription_service, get_current_user_id,
)
from app.services.auth import create_access_token


# ─── Auth helper ─────────────────────────────────────────────────────────────

def auth_headers(user_id: int = 1) -> dict:
    token = create_access_token(user_id)
    return {"Authorization": f"Bearer {token}"}


# ─── Mock services ────────────────────────────────────────────────────────────

@pytest.fixture
def mock_auth_svc():
    svc = AsyncMock()
    svc.register.return_value = {"access_token": "at", "refresh_token": "rt", "token_type": "bearer"}
    svc.login.return_value = {"access_token": "at", "refresh_token": "rt", "token_type": "bearer"}
    svc.refresh.return_value = {"access_token": "new_at", "token_type": "bearer"}
    svc.get_me.return_value = {"id": 1, "email": "u@test.com", "fullname": "Test", "ai_consent": False, "telegram_user_id": None}
    return svc


@pytest.fixture
def mock_user_svc():
    svc = AsyncMock()
    svc.get_full_profile.return_value = {
        "user": {"id": 1, "email": "u@test.com", "fullname": "Test", "ai_consent": False},
        "nutrition_profile": None,
        "training_profile": None,
        "subscription": None,
    }
    return svc


@pytest.fixture
def mock_training_svc():
    svc = AsyncMock()
    svc.get_programs.return_value = []
    svc.get_schedule.return_value = {"program": None, "schedule": []}
    svc.get_task_status.return_value = {"task_id": "abc", "status": "success"}
    svc.start_adaptive_generation.return_value = {"task_id": "abc", "comment": "Generation started"}
    svc.match_programs.return_value = []
    return svc


@pytest.fixture
def mock_nutrition_svc():
    svc = AsyncMock()
    svc.add_meal.return_value = {"id": 1}
    svc.get_meals.return_value = {"meals": [], "summary": {}}
    svc.get_goals.return_value = {}
    svc.search_foods.return_value = []
    return svc


@pytest.fixture
def mock_quiz_svc():
    svc = AsyncMock()
    svc.get_all_answers.return_value = []
    svc.find_answers.return_value = []
    return svc


@pytest.fixture
def mock_equipment_svc():
    svc = AsyncMock()
    svc.get_catalog.return_value = []
    svc.get_user_equipment.return_value = []
    return svc


@pytest.fixture
def mock_subscription_svc():
    svc = AsyncMock()
    svc.get_plans.return_value = []
    svc.get_active.return_value = None
    svc.create_payment.return_value = {"payment_url": None, "plan_id": 1, "payment_id": None}
    return svc


# ─── HTTP client with overridden deps ────────────────────────────────────────

@pytest_asyncio.fixture
async def client(
    mock_auth_svc, mock_user_svc, mock_training_svc,
    mock_nutrition_svc, mock_quiz_svc, mock_equipment_svc, mock_subscription_svc,
):
    app.dependency_overrides[get_auth_service] = lambda: mock_auth_svc
    app.dependency_overrides[get_user_service] = lambda: mock_user_svc
    app.dependency_overrides[get_training_service] = lambda: mock_training_svc
    app.dependency_overrides[get_nutrition_service] = lambda: mock_nutrition_svc
    app.dependency_overrides[get_quiz_service] = lambda: mock_quiz_svc
    app.dependency_overrides[get_equipment_service] = lambda: mock_equipment_svc
    app.dependency_overrides[get_subscription_service] = lambda: mock_subscription_svc
    # Always return user_id=1 from token validation
    app.dependency_overrides[get_current_user_id] = lambda: 1

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac

    app.dependency_overrides.clear()

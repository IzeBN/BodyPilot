"""Unit tests for SubscriptionService."""
import sys
import pytest
from unittest.mock import MagicMock, AsyncMock, patch
from fastapi import HTTPException

from app.services.subscription_service import SubscriptionService


@pytest.fixture
def service(mock_subscription_repo, mock_user_repo, mock_pool):
    return SubscriptionService(mock_subscription_repo, mock_user_repo, mock_pool)


# ─── get_plans ───────────────────────────────────────────────────────────────

async def test_get_plans_empty(service):
    result = await service.get_plans()
    assert result == []


async def test_get_plans_returns_list(service, mock_subscription_repo):
    mock_subscription_repo.get_plans.return_value = [
        {"id": 1, "name": "Basic", "price_rub": 299, "duration_days": 30, "is_trial": False}
    ]
    result = await service.get_plans()
    assert len(result) == 1
    assert result[0]["name"] == "Basic"


# ─── get_active ───────────────────────────────────────────────────────────────

async def test_get_active_none(service):
    result = await service.get_active(1)
    assert result is None


async def test_get_active_returns_dict(service, mock_subscription_repo):
    mock_subscription_repo.get_active_subscription.return_value = {
        "id": 1, "user_id": 1, "plan_name": "Pro", "status": "active"
    }
    result = await service.get_active(1)
    assert result["plan_name"] == "Pro"


# ─── create_payment: plan not found ──────────────────────────────────────────

async def test_create_payment_plan_not_found(service, mock_subscription_repo):
    """Plan lookup returns None → 404."""
    mock_subscription_repo.get_plan_by_id.return_value = None
    from unittest.mock import MagicMock
    fake_yookassa = MagicMock()
    with patch.dict(sys.modules, {"yookassa": fake_yookassa}):
        with pytest.raises(HTTPException) as exc:
            await service.create_payment(1, 999, None, False)
    assert exc.value.status_code == 404


# ─── create_payment: free plan ───────────────────────────────────────────────

async def test_create_payment_free_plan(service, mock_subscription_repo, mock_conn):
    """Free plan (price_rub=0) activates immediately without payment URL."""
    mock_subscription_repo.get_plan_by_id.return_value = {
        "id": 1, "name": "Free", "price_rub": 0, "is_trial": False, "duration_days": None
    }
    mock_conn.fetchval.return_value = None  # no prior free activation

    # patch yookassa import inside create_payment
    fake_yookassa = MagicMock()
    with patch.dict(sys.modules, {"yookassa": fake_yookassa}):
        result = await service.create_payment(1, 1, None, False)

    assert result["payment_url"] is None
    assert result["plan_id"] == 1
    mock_subscription_repo.create_subscription.assert_awaited_once()


# ─── create_payment: free plan already activated ─────────────────────────────

async def test_create_payment_free_plan_already_used(service, mock_subscription_repo, mock_conn):
    mock_subscription_repo.get_plan_by_id.return_value = {
        "id": 1, "name": "Free", "price_rub": 0, "is_trial": False, "duration_days": None
    }
    mock_conn.fetchval.return_value = 1  # already activated

    fake_yookassa = MagicMock()
    with patch.dict(sys.modules, {"yookassa": fake_yookassa}):
        with pytest.raises(HTTPException) as exc:
            await service.create_payment(1, 1, None, False)
    assert exc.value.status_code == 400


# ─── create_payment: paid plan without email ─────────────────────────────────

async def test_create_payment_paid_no_email(service, mock_subscription_repo, mock_conn):
    """Paid plan without email → 400."""
    mock_subscription_repo.get_plan_by_id.return_value = {
        "id": 2, "name": "Pro", "price_rub": 499, "is_trial": False, "duration_days": 30
    }

    fake_yookassa = MagicMock()
    with patch.dict(sys.modules, {"yookassa": fake_yookassa}):
        with pytest.raises(HTTPException) as exc:
            await service.create_payment(1, 2, None, False)
    assert exc.value.status_code == 400


# ─── create_payment: trial already used ──────────────────────────────────────

async def test_create_payment_trial_already_used(service, mock_subscription_repo, mock_conn):
    mock_subscription_repo.get_plan_by_id.return_value = {
        "id": 3, "name": "Trial", "price_rub": 1, "is_trial": True, "duration_days": 3
    }
    mock_conn.fetchval.return_value = 1  # trial already used

    fake_yookassa = MagicMock()
    with patch.dict(sys.modules, {"yookassa": fake_yookassa}):
        with pytest.raises(HTTPException) as exc:
            await service.create_payment(1, 3, "u@test.com", True)
    assert exc.value.status_code == 400


# ─── cancel ───────────────────────────────────────────────────────────────────

async def test_cancel(service, mock_subscription_repo, mock_user_repo):
    await service.cancel(1)
    mock_subscription_repo.cancel_subscription.assert_awaited_once_with(1)
    mock_user_repo.add_action.assert_awaited_once()


# ─── add_landing_bid ──────────────────────────────────────────────────────────

async def test_landing_bid(service, mock_subscription_repo):
    await service.add_landing_bid("Ivan", "ivan@example.com", "+79001234567")
    mock_subscription_repo.add_landing_bid.assert_awaited_once_with("Ivan", "ivan@example.com", "+79001234567")


async def test_landing_bid_nulls(service, mock_subscription_repo):
    await service.add_landing_bid(None, None, None)
    mock_subscription_repo.add_landing_bid.assert_awaited_once_with(None, None, None)

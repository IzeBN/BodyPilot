from datetime import datetime, timedelta
from fastapi import HTTPException
from asyncpg import Pool

from app.repositories.subscription import SubscriptionRepository
from app.repositories.user import UserRepository


class SubscriptionService:
    def __init__(
        self,
        sub_repo: SubscriptionRepository,
        user_repo: UserRepository,
        pool: Pool,
    ) -> None:
        self._repo = sub_repo
        self._users = user_repo
        self._pool = pool

    async def get_plans(self) -> list[dict]:
        rows = await self._repo.get_plans()
        return [dict(r) for r in rows]

    async def get_active(self, user_id: int) -> dict | None:
        row = await self._repo.get_active_subscription(user_id)
        return dict(row) if row else None

    async def create_payment(
        self, user_id: int, plan_id: int,
        email: str | None, is_trial: bool,
    ) -> dict:
        from app.config import get_settings
        import yookassa

        s = get_settings()
        plan = await self._repo.get_plan_by_id(plan_id)
        if not plan:
            raise HTTPException(404, detail="Plan not found")

        is_free = (plan["price_rub"] or 0) == 0
        is_trial_plan = is_trial or plan["is_trial"]

        if is_trial_plan:
            async with self._pool.acquire() as conn:
                used_trial = await conn.fetchval(
                    """SELECT 1 FROM subscriptions WHERE user_id = $1
                       AND plan_id IN (SELECT id FROM subscription_plans WHERE is_trial = TRUE)""",
                    user_id,
                )
            if used_trial:
                raise HTTPException(400, detail="Trial period already used")

        if is_free:
            async with self._pool.acquire() as conn:
                used_free = await conn.fetchval(
                    "SELECT 1 FROM user_actions WHERE user_id = $1 AND action LIKE 'Activated free%'",
                    user_id,
                )
            if used_free:
                raise HTTPException(400, detail="Free plan already activated")
            end_date = None
            if plan["duration_days"]:
                end_date = datetime.now() + timedelta(days=plan["duration_days"])
            await self._repo.create_subscription(user_id, plan_id, "free", 0, end_date)
            await self._users.add_action(user_id, f"Activated free plan - {plan_id}")
            return {"payment_url": None, "plan_id": plan_id}

        if not email:
            raise HTTPException(400, detail="Email required for paid subscription")

        yookassa.Configuration.account_id = s.yookassa_shop_id
        yookassa.Configuration.secret_key = s.yookassa_secret_key

        amount = "1.00" if is_trial_plan else str(plan["price_rub"])
        payment = yookassa.Payment.create({
            "amount": {"value": amount, "currency": "RUB"},
            "confirmation": {"type": "redirect", "return_url": s.yookassa_return_url},
            "capture": True,
            "description": plan["name"],
            "save_payment_method": True,
            "metadata": {
                "plan_id": str(plan_id),
                "user_id": str(user_id),
                "is_trial": "true" if is_trial_plan else "false",
            },
            "receipt": {
                "customer": {"email": email},
                "items": [{
                    "description": plan["name"],
                    "quantity": "1.00",
                    "amount": {"value": amount, "currency": "RUB"},
                    "vat_code": "1",
                }],
            },
        })

        await self._users.add_action(user_id, f"Payment link generated - {plan_id}")
        return {
            "payment_id": payment.id,
            "payment_url": payment.confirmation.confirmation_url,
            "plan_id": plan_id,
        }

    async def cancel(self, user_id: int) -> None:
        await self._repo.cancel_subscription(user_id)
        await self._users.add_action(user_id, "Cancelled subscription")

    async def add_landing_bid(self, name: str | None, email: str | None, phone: str | None) -> None:
        await self._repo.add_landing_bid(name, email, phone)

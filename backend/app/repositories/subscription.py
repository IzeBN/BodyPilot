import asyncpg
from datetime import datetime
from app.repositories.base import BaseRepository


class SubscriptionRepository(BaseRepository):

    async def get_plans(self) -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            return await conn.fetch(
                "SELECT * FROM subscription_plans ORDER BY price_rub"
            )

    async def get_plan_by_id(self, plan_id: int) -> asyncpg.Record | None:
        async with self.pool.acquire() as conn:
            return await conn.fetchrow(
                "SELECT * FROM subscription_plans WHERE id = $1", plan_id
            )

    async def get_active_subscription(self, user_id: int) -> asyncpg.Record | None:
        async with self.pool.acquire() as conn:
            return await conn.fetchrow(
                """SELECT s.*, p.name plan_name, p.features
                   FROM subscriptions s
                   JOIN subscription_plans p ON p.id = s.plan_id
                   WHERE s.user_id = $1 AND s.status = 'active' AND (s.end_date IS NULL OR s.end_date > NOW())
                   ORDER BY s.end_date DESC LIMIT 1""",
                user_id,
            )

    async def create_subscription(
        self, user_id: int, plan_id: int, payment_type: str,
        cost_rub: float, end_date: datetime | None,
    ) -> int:
        async with self.pool.acquire() as conn:
            await conn.execute(
                "UPDATE subscriptions SET status = 'cancelled' WHERE user_id = $1 AND status = 'active'",
                user_id,
            )
            return await conn.fetchval(
                """INSERT INTO subscriptions (user_id, plan_id, payment_type, cost_rub, end_date)
                   VALUES ($1, $2, $3, $4, $5) RETURNING id""",
                user_id, plan_id, payment_type, cost_rub, end_date,
            )

    async def cancel_subscription(self, user_id: int) -> None:
        async with self.pool.acquire() as conn:
            await conn.execute(
                "UPDATE subscriptions SET status = 'cancelled' WHERE user_id = $1 AND status = 'active'",
                user_id,
            )

    async def save_auto_payment(self, subscription_id: int, payment_token: str, provider: str = "yookassa") -> None:
        async with self.pool.acquire() as conn:
            await conn.execute(
                """INSERT INTO auto_payments (subscription_id, payment_token, provider)
                   VALUES ($1, $2, $3)
                   ON CONFLICT DO NOTHING""",
                subscription_id, payment_token, provider,
            )

    async def add_landing_bid(self, name: str | None, email: str | None, phone: str | None) -> None:
        async with self.pool.acquire() as conn:
            await conn.execute(
                "INSERT INTO landing_bids (name, email, phone) VALUES ($1, $2, $3)",
                name, email, phone,
            )

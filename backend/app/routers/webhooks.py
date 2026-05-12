from fastapi import APIRouter, Request, HTTPException
from datetime import datetime, timedelta
from asyncpg import Pool
from fastapi import Depends
from app.dependencies import get_db
from app.models.common import WebhookStatusResponse

router = APIRouter(prefix="/webhook", tags=["webhooks"])


@router.post(
    "/yookassa",
    response_model=WebhookStatusResponse,
    summary="YooKassa payment webhook",
    description=(
        "Receives payment events from YooKassa. Only 'payment.succeeded' events are processed. "
        "Idempotent — duplicate events are safely ignored via DB deduplication."
    ),
)
async def yookassa_webhook(req: Request, db: Pool = Depends(get_db)):
    try:
        event = await req.json()
    except Exception:
        raise HTTPException(400, "Invalid JSON")

    event_type = event.get("event", "")
    if event_type != "payment.succeeded":
        return WebhookStatusResponse()

    payment = event.get("object", {})
    metadata = payment.get("metadata") or {}
    payment_id = payment.get("id", "")
    method = payment.get("payment_method") or {}

    try:
        cost = float(payment.get("amount", {}).get("value", "0").replace(",", "."))
        plan_id = int(metadata.get("plan_id", 0))
        user_id = int(metadata.get("user_id", 0))
        is_trial = metadata.get("is_trial") == "true"
        payment_token = method.get("id", "")
    except (ValueError, TypeError):
        raise HTTPException(400, "Invalid metadata")

    async with db.acquire() as conn:
        # Idempotency: skip if already processed
        already_done = await conn.fetchval(
            "SELECT 1 FROM processed_webhook_events WHERE event_id = $1",
            payment_id,
        )
        if already_done:
            return WebhookStatusResponse()

        plan = await conn.fetchrow("SELECT * FROM subscription_plans WHERE id = $1", plan_id)
        if not plan:
            return WebhookStatusResponse()

        end_date = None
        if is_trial:
            end_date = datetime.now() + timedelta(days=3)
        elif plan["duration_days"]:
            end_date = datetime.now() + timedelta(days=plan["duration_days"])

        async with conn.transaction():
            await conn.execute(
                "UPDATE subscriptions SET status = 'cancelled' WHERE user_id = $1 AND status = 'active'",
                user_id,
            )
            subscription_id = await conn.fetchval(
                """INSERT INTO subscriptions (user_id, plan_id, payment_type, cost_rub, end_date)
                   VALUES ($1, $2, 'yookassa', $3, $4) RETURNING id""",
                user_id, plan_id, cost, end_date,
            )

            if payment_token:
                await conn.execute(
                    """INSERT INTO auto_payments (subscription_id, payment_token, provider)
                       VALUES ($1, $2, 'yookassa') ON CONFLICT DO NOTHING""",
                    subscription_id, payment_token,
                )

            action = "Activated trial subscription" if is_trial else f"Payment succeeded - {plan['name']} ({cost} RUB)"
            await conn.execute(
                "INSERT INTO user_actions (user_id, action) VALUES ($1, $2)",
                user_id, action,
            )

            await conn.execute(
                "INSERT INTO processed_webhook_events (event_id) VALUES ($1) ON CONFLICT DO NOTHING",
                payment_id,
            )

        tg_id: int | None = await conn.fetchval(
            "SELECT telegram_user_id FROM users WHERE id = $1", user_id
        )

    if tg_id:
        from app.config import get_settings
        import httpx
        s = get_settings()
        if s.telegram_bot_token:
            text = f"<b>Подписка {plan['name']} оформлена</b>\n\n<i>Можете начинать заниматься</i>"
            async with httpx.AsyncClient() as client:
                try:
                    await client.post(
                        f"https://api.telegram.org/bot{s.telegram_bot_token}/sendMessage",
                        json={"chat_id": tg_id, "text": text, "parse_mode": "HTML"},
                        timeout=5,
                    )
                except Exception:
                    pass

    return WebhookStatusResponse()

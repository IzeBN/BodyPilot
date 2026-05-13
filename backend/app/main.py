import asyncio
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from prometheus_fastapi_instrumentator import Instrumentator

logger = logging.getLogger(__name__)

from app.database import get_pool, close_pool
from app.config import get_settings
from app.routers import (
    auth, user, training, nutrition,
    chat, equipment, quiz, subscription,
    admin, webhooks, neural,
)

OPENAPI_TAGS = [
    {"name": "auth",         "description": "Authentication: register, login, token refresh, logout, account deletion"},
    {"name": "user",         "description": "User profiles: basic info, nutrition profile, training profile, weekly progress"},
    {"name": "training",     "description": "Training programs, schedule management, exercise results, program matching"},
    {"name": "nutrition",    "description": "Food diary, meal logging, food database search, barcode lookup, nutrition goals, statistics. Includes AI recognition from text / photo / voice (`/nutrition/recognize/*`)"},
    {"name": "chat",         "description": "Two dedicated AI chat assistants: **Training** (`/chat/training`) and **Nutrition** (`/chat/nutrition`). Each assistant has its own conversation history and a rich system prompt built from the user's active program / logged meals."},
    {"name": "equipment",    "description": "Equipment catalog and user equipment selection"},
    {"name": "quiz",         "description": "Onboarding quiz: questions, answers, consultation requests"},
    {"name": "subscription", "description": "Subscription plans, YooKassa payment creation, landing bids"},
    {"name": "admin",        "description": "Admin-only: push notifications, user management, analytics"},
    {"name": "webhooks",     "description": "External service webhooks (YooKassa payment events)"},
    {"name": "neural",       "description": "Direct neural/AI endpoints: program generation, consultation"},
]


async def _init_assistant_bg(api_key: str, proxy: str | None) -> None:
    try:
        from app.neural.assistant import init_assistant
        await init_assistant(api_key, proxy)
        logger.info("Neural assistant initialized")
    except Exception as e:
        logger.warning("Neural assistant init failed (non-critical): %s", e)


@asynccontextmanager
async def lifespan(app: FastAPI):
    await get_pool()
    s = get_settings()
    if s.effective_openai_key:
        asyncio.create_task(_init_assistant_bg(s.effective_openai_key, s.openai_proxy or None))
    yield
    await close_pool()


app = FastAPI(
    title="KayFit + FitKeep Unified API",
    version="1.0.0",
    description=(
        "Unified backend for the KayFit (nutrition tracking) and FitKeep (training) apps.\n\n"
        "**Authentication:** All protected endpoints require `Authorization: Bearer <access_token>`.\n\n"
        "**Localisation:** Pass `Accept-Language: ru` or `Accept-Language: en` to receive "
        "translated content where available.\n\n"
        "**Token lifecycle:**\n"
        "- Access token: 15 min, JWT\n"
        "- Refresh token: 30 days, opaque (stored hashed in DB)\n"
    ),
    openapi_tags=OPENAPI_TAGS,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

PREFIX = "/api/v1"

app.include_router(auth.router,         prefix=PREFIX)
app.include_router(user.router,         prefix=PREFIX)
app.include_router(training.router,     prefix=PREFIX)
app.include_router(nutrition.router,    prefix=PREFIX)
app.include_router(chat.router,         prefix=PREFIX)
app.include_router(equipment.router,    prefix=PREFIX)
app.include_router(quiz.router,         prefix=PREFIX)
app.include_router(subscription.router, prefix=PREFIX)
app.include_router(admin.router,        prefix=PREFIX)
app.include_router(webhooks.router,     prefix=PREFIX)
app.include_router(neural.router,       prefix=PREFIX)

Instrumentator().instrument(app).expose(app, endpoint="/metrics")


@app.get("/health", tags=["health"], summary="Health check")
async def health():
    """Simple liveness probe — returns 200 OK when the service is running."""
    return {"status": "ok"}

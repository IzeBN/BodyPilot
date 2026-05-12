from fastapi import Depends, HTTPException, Header
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from asyncpg import Pool

from app.config import get_settings
from app.database import get_pool

from app.repositories.auth import AuthRepository
from app.repositories.user import UserRepository
from app.repositories.training import TrainingRepository
from app.repositories.nutrition import NutritionRepository
from app.repositories.chat import ChatRepository
from app.repositories.equipment import EquipmentRepository
from app.repositories.quiz import QuizRepository
from app.repositories.subscription import SubscriptionRepository
from app.repositories.notifications import NotificationsRepository

from app.services.auth_service import AuthService
from app.services.user_service import UserService
from app.services.training_service import TrainingService
from app.services.nutrition_service import NutritionService
from app.services.chat_service import ChatService
from app.services.equipment_service import EquipmentService
from app.services.quiz_service import QuizService
from app.services.subscription_service import SubscriptionService
from app.services.admin_service import AdminService
from app.services.neural_service import NeuralService
from app.services.food_recognition_service import FoodRecognitionService
from app.neural.assistant import get_assistant

_bearer = HTTPBearer()


# ─── DB ───────────────────────────────────────────────────────────────────────

async def get_db() -> Pool:
    return await get_pool()


# ─── AUTH ─────────────────────────────────────────────────────────────────────

async def get_current_user_id(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer),
) -> int:
    s = get_settings()
    try:
        payload = jwt.decode(
            credentials.credentials, s.jwt_secret, algorithms=[s.jwt_algorithm]
        )
        sub = payload.get("sub")
        if sub is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return int(sub)
    except (JWTError, ValueError):
        raise HTTPException(status_code=401, detail="Invalid token")


def get_lang(accept_language: str = Header(default="ru")) -> str:
    lang = accept_language.split(",")[0].split("-")[0].strip().lower()
    return lang if lang in ("ru", "en") else "ru"


# ─── REPOSITORIES ─────────────────────────────────────────────────────────────

def get_auth_repo(db: Pool = Depends(get_db)) -> AuthRepository:
    return AuthRepository(db)


def get_user_repo(db: Pool = Depends(get_db)) -> UserRepository:
    return UserRepository(db)


def get_training_repo(db: Pool = Depends(get_db)) -> TrainingRepository:
    return TrainingRepository(db)


def get_nutrition_repo(db: Pool = Depends(get_db)) -> NutritionRepository:
    return NutritionRepository(db)


def get_chat_repo(db: Pool = Depends(get_db)) -> ChatRepository:
    return ChatRepository(db)


def get_equipment_repo(db: Pool = Depends(get_db)) -> EquipmentRepository:
    return EquipmentRepository(db)


def get_quiz_repo(db: Pool = Depends(get_db)) -> QuizRepository:
    return QuizRepository(db)


def get_subscription_repo(db: Pool = Depends(get_db)) -> SubscriptionRepository:
    return SubscriptionRepository(db)


def get_notifications_repo(db: Pool = Depends(get_db)) -> NotificationsRepository:
    return NotificationsRepository(db)


# ─── SERVICES ─────────────────────────────────────────────────────────────────

def get_auth_service(
    auth_repo: AuthRepository = Depends(get_auth_repo),
) -> AuthService:
    return AuthService(auth_repo)


def get_user_service(
    user_repo: UserRepository = Depends(get_user_repo),
    auth_repo: AuthRepository = Depends(get_auth_repo),
) -> UserService:
    return UserService(user_repo, auth_repo)


def get_training_service(
    training_repo: TrainingRepository = Depends(get_training_repo),
    user_repo: UserRepository = Depends(get_user_repo),
    quiz_repo: QuizRepository = Depends(get_quiz_repo),
    notifications_repo: NotificationsRepository = Depends(get_notifications_repo),
    db: Pool = Depends(get_db),
) -> TrainingService:
    return TrainingService(training_repo, user_repo, quiz_repo, notifications_repo, db)


def get_nutrition_service(
    nutrition_repo: NutritionRepository = Depends(get_nutrition_repo),
) -> NutritionService:
    return NutritionService(nutrition_repo)


def get_chat_service(
    chat_repo: ChatRepository = Depends(get_chat_repo),
    user_repo: UserRepository = Depends(get_user_repo),
    db: Pool = Depends(get_db),
) -> ChatService:
    return ChatService(chat_repo, user_repo, db)


def get_equipment_service(
    equipment_repo: EquipmentRepository = Depends(get_equipment_repo),
    user_repo: UserRepository = Depends(get_user_repo),
) -> EquipmentService:
    return EquipmentService(equipment_repo, user_repo)


def get_quiz_service(
    quiz_repo: QuizRepository = Depends(get_quiz_repo),
    user_repo: UserRepository = Depends(get_user_repo),
    db: Pool = Depends(get_db),
) -> QuizService:
    return QuizService(quiz_repo, user_repo, db)


def get_subscription_service(
    subscription_repo: SubscriptionRepository = Depends(get_subscription_repo),
    user_repo: UserRepository = Depends(get_user_repo),
    db: Pool = Depends(get_db),
) -> SubscriptionService:
    return SubscriptionService(subscription_repo, user_repo, db)


def get_admin_service(
    notifications_repo: NotificationsRepository = Depends(get_notifications_repo),
    chat_repo: ChatRepository = Depends(get_chat_repo),
    db: Pool = Depends(get_db),
) -> AdminService:
    return AdminService(notifications_repo, chat_repo, db)


def get_food_recognition_service(db: Pool = Depends(get_db)) -> FoodRecognitionService:
    return FoodRecognitionService(db)


def get_neural_service() -> NeuralService:
    return NeuralService(get_assistant())


# ─── ADMIN GUARD ──────────────────────────────────────────────────────────────

async def require_admin(
    user_id: int = Depends(get_current_user_id),
    notifications_repo: NotificationsRepository = Depends(get_notifications_repo),
) -> int:
    if not await notifications_repo.is_admin(user_id):
        raise HTTPException(status_code=403, detail="Admin access required")
    return user_id

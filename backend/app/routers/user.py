from fastapi import APIRouter, Depends
from app.dependencies import get_user_service, get_current_user_id
from app.models.user import (
    UpdateProfileRequest, AiConsentRequest,
    NutritionProfileRequest, TrainingProfileRequest,
    NutritionProfileResponse, TrainingProfileResponse,
    FullProfileResponse, WeeklyProgressResponse, WeightLossDateResponse,
    CalculateWeightLossRequest,
)
from app.models.common import OkResponse
from app.services.user_service import UserService

router = APIRouter(prefix="/user", tags=["user"])


@router.get(
    "/profile",
    response_model=FullProfileResponse,
    summary="Get full user profile",
    description=(
        "Returns combined profile: user info, nutrition profile, training profile, "
        "and active subscription. Used by the app on startup to determine onboarding state."
    ),
)
async def get_profile(
    user_id: int = Depends(get_current_user_id),
    service: UserService = Depends(get_user_service),
):
    return await service.get_full_profile(user_id)


@router.patch(
    "/profile",
    response_model=OkResponse,
    summary="Update basic profile",
    description="Partially update fullname and/or email. Only provided fields are changed.",
)
async def update_profile(
    body: UpdateProfileRequest,
    user_id: int = Depends(get_current_user_id),
    service: UserService = Depends(get_user_service),
):
    await service.update_profile(user_id, body.model_dump(exclude_none=True))
    return OkResponse()


@router.post(
    "/ai-consent",
    response_model=OkResponse,
    summary="Update AI consent flag",
    description="Record user's AI data processing consent. Must be true before AI chat features are unlocked.",
)
async def update_ai_consent(
    body: AiConsentRequest,
    user_id: int = Depends(get_current_user_id),
    service: UserService = Depends(get_user_service),
):
    await service.update_ai_consent(user_id, body.consent)
    return OkResponse()


@router.post(
    "/nutrition-profile",
    response_model=OkResponse,
    summary="Save nutrition profile",
    description=(
        "Upsert user's nutrition/health data (weight, height, goal, restrictions). "
        "Used to personalise calorie recommendations and AI diet advice."
    ),
)
async def upsert_nutrition_profile(
    body: NutritionProfileRequest,
    user_id: int = Depends(get_current_user_id),
    service: UserService = Depends(get_user_service),
):
    await service.upsert_nutrition_profile(user_id, body.model_dump(exclude_none=True))
    return OkResponse()


@router.get(
    "/nutrition-profile",
    response_model=NutritionProfileResponse,
    summary="Get nutrition profile",
    description="Returns the stored nutrition/health data for the current user.",
)
async def get_nutrition_profile(
    user_id: int = Depends(get_current_user_id),
    service: UserService = Depends(get_user_service),
):
    return await service.get_nutrition_profile(user_id)


@router.post(
    "/training-profile",
    response_model=OkResponse,
    summary="Save training profile",
    description=(
        "Upsert user's fitness data (experience, preferred training type, injuries, etc.). "
        "Used for training program matching and AI workout personalisation."
    ),
)
async def upsert_training_profile(
    body: TrainingProfileRequest,
    user_id: int = Depends(get_current_user_id),
    service: UserService = Depends(get_user_service),
):
    await service.upsert_training_profile(user_id, body.model_dump(exclude_none=True))
    return OkResponse()


@router.get(
    "/training-profile",
    response_model=TrainingProfileResponse,
    summary="Get training profile",
    description="Returns the stored fitness data for the current user.",
)
async def get_training_profile(
    user_id: int = Depends(get_current_user_id),
    service: UserService = Depends(get_user_service),
):
    return await service.get_training_profile(user_id)


@router.post(
    "/actions/add",
    response_model=OkResponse,
    summary="Log a user action",
    description=(
        "Record a client-side action for analytics. Duplicate actions within 30 seconds are deduplicated. "
        "Used for funnel tracking and admin dashboards."
    ),
)
async def add_action(
    action: str,
    user_id: int = Depends(get_current_user_id),
    service: UserService = Depends(get_user_service),
):
    await service.add_action(user_id, action)
    return OkResponse()


@router.get(
    "/progress",
    response_model=WeeklyProgressResponse,
    summary="Weekly training progress",
    description=(
        "Returns training status for each day of the current calendar week. "
        "Status values: 'completed', 'pending', 'none'."
    ),
)
async def get_weekly_progress(
    user_id: int = Depends(get_current_user_id),
    service: UserService = Depends(get_user_service),
):
    return await service.get_weekly_progress(user_id)


@router.post(
    "/clear",
    response_model=OkResponse,
    summary="Clear training data",
    description=(
        "Deletes all training history: exercise results, schedules, and program assignments. "
        "Used when the user wants to restart from scratch."
    ),
)
async def clear_training(
    user_id: int = Depends(get_current_user_id),
    service: UserService = Depends(get_user_service),
):
    await service.clear_training_data(user_id)
    return OkResponse()


@router.post(
    "/fcm-token",
    response_model=OkResponse,
    summary="Register push notification token",
    description="Register or update a Firebase Cloud Messaging token to enable push notifications.",
)
async def register_fcm_token(
    token: str,
    platform: str,
    user_id: int = Depends(get_current_user_id),
    service: UserService = Depends(get_user_service),
):
    await service.register_fcm_token(user_id, token, platform)
    return OkResponse()

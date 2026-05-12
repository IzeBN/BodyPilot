from fastapi import APIRouter, Depends, UploadFile, File, Form
from datetime import date
from app.dependencies import get_nutrition_service, get_food_recognition_service, get_current_user_id, get_lang
from app.models.nutrition import (
    AddMealRequest, EditMealRequest, NutritionGoalsRequest, RecognizeTextRequest,
    MealResponse, MealListResponse, FoodItemResponse,
    NutritionGoalsResponse, NutritionStatsResponse,
    RecognizeResponse, RecognizeVoiceResponse,
)
from app.models.common import OkResponse
from app.services.nutrition_service import NutritionService
from app.services.food_recognition_service import FoodRecognitionService

router = APIRouter(prefix="/nutrition", tags=["nutrition"])


# ─── Meal diary ───────────────────────────────────────────────────────────────

@router.post(
    "/meals",
    response_model=MealResponse,
    summary="Log a meal",
    description=(
        "Add a food entry to the daily diary. Provide either food_id (from DB) or food_name (custom). "
        "All micronutrient and vitamin fields are optional — pass them when recognised from photo/voice/text "
        "to preserve the full nutritional profile in the diary."
    ),
    status_code=201,
)
async def add_meal(
    body: AddMealRequest,
    user_id: int = Depends(get_current_user_id),
    service: NutritionService = Depends(get_nutrition_service),
):
    return await service.add_meal(user_id, body.model_dump())


@router.get(
    "/meals",
    response_model=MealListResponse,
    summary="Get meals for a day",
    description=(
        "Returns all meal entries for the given date plus a daily summary "
        "(total calories, protein, fat, carbs, meal count)."
    ),
)
async def get_meals(
    log_date: date,
    user_id: int = Depends(get_current_user_id),
    service: NutritionService = Depends(get_nutrition_service),
):
    return await service.get_meals(user_id, log_date)


@router.patch(
    "/meals/{meal_id}",
    response_model=OkResponse,
    summary="Edit a meal entry",
    description="Partially update a meal. Only supplied non-null fields are changed.",
)
async def edit_meal(
    meal_id: int,
    body: EditMealRequest,
    user_id: int = Depends(get_current_user_id),
    service: NutritionService = Depends(get_nutrition_service),
):
    await service.edit_meal(meal_id, user_id, body.model_dump(exclude_none=True))
    return OkResponse()


@router.delete(
    "/meals/{meal_id}",
    response_model=OkResponse,
    summary="Delete a meal entry",
    description="Permanently removes a meal from the diary.",
)
async def delete_meal(
    meal_id: int,
    user_id: int = Depends(get_current_user_id),
    service: NutritionService = Depends(get_nutrition_service),
):
    await service.delete_meal(meal_id, user_id)
    return OkResponse()


# ─── Food database ────────────────────────────────────────────────────────────

@router.get(
    "/foods/search",
    response_model=list[FoodItemResponse],
    summary="Search food database",
    description="Full-text search in the food DB by name (case-insensitive substring match).",
)
async def search_foods(
    q: str,
    limit: int = 20,
    service: NutritionService = Depends(get_nutrition_service),
):
    return await service.search_foods(q, limit)


@router.get(
    "/foods/barcode/{barcode}",
    response_model=FoodItemResponse,
    summary="Look up food by barcode",
    description="Fetch a food item using its EAN/UPC barcode. Used by the in-app barcode scanner.",
)
async def food_by_barcode(
    barcode: str,
    service: NutritionService = Depends(get_nutrition_service),
):
    return await service.get_food_by_barcode(barcode)


# ─── Nutrition goals ──────────────────────────────────────────────────────────

@router.post(
    "/goals",
    response_model=OkResponse,
    summary="Set nutrition goals",
    description=(
        "Upsert daily nutrition targets (calories, macros, water). "
        "Creates a new entry for today or updates today's existing entry."
    ),
)
async def upsert_goals(
    body: NutritionGoalsRequest,
    user_id: int = Depends(get_current_user_id),
    service: NutritionService = Depends(get_nutrition_service),
):
    await service.upsert_goals(user_id, body.model_dump())
    return OkResponse()


@router.get(
    "/goals",
    response_model=NutritionGoalsResponse,
    summary="Get current nutrition goals",
    description="Returns the most recent nutrition targets for the current user.",
)
async def get_goals(
    user_id: int = Depends(get_current_user_id),
    service: NutritionService = Depends(get_nutrition_service),
):
    return await service.get_goals(user_id)


@router.get(
    "/stats",
    response_model=NutritionStatsResponse,
    summary="Nutrition statistics for a date range",
    description=(
        "Returns daily aggregated totals (calories, protein, fat, carbs) "
        "for each day in the requested range. Use for charts and progress tracking."
    ),
)
async def get_stats(
    date_from: date,
    date_to: date,
    user_id: int = Depends(get_current_user_id),
    service: NutritionService = Depends(get_nutrition_service),
):
    return await service.get_stats(user_id, date_from, date_to)


# ─── Food recognition ─────────────────────────────────────────────────────────

@router.post(
    "/recognize/text",
    response_model=RecognizeResponse,
    summary="Recognise meal from text",
    description=(
        "Parse a free-text description of what was eaten. Claude splits the text into individual "
        "food items, then looks up or generates full KBJU + vitamins/minerals per actual portion. "
        "Use the returned items to populate the Add Meal form or log them directly."
    ),
)
async def recognize_text(
    body: RecognizeTextRequest,
    recognition_service: FoodRecognitionService = Depends(get_food_recognition_service),
):
    return await recognition_service.recognize_text(body.text, body.language)


@router.post(
    "/recognize/photo",
    response_model=RecognizeResponse,
    summary="Recognise meal from photo",
    description=(
        "Upload a JPEG/PNG/WEBP image of a meal. Claude Vision identifies each food item and "
        "estimates portion weight, then the service enriches results with full nutrient data. "
        "Pass `language` form field as 'ru' or 'en' to control response language."
    ),
)
async def recognize_photo(
    file: UploadFile = File(..., description="Food photo (JPEG, PNG, or WEBP)"),
    language: str = Form(default="ru", description="Response language: 'ru' or 'en'"),
    recognition_service: FoodRecognitionService = Depends(get_food_recognition_service),
):
    image_data = await file.read()
    return await recognition_service.recognize_photo(image_data, language)


@router.post(
    "/recognize/voice",
    response_model=RecognizeVoiceResponse,
    summary="Recognise meal from voice",
    description=(
        "Upload an audio file (MP3, WAV, M4A, OGG, WebM). OpenAI Whisper transcribes it, "
        "then Claude parses the transcript into food items and enriches with full nutrient data. "
        "The response includes `transcript` so the user can confirm what was heard."
    ),
)
async def recognize_voice(
    file: UploadFile = File(..., description="Audio recording (MP3, WAV, M4A, OGG, WebM)"),
    language: str = Form(default="ru", description="Audio language for transcription: 'ru' or 'en'"),
    recognition_service: FoodRecognitionService = Depends(get_food_recognition_service),
):
    audio_data = await file.read()
    return await recognition_service.recognize_voice(audio_data, file.filename or "audio", language)

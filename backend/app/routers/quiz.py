from fastapi import APIRouter, Depends
from app.dependencies import get_quiz_service, get_current_user_id, get_lang
from app.models.quiz import (
    QuizAnswerRequest, QuizFindRequest, ConsultationRequest,
    QuizQuestionsResponse, QuizAnswersResponse, QuizFindResponse,
)
from app.models.common import OkResponse
from app.services.quiz_service import QuizService

router = APIRouter(prefix="/quiz", tags=["quiz"])

QUIZ_QUESTIONS = {
    "ru": {
        "goal":              {"title": "Какая у тебя цель?",                           "type": "many_buttons", "answers": {1: "Сбросить вес", 2: "Набрать мышечную массу", 3: "Укрепить здоровье", 4: "Держать в тонусе", 5: "Восстановление после травмы", 6: "Развитие выносливости"}},
        "gender":            {"title": "Какой пол?",                                   "type": "one_button",   "answers": {1: "М", 2: "Ж", 3: "Предпочитаю не отвечать"}},
        "challenge":         {"title": "Главный вызов в фитнесе?",                     "type": "many_buttons", "answers": {1: "Поддерживать мотивацию", 2: "Находить время", 3: "Начать", 4: "Преодолеть плато", 5: "Другое"}},
        "experience":        {"title": "Опыт в фитнесе?",                              "type": "one_button",   "answers": {1: "Нет или мало (до 6 мес)", 2: "Немного (0.5–2 года)", 3: "Много (2+ лет)"}},
        "training_days":     {"title": "Сколько дней в неделю тренируешься?",          "type": "many_buttons", "answers": {i: str(i) for i in range(1, 8)}},
        "coach_type":        {"title": "Какой тип коача ближе?",                       "type": "one_button",   "answers": {1: "Строгий", 2: "Партнёр", 3: "И тот, и тот"}},
        "health":            {"title": "Особенности здоровья?",                        "type": "many_buttons", "answers": {1: "Травмы суставов", 2: "Нестабильное психологическое состояние", 3: "Беременность", 4: "Гормональная терапия"}},
        "age":               {"title": "Возраст (полных лет)",                         "type": "text",         "answers": {}},
        "height":            {"title": "Рост (см)",                                    "type": "text",         "answers": {}},
        "weight":            {"title": "Вес (кг)",                                     "type": "text",         "answers": {}},
        "target_weight":     {"title": "Целевой вес (кг)",                             "type": "text",         "answers": {}},
        "activity_level":    {"title": "Уровень физической активности",                "type": "one_button",   "answers": {1: "Сидячий", 2: "Малоактивный", 3: "Умеренный", 4: "Активный", 5: "Очень активный"}},
        "current_fat_pct":   {"title": "Текущий % жира",                              "type": "text",         "answers": {}},
        "desired_fat_pct":   {"title": "Желаемый % жира",                             "type": "text",         "answers": {}},
        "injuries":          {"title": "Травмы / ограничения",                         "type": "text",         "answers": {}},
        "training_duration": {"title": "Предпочтительная длительность тренировки",     "type": "one_button",   "answers": {1: "30 мин", 2: "45 мин", 3: "60 мин", 4: "90 мин"}},
        "training_type":     {"title": "Тип тренировок",                               "type": "one_button",   "answers": {1: "Силовые", 2: "Кардио", 3: "Смешанные"}},
        "dietary_restrictions": {"title": "Ограничения в питании / аллергии",         "type": "text",         "answers": {}},
    },
    "en": {
        "goal":          {"title": "What is your goal?",    "type": "many_buttons", "answers": {1: "Lose weight", 2: "Gain muscle", 3: "Improve health", 4: "Stay toned", 5: "Recovery", 6: "Build endurance"}},
        "gender":        {"title": "What is your gender?",  "type": "one_button",   "answers": {1: "Male", 2: "Female", 3: "Prefer not to say"}},
        "experience":    {"title": "Fitness experience?",   "type": "one_button",   "answers": {1: "Beginner (< 6 months)", 2: "Some (0.5–2 years)", 3: "Experienced (2+ years)"}},
        "training_days": {"title": "Training days per week?", "type": "many_buttons", "answers": {i: str(i) for i in range(1, 8)}},
        "training_type": {"title": "Training type?",         "type": "one_button",   "answers": {1: "Strength", 2: "Cardio", 3: "Mixed"}},
    },
}


@router.get(
    "/questions",
    response_model=QuizQuestionsResponse,
    summary="Get onboarding quiz questions",
    description=(
        "Returns all quiz questions with answer options for the current language. "
        "Questions are returned as a keyed dict — iterate in any order or present selected keys."
    ),
)
async def get_questions(lang: str = Depends(get_lang)):
    return {"lang": lang, "questions": QUIZ_QUESTIONS.get(lang, QUIZ_QUESTIONS["ru"])}


@router.post(
    "/answer",
    response_model=OkResponse,
    summary="Save a quiz answer",
    description=(
        "Upsert a single quiz answer for the current user. "
        "For many_buttons, pass a list of ints. For one_button, pass a single int. "
        "For text questions, pass a string."
    ),
)
async def save_answer(
    body: QuizAnswerRequest,
    user_id: int = Depends(get_current_user_id),
    service: QuizService = Depends(get_quiz_service),
):
    await service.save_answer(user_id, body.question_key, body.answer_type, body.answer)
    return OkResponse()


@router.post(
    "/answers/find",
    response_model=QuizFindResponse,
    summary="Retrieve specific answers",
    description=(
        "Fetch stored answers for specific question keys. "
        "Used to check onboarding completeness (e.g. check 'current_fat_percentage' to see if quiz was done)."
    ),
)
async def find_answers(
    body: QuizFindRequest,
    user_id: int = Depends(get_current_user_id),
    service: QuizService = Depends(get_quiz_service),
):
    return await service.find_answers(user_id, body.keys)


@router.get(
    "/answers",
    response_model=QuizAnswersResponse,
    summary="Get all quiz answers",
    description="Returns all saved quiz answers for the current user, ordered by question creation time.",
)
async def get_all_answers(
    user_id: int = Depends(get_current_user_id),
    service: QuizService = Depends(get_quiz_service),
):
    return await service.get_all_answers(user_id)


@router.post(
    "/consultation",
    response_model=OkResponse,
    summary="Request a trainer consultation",
    description=(
        "Sends a consultation request notification to the trainer team via Telegram. "
        "The user's preferred date and time are included in the notification."
    ),
)
async def request_consultation(
    body: ConsultationRequest,
    user_id: int = Depends(get_current_user_id),
    service: QuizService = Depends(get_quiz_service),
):
    await service.request_consultation(user_id, body.date, body.time)  # type: ignore[arg-type]
    return OkResponse()

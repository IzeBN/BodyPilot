from fastapi import APIRouter, Depends
from app.dependencies import get_training_service, get_current_user_id, get_lang
from app.models.training import (
    AddExerciseResultRequest, ReplaceExercisesRequest,
    SelectProgramRequest, EditScheduleDateRequest,
    ProgramResponse, ProgramDetailResponse, ProgramMatchResponse,
    WorkoutExerciseResponse, UserScheduleResponse, ExerciseDetailResponse,
    GenerateTaskResponse, TaskStatusResponse,
    ExerciseLastWeekResult, AlternativeExerciseResponse,
)
from app.models.user import CalculateWeightLossRequest, WeightLossDateResponse
from app.models.common import OkResponse
from app.services.training_service import TrainingService

router = APIRouter(prefix="/training", tags=["training"])


@router.get(
    "/programs",
    response_model=list[ProgramResponse],
    summary="List training programs",
    description=(
        "Returns all available training programs, optionally filtered by category. "
        "Supports i18n via Accept-Language header (ru/en)."
    ),
)
async def get_programs(
    category: str | None = None,
    lang: str = Depends(get_lang),
    service: TrainingService = Depends(get_training_service),
):
    return await service.get_programs(category, lang)


@router.get(
    "/programs/free",
    response_model=list[WorkoutExerciseResponse],
    summary="List free program workouts",
    description="Returns workouts from programs in the 'free' category (no subscription required).",
)
async def get_free_programs(
    lang: str = Depends(get_lang),
    service: TrainingService = Depends(get_training_service),
):
    return await service.get_free_programs(lang)


@router.post(
    "/programs/match",
    response_model=list[ProgramMatchResponse],
    summary="Match programs to user profile",
    description=(
        "Scores all programs against the user's quiz answers and returns a ranked list. "
        "Use to suggest the best program before the user makes a selection."
    ),
)
async def match_programs(
    user_id: int = Depends(get_current_user_id),
    service: TrainingService = Depends(get_training_service),
):
    return await service.match_programs(user_id)


@router.post(
    "/programs/select",
    response_model=OkResponse,
    summary="Assign a training program",
    description=(
        "Assigns the chosen program to the user and generates a personalised workout schedule "
        "based on their preferred training days from the quiz."
    ),
)
async def select_program(
    body: SelectProgramRequest,
    user_id: int = Depends(get_current_user_id),
    service: TrainingService = Depends(get_training_service),
):
    await service.select_program(user_id, body.program_id)
    return OkResponse()


@router.post(
    "/programs/generate",
    response_model=GenerateTaskResponse,
    summary="Start adaptive program generation",
    description=(
        "Asynchronously runs program matching and schedule generation in the background. "
        "Returns a task_id immediately. Poll `/programs/generate/{task_id}/status` for completion."
    ),
)
async def generate_adaptive_program(
    user_id: int = Depends(get_current_user_id),
    lang: str = Depends(get_lang),
    service: TrainingService = Depends(get_training_service),
):
    return await service.start_adaptive_generation(user_id, lang)


@router.get(
    "/programs/generate/{task_id}/status",
    response_model=TaskStatusResponse,
    summary="Poll program generation status",
    description="Check the status of a background generation task. Status: 'running', 'success', 'error'.",
)
async def get_generation_status(
    task_id: str,
    service: TrainingService = Depends(get_training_service),
):
    return await service.get_task_status(task_id)


@router.get(
    "/programs/{program_id}",
    response_model=ProgramDetailResponse,
    summary="Get program detail",
    description="Returns a program's metadata and its list of workouts.",
)
async def get_program(
    program_id: int,
    lang: str = Depends(get_lang),
    service: TrainingService = Depends(get_training_service),
):
    return await service.get_program_detail(program_id, lang)


@router.get(
    "/programs/{program_id}/workouts/{workout_id}/exercises",
    response_model=list[WorkoutExerciseResponse],
    summary="Get workout exercises",
    description="Returns all exercises in a specific workout, with defaults for sets/reps/weight.",
)
async def get_workout_exercises(
    program_id: int,
    workout_id: int,
    lang: str = Depends(get_lang),
    service: TrainingService = Depends(get_training_service),
):
    return await service.get_workout_exercises(workout_id, lang)


@router.get(
    "/schedule",
    response_model=UserScheduleResponse,
    summary="Get user schedule",
    description=(
        "Returns the user's active program and their full training schedule "
        "(all workout sessions with dates and statuses)."
    ),
)
async def get_schedule(
    user_id: int = Depends(get_current_user_id),
    service: TrainingService = Depends(get_training_service),
):
    return await service.get_schedule(user_id)


@router.get(
    "/schedule/{schedule_id}/exercises",
    response_model=list[WorkoutExerciseResponse],
    summary="Get exercises for a scheduled session",
    description=(
        "Returns exercises for a specific workout session, applying any user-specific "
        "exercise overrides. Includes default and user-customised sets/reps/weight."
    ),
)
async def get_schedule_exercises(
    schedule_id: int,
    lang: str = Depends(get_lang),
    user_id: int = Depends(get_current_user_id),
    service: TrainingService = Depends(get_training_service),
):
    return await service.get_schedule_exercises(schedule_id, user_id, lang)


@router.get(
    "/schedule/{schedule_id}/exercise/{exercise_id}",
    response_model=ExerciseDetailResponse,
    summary="Get exercise detail in session",
    description=(
        "Returns full exercise details for a session: description, video, "
        "approach list with reps/weight, previous results, and next exercise preview."
    ),
)
async def get_exercise_detail(
    schedule_id: int,
    exercise_id: int,
    lang: str = Depends(get_lang),
    user_id: int = Depends(get_current_user_id),
    service: TrainingService = Depends(get_training_service),
):
    return await service.get_exercise_detail(schedule_id, exercise_id, user_id, lang)


@router.patch(
    "/schedule/{schedule_id}/date",
    response_model=OkResponse,
    summary="Reschedule a workout",
    description="Move a scheduled workout to a different date.",
)
async def reschedule(
    schedule_id: int,
    body: EditScheduleDateRequest,
    user_id: int = Depends(get_current_user_id),
    service: TrainingService = Depends(get_training_service),
):
    await service.reschedule(schedule_id, user_id, body.new_date)
    return OkResponse()


@router.post(
    "/results",
    response_model=OkResponse,
    summary="Submit exercise results",
    description=(
        "Save completed sets for an exercise. Set `training_complete=true` on the last exercise "
        "to mark the entire workout session as done."
    ),
)
async def add_results(
    body: AddExerciseResultRequest,
    user_id: int = Depends(get_current_user_id),
    service: TrainingService = Depends(get_training_service),
):
    await service.save_results(
        user_id, body.schedule_id, body.exercise_id,
        body.approaches, body.training_complete,
    )
    return OkResponse()


@router.post(
    "/exercises/max-weight",
    response_model=OkResponse,
    summary="Record personal best weight",
    description="Manually log a max weight for an exercise. Only saved if it exceeds the current record.",
)
async def set_max_weight(
    exercise_id: int,
    weight: float,
    user_id: int = Depends(get_current_user_id),
    service: TrainingService = Depends(get_training_service),
):
    await service.set_max_weight(user_id, exercise_id, weight)
    return OkResponse()


@router.get(
    "/exercises/{exercise_id}/alternatives",
    response_model=list[AlternativeExerciseResponse],
    summary="Get alternative exercises",
    description="Returns exercises that can substitute the given exercise (same muscle group / difficulty).",
)
async def get_alternatives(
    exercise_id: int,
    lang: str = Depends(get_lang),
    user_id: int = Depends(get_current_user_id),
    service: TrainingService = Depends(get_training_service),
):
    return await service.get_alternatives(exercise_id, user_id, lang)


@router.post(
    "/schedule/{schedule_id}/replace-exercises",
    response_model=OkResponse,
    summary="Replace exercises in a session",
    description=(
        "Substitute one or more exercises in a scheduled workout with alternatives. "
        "Overrides are stored per-user and do not affect other users' programs."
    ),
)
async def replace_exercises(
    schedule_id: int,
    body: ReplaceExercisesRequest,
    user_id: int = Depends(get_current_user_id),
    service: TrainingService = Depends(get_training_service),
):
    await service.replace_exercises(schedule_id, user_id, body.replacements)
    return OkResponse()


@router.get(
    "/results/last-week",
    response_model=list[ExerciseLastWeekResult],
    summary="Last week's training results",
    description="Returns aggregated exercise results from the past 7 days: max weight and total reps per exercise.",
)
async def last_week_results(
    user_id: int = Depends(get_current_user_id),
    service: TrainingService = Depends(get_training_service),
):
    return await service.get_last_week_results(user_id)


@router.post(
    "/calculate/weight-loss-date",
    response_model=WeightLossDateResponse,
    summary="Estimate weight-loss target date",
    description=(
        "Calculates an estimated date to reach the target body-fat percentage based on current "
        "metrics, training intensity, and workout frequency from the user's program."
    ),
)
async def calculate_weight_loss_date(
    body: CalculateWeightLossRequest,
    user_id: int = Depends(get_current_user_id),
    service: TrainingService = Depends(get_training_service),
):
    return await service.calculate_weight_loss_date(user_id, body)

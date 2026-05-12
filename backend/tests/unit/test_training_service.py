"""Unit tests for TrainingService."""
import pytest
import datetime
from fastapi import HTTPException
from unittest.mock import AsyncMock, patch

from app.services.training_service import TrainingService
from app.models.training import ReplaceExerciseItem
from app.models.user import CalculateWeightLossRequest


@pytest.fixture
def service(mock_training_repo, mock_user_repo, mock_quiz_repo, mock_notifications_repo, mock_pool):
    return TrainingService(
        mock_training_repo, mock_user_repo,
        mock_quiz_repo, mock_notifications_repo, mock_pool,
    )


# ─── get_programs ─────────────────────────────────────────────────────────────

async def test_get_programs_empty(service, mock_training_repo):
    result = await service.get_programs(None, "ru")
    assert result == []


async def test_get_programs_with_data(service, mock_training_repo):
    mock_training_repo.get_programs.return_value = [
        {"id": 1, "title": "Fat Loss Program", "category": "fat_loss"}
    ]
    result = await service.get_programs("fat_loss", "ru")
    assert len(result) == 1
    mock_training_repo.get_programs.assert_awaited_once_with("fat_loss", "ru")


async def test_get_programs_passes_lang(service, mock_training_repo):
    await service.get_programs(None, "en")
    mock_training_repo.get_programs.assert_awaited_once_with(None, "en")


# ─── get_program_detail ───────────────────────────────────────────────────────

async def test_get_program_detail_not_found(service, mock_training_repo):
    mock_training_repo.get_program_by_id.return_value = None
    with pytest.raises(HTTPException) as exc:
        await service.get_program_detail(999, "ru")
    assert exc.value.status_code == 404


async def test_get_program_detail_success(service, mock_training_repo):
    mock_training_repo.get_program_by_id.return_value = {"id": 1, "name": "Strength"}
    mock_training_repo.get_program_workouts.return_value = [{"id": 10, "name": "Day 1"}]
    result = await service.get_program_detail(1, "ru")
    assert result["program"]["id"] == 1
    assert len(result["workouts"]) == 1


# ─── get_workout_exercises ────────────────────────────────────────────────────

async def test_get_workout_exercises_empty(service, mock_training_repo):
    result = await service.get_workout_exercises(1, "ru")
    assert result == []


async def test_get_workout_exercises_returns_list(service, mock_training_repo):
    mock_training_repo.get_workout_exercises.return_value = [
        {"id": 5, "name": "Squat", "sets": 3}
    ]
    result = await service.get_workout_exercises(1, "ru")
    assert result[0]["name"] == "Squat"


# ─── select_program ───────────────────────────────────────────────────────────

async def test_select_program_not_found(service, mock_training_repo):
    mock_training_repo.get_program_by_id.return_value = None
    with pytest.raises(HTTPException) as exc:
        await service.select_program(1, 999)
    assert exc.value.status_code == 404


async def test_select_program_success(service, mock_training_repo, mock_user_repo):
    mock_training_repo.get_program_by_id.return_value = {"id": 5, "name": "Strength"}
    with patch("app.services.training_service.build_schedule", new=AsyncMock()):
        await service.select_program(1, 5)
    mock_training_repo.assign_program.assert_awaited_once_with(1, 5)
    mock_user_repo.add_action.assert_awaited()


# ─── get_schedule ─────────────────────────────────────────────────────────────

async def test_get_schedule_no_program(service, mock_training_repo, mock_user_repo):
    mock_training_repo.get_user_active_program.return_value = None
    mock_training_repo.get_user_schedule.return_value = []
    result = await service.get_schedule(1)
    assert result["program"] is None
    assert result["schedule"] == []


async def test_get_schedule_with_program(service, mock_training_repo, mock_user_repo):
    mock_training_repo.get_user_active_program.return_value = {"id": 1, "name": "Fat Loss"}
    mock_training_repo.get_user_schedule.return_value = [{"id": 10, "status": "pending"}]
    result = await service.get_schedule(1)
    assert result["program"]["name"] == "Fat Loss"
    assert len(result["schedule"]) == 1


# ─── get_schedule_exercises ──────────────────────────────────────────────────

async def test_get_schedule_exercises_no_access(service, mock_training_repo):
    mock_training_repo.get_schedule_by_id.return_value = None
    with pytest.raises(HTTPException) as exc:
        await service.get_schedule_exercises(999, 1, "ru")
    assert exc.value.status_code == 404


async def test_get_schedule_exercises_success(service, mock_training_repo, mock_user_repo):
    mock_training_repo.get_schedule_by_id.return_value = {"id": 1, "user_id": 1}
    mock_training_repo.get_schedule_exercises.return_value = [{"id": 5, "name": "Bench Press"}]
    result = await service.get_schedule_exercises(1, 1, "ru")
    assert result[0]["name"] == "Bench Press"


# ─── reschedule ───────────────────────────────────────────────────────────────

async def test_reschedule_no_access(service, mock_training_repo):
    mock_training_repo.get_schedule_by_id.return_value = None
    with pytest.raises(HTTPException):
        await service.reschedule(999, 1, datetime.date.today())


async def test_reschedule_success(service, mock_training_repo, mock_user_repo):
    mock_training_repo.get_schedule_by_id.return_value = {"id": 1}
    new_date = datetime.date(2025, 6, 1)
    await service.reschedule(1, 1, new_date)
    mock_training_repo.update_schedule_date.assert_awaited_once_with(1, new_date)
    mock_user_repo.add_action.assert_awaited()


# ─── save_results ─────────────────────────────────────────────────────────────

async def test_save_results_no_access(service, mock_training_repo):
    mock_training_repo.get_schedule_by_id.return_value = None
    with pytest.raises(HTTPException):
        await service.save_results(1, 999, 1, [], False)


async def test_save_results_marks_complete(service, mock_training_repo, mock_user_repo):
    from app.models.training import ApproachResult
    mock_training_repo.get_schedule_by_id.return_value = {"id": 1}
    approaches = [ApproachResult(approach_number=1, repetitions=10, weight=50.0)]
    await service.save_results(1, 1, 5, approaches, training_complete=True)
    mock_training_repo.update_schedule_status.assert_awaited_once_with(1, "completed")
    mock_user_repo.add_action.assert_awaited()


async def test_save_results_not_complete_no_status_update(service, mock_training_repo):
    from app.models.training import ApproachResult
    mock_training_repo.get_schedule_by_id.return_value = {"id": 1}
    approaches = [ApproachResult(approach_number=1, repetitions=8, weight=None)]
    await service.save_results(1, 1, 5, approaches, training_complete=False)
    mock_training_repo.update_schedule_status.assert_not_awaited()


# ─── set_max_weight ───────────────────────────────────────────────────────────

async def test_set_max_weight(service, mock_training_repo):
    await service.set_max_weight(1, 5, 120.0)
    mock_training_repo.add_max_weight.assert_awaited_once_with(1, 5, 120.0)


# ─── get_last_week_results ────────────────────────────────────────────────────

async def test_get_last_week_results_empty(service, mock_training_repo):
    result = await service.get_last_week_results(1)
    assert result == []


async def test_get_last_week_results_with_data(service, mock_training_repo):
    mock_training_repo.get_last_week_results.return_value = [
        {"exercise_id": 1, "max_weight": 100, "total_reps": 30}
    ]
    result = await service.get_last_week_results(1)
    assert result[0]["max_weight"] == 100


# ─── get_alternatives ─────────────────────────────────────────────────────────

async def test_get_alternatives_empty(service, mock_training_repo, mock_user_repo):
    result = await service.get_alternatives(1, 1, "ru")
    assert result == []


async def test_get_alternatives_logs_action(service, mock_training_repo, mock_user_repo):
    mock_training_repo.get_alternatives.return_value = [{"id": 2, "name": "Dumbbell Press"}]
    result = await service.get_alternatives(1, 1, "ru")
    assert len(result) == 1
    mock_user_repo.add_action.assert_awaited()


# ─── replace_exercises ───────────────────────────────────────────────────────

async def test_replace_exercises_no_access(service, mock_training_repo):
    mock_training_repo.get_schedule_by_id.return_value = None
    with pytest.raises(HTTPException) as exc:
        await service.replace_exercises(999, 1, [ReplaceExerciseItem(old_exercise_id=1, new_exercise_id=2)])
    assert exc.value.status_code == 404


async def test_replace_exercises_calls_repo_with_user_id(service, mock_training_repo):
    mock_training_repo.get_schedule_by_id.return_value = {"id": 1, "user_id": 42}
    await service.replace_exercises(1, 42, [ReplaceExerciseItem(old_exercise_id=10, new_exercise_id=20)])
    mock_training_repo.replace_exercise_in_schedule.assert_awaited_once_with(1, 42, 10, 20)


async def test_replace_exercises_multiple(service, mock_training_repo):
    mock_training_repo.get_schedule_by_id.return_value = {"id": 1}
    replacements = [
        ReplaceExerciseItem(old_exercise_id=1, new_exercise_id=2),
        ReplaceExerciseItem(old_exercise_id=3, new_exercise_id=4),
    ]
    await service.replace_exercises(1, 1, replacements)
    assert mock_training_repo.replace_exercise_in_schedule.await_count == 2


# ─── start_adaptive_generation ───────────────────────────────────────────────

async def test_start_adaptive_generation_creates_task(service, mock_notifications_repo):
    result = await service.start_adaptive_generation(1, "ru")
    assert "task_id" in result
    mock_notifications_repo.upsert_task.assert_awaited_once()


# ─── get_task_status ──────────────────────────────────────────────────────────

async def test_get_task_status_not_found(service, mock_notifications_repo):
    mock_notifications_repo.get_task.return_value = None
    with pytest.raises(HTTPException) as exc:
        await service.get_task_status("nonexistent")
    assert exc.value.status_code == 404


async def test_get_task_status_success(service, mock_notifications_repo):
    mock_notifications_repo.get_task.return_value = {"id": "abc", "user_id": 1, "status": "success"}
    result = await service.get_task_status("abc")
    assert result["status"] == "success"
    assert result["task_id"] == "abc"


# ─── _calc_coefficients ───────────────────────────────────────────────────────

def test_calc_coefficients_beginner_young_lean():
    coeffs = TrainingService._calc_coefficients(age=23, fat_pct=10.0, experience=1, weight=75, height=180)
    assert len(coeffs) == 4
    assert coeffs[0] == 1.2   # beginner (exp <= 2)
    assert coeffs[1] == 1.1   # age < 25
    assert coeffs[2] == 1.1   # fat <= 12


def test_calc_coefficients_veteran_obese():
    coeffs = TrainingService._calc_coefficients(age=50, fat_pct=30.0, experience=5, weight=110, height=175)
    assert coeffs[0] == 0.3   # expert (exp > 3)
    assert coeffs[1] == 0.7   # age >= 46
    assert coeffs[2] == 0.75  # fat > 22


def test_calc_coefficients_intermediate_middle_age():
    coeffs = TrainingService._calc_coefficients(age=35, fat_pct=18.0, experience=3, weight=80, height=175)
    assert coeffs[0] == 0.7   # experience == 3
    assert coeffs[1] == 1.0   # 25 <= age < 36
    assert coeffs[2] == 0.9   # 17 < fat <= 22


def test_calc_coefficients_height_in_meters():
    """Height < 10 is treated as meters."""
    coeffs1 = TrainingService._calc_coefficients(30, 15, 2, 70, 1.75)
    coeffs2 = TrainingService._calc_coefficients(30, 15, 2, 70, 175)
    # BMI should be the same regardless of whether height is in m or cm
    assert coeffs1[3] == coeffs2[3]


# ─── calculate_weight_loss_date ──────────────────────────────────────────────

async def test_calculate_weight_loss_date_no_fat_to_burn(service, mock_quiz_repo, mock_pool, mock_conn):
    """If desired_fat_pct > current_fat_pct (gaining muscle scenario), return today."""
    body = CalculateWeightLossRequest(
        age=25, weight=70, height=175,
        current_fat_pct=10, desired_fat_pct=15,
    )
    mock_conn.fetchval.return_value = 45.0
    mock_conn.fetchrow.return_value = None
    mock_quiz_repo.get_answer.return_value = None

    result = await service.calculate_weight_loss_date(1, body)
    assert result["target_weight"] == body.weight
    assert result["date_to_goal"] == datetime.date.today().isoformat()


async def test_calculate_weight_loss_date_fat_to_burn(service, mock_quiz_repo, mock_pool, mock_conn):
    body = CalculateWeightLossRequest(
        age=30, weight=90, height=175,
        current_fat_pct=25, desired_fat_pct=15,
    )
    mock_conn.fetchval.return_value = 45.0
    mock_conn.fetchrow.return_value = {"category": "fat_loss"}
    mock_quiz_repo.get_answer.return_value = None

    result = await service.calculate_weight_loss_date(1, body)
    assert result["target_weight"] < 90
    assert "date_to_goal" in result

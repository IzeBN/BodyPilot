from pydantic import BaseModel, Field
from typing import Optional, Literal
from datetime import date


class ApproachRequest(BaseModel):
    approach_number: int = Field(..., ge=1, description="Approach (set) number, starting from 1")
    repetitions: int = Field(..., ge=0, description="Number of repetitions performed")
    repetition_margin: int = Field(0, ge=0, description="Allowed rep margin (±)")
    weight: Optional[float] = Field(None, ge=0, description="Weight used in kg (null for bodyweight)")


class ApproachResult(BaseModel):
    approach_number: int = Field(..., ge=1, description="Approach (set) number")
    repetitions: int = Field(..., ge=0, description="Repetitions performed")
    weight: Optional[float] = Field(None, ge=0, description="Weight in kg")


class AddExerciseResultRequest(BaseModel):
    schedule_id: int = Field(..., description="ID of the scheduled workout session")
    exercise_id: int = Field(..., description="ID of the exercise being reported")
    approaches: list[ApproachResult] = Field(..., description="All completed sets with results")
    training_complete: bool = Field(
        False,
        description="Set to true when the entire workout is finished to mark schedule entry as completed",
    )


class GetExercisesRequest(BaseModel):
    schedule_id: int = Field(..., description="ID of the scheduled workout session")


class GetAlternativesRequest(BaseModel):
    exercise_id: int = Field(..., description="ID of the exercise to find alternatives for")


class ReplaceExerciseItem(BaseModel):
    old_exercise_id: int = Field(..., description="Exercise to be replaced")
    new_exercise_id: int = Field(..., description="Replacement exercise")


class ReplaceExercisesRequest(BaseModel):
    schedule_id: int = Field(..., description="Workout session to apply replacements in")
    replacements: list[ReplaceExerciseItem] = Field(
        ..., description="List of exercise substitutions. Changes are per-user and do not affect other users."
    )


class AdaptTrainingRequest(BaseModel):
    schedule_id: int = Field(..., description="ID of the workout session to adapt")
    new_duration_min: int = Field(..., ge=10, le=180, description="Desired workout duration in minutes")
    equipment: Optional[list[dict]] = Field(None, description="Available equipment override")


class FindProgramsRequest(BaseModel):
    category: Optional[str] = Field(
        None,
        description="Filter programs by category",
        examples=["fat_loss", "gain", "tone", "free"],
    )
    from_trainer: bool = Field(False, description="Return only trainer-assigned programs")


class SelectProgramRequest(BaseModel):
    program_id: int = Field(..., description="ID of the training program to assign")


class EditScheduleDateRequest(BaseModel):
    schedule_id: int = Field(..., description="ID of the scheduled workout entry")
    new_date: date = Field(..., description="New date for the workout")


# ── Response models ────────────────────────────────────────────────────────────

class ProgramResponse(BaseModel):
    id: int = Field(..., description="Program ID")
    name: str = Field(..., description="Program name")
    description: Optional[str] = Field(None, description="Program description")
    category: Optional[str] = Field(None, description="Category: fat_loss / gain / tone / free")
    difficulty: Optional[str] = Field(None, description="Difficulty level: beginner / intermediate / advanced")
    duration_weeks: Optional[int] = Field(None, description="Program duration in weeks")
    workouts_per_week: Optional[int] = Field(None, description="Number of workouts per week")
    image_url: Optional[str] = Field(None, description="Cover image URL")


class WorkoutSummaryResponse(BaseModel):
    id: int = Field(..., description="Workout ID")
    name: str = Field(..., description="Workout name")
    day_number: Optional[int] = Field(None, description="Day number within the program")
    duration_min: Optional[int] = Field(None, description="Estimated duration in minutes")


class ProgramDetailResponse(BaseModel):
    id: int = Field(..., description="Program ID")
    name: str = Field(..., description="Program name")
    description: Optional[str] = Field(None, description="Program description")
    category: Optional[str] = Field(None, description="Category")
    difficulty: Optional[str] = Field(None, description="Difficulty level")
    duration_weeks: Optional[int] = Field(None, description="Duration in weeks")
    workouts_per_week: Optional[int] = Field(None, description="Workouts per week")
    image_url: Optional[str] = Field(None, description="Cover image URL")
    workouts: list[WorkoutSummaryResponse] = Field(..., description="List of workouts in the program")


class ProgramMatchResponse(BaseModel):
    program: ProgramResponse = Field(..., description="Training program")
    score: float = Field(..., description="Match score (0–100). Higher = better fit for the user.")


class ApproachResponse(BaseModel):
    approach_number: int = Field(..., description="Set number")
    repetitions: int = Field(..., description="Target repetitions")
    repetition_margin: int = Field(..., description="Allowed rep margin (±)")
    weight: Optional[float] = Field(None, description="Target weight in kg (null = bodyweight)")


class WorkoutExerciseResponse(BaseModel):
    exercise_id: int = Field(..., description="Exercise ID")
    name: str = Field(..., description="Exercise name")
    description: Optional[str] = Field(None, description="Exercise description")
    video_url: Optional[str] = Field(None, description="Demonstration video URL")
    muscle_group: Optional[str] = Field(None, description="Primary muscle group")
    order: Optional[int] = Field(None, description="Exercise order within the workout")
    approaches: list[ApproachResponse] = Field(..., description="Planned sets with reps/weight")


class ScheduleEntryResponse(BaseModel):
    id: int = Field(..., description="Schedule entry ID")
    workout_id: int = Field(..., description="Linked workout ID")
    workout_name: str = Field(..., description="Workout name")
    scheduled_date: str = Field(..., description="Planned date (YYYY-MM-DD)")
    status: str = Field(..., description="Status: pending / completed / skipped")


class UserScheduleResponse(BaseModel):
    program_id: Optional[int] = Field(None, description="Active program ID")
    program_name: Optional[str] = Field(None, description="Active program name")
    entries: list[ScheduleEntryResponse] = Field(..., description="All scheduled workout sessions")


class ExerciseDetailResponse(BaseModel):
    exercise_id: int = Field(..., description="Exercise ID")
    name: str = Field(..., description="Exercise name")
    description: Optional[str] = Field(None, description="Detailed description")
    video_url: Optional[str] = Field(None, description="Demonstration video URL")
    muscle_group: Optional[str] = Field(None, description="Primary muscle group worked")
    approaches: list[ApproachResponse] = Field(..., description="Planned sets with reps/weight")
    previous_results: list[ApproachResult] = Field(
        ..., description="Results from the last time this exercise was done"
    )
    next_exercise: Optional[str] = Field(None, description="Name of the next exercise in the session (preview)")


class GenerateTaskResponse(BaseModel):
    task_id: str = Field(..., description="Background task ID — use to poll /programs/generate/{task_id}/status")


class TaskStatusResponse(BaseModel):
    task_id: str = Field(..., description="Background task ID")
    status: str = Field(..., description="Task status: running / success / error")


class ExerciseLastWeekResult(BaseModel):
    exercise_id: int = Field(..., description="Exercise ID")
    exercise_name: str = Field(..., description="Exercise name")
    max_weight_kg: Optional[float] = Field(None, description="Maximum weight lifted this week (kg)")
    total_reps: int = Field(..., description="Total repetitions performed this week")
    sessions_count: int = Field(..., description="Number of sessions the exercise appeared in")


class AlternativeExerciseResponse(BaseModel):
    exercise_id: int = Field(..., description="Alternative exercise ID")
    name: str = Field(..., description="Alternative exercise name")
    description: Optional[str] = Field(None, description="Description")
    muscle_group: Optional[str] = Field(None, description="Primary muscle group")
    difficulty: Optional[str] = Field(None, description="Difficulty level")

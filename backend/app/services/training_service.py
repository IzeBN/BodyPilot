import asyncio
import uuid
import datetime
import math
from fastapi import HTTPException
from asyncpg import Pool

from app.repositories.training import TrainingRepository
from app.repositories.user import UserRepository
from app.repositories.quiz import QuizRepository
from app.repositories.notifications import NotificationsRepository
from app.services.training_matching import match_training_program
from app.services.schedule import build_schedule

INTENSITY_COEFFICIENTS = {"tone": 4.0, "gain": 6.0, "fat_loss": 8.0}
GOAL_INTENSITY_MAP = {
    "lose_weight": "fat_loss", "жиросжигание": "fat_loss",
    "gain_mass": "gain", "набор": "gain",
    "tone": "tone", "тонус": "tone",
}


class TrainingService:
    def __init__(
        self,
        training_repo: TrainingRepository,
        user_repo: UserRepository,
        quiz_repo: QuizRepository,
        notifications_repo: NotificationsRepository,
        pool: Pool,
    ) -> None:
        self._repo = training_repo
        self._users = user_repo
        self._quiz = quiz_repo
        self._notif = notifications_repo
        self._pool = pool

    # ── Programs ──────────────────────────────────────────────────────────────

    async def get_programs(self, category: str | None, lang: str) -> list[dict]:
        rows = await self._repo.get_programs(category, lang)
        return [dict(r) for r in rows]

    async def get_free_programs(self, lang: str) -> list[dict]:
        async with self._pool.acquire() as conn:
            rows = await conn.fetch(
                """SELECT pw.*, COALESCE(tr.value, pw.title) AS display_title
                   FROM program_workouts pw
                   LEFT JOIN translations tr ON tr.entity_type = 'program_workouts'
                       AND tr.entity_id = pw.id AND tr.lang = $1 AND tr.field = 'title'
                   WHERE pw.program_id IN (SELECT id FROM training_programs WHERE category = 'free')
                   ORDER BY pw.position""",
                lang,
            )
        return [dict(r) for r in rows]

    async def get_program_detail(self, program_id: int, lang: str) -> dict:
        program = await self._repo.get_program_by_id(program_id)
        if not program:
            raise HTTPException(404, detail="Program not found")
        workouts = await self._repo.get_program_workouts(program_id, lang)
        return {"program": dict(program), "workouts": [dict(w) for w in workouts]}

    async def get_workout_exercises(self, workout_id: int, lang: str) -> list[dict]:
        rows = await self._repo.get_workout_exercises(workout_id, lang)
        return [dict(r) for r in rows]

    async def match_programs(self, user_id: int) -> list[dict]:
        results = await match_training_program(user_id, self._pool)
        return [{"program_id": r.program_id, "score": r.score} for r in results]

    async def select_program(self, user_id: int, program_id: int) -> None:
        program = await self._repo.get_program_by_id(program_id)
        if not program:
            raise HTTPException(404, detail="Program not found")
        await self._repo.assign_program(user_id, program_id)
        await build_schedule(user_id, program_id, self._pool)
        await self._users.add_action(user_id, "Training program selected")

    async def start_adaptive_generation(self, user_id: int, lang: str) -> dict:
        task_id = str(uuid.uuid4())
        await self._notif.upsert_task(task_id, user_id, "running")

        async def _run():
            try:
                await self._users.add_action(user_id, "Started adaptive program generation")
                matches = await match_training_program(user_id, self._pool)
                if matches:
                    await self._repo.assign_program(user_id, matches[0].program_id, "ai")
                    await build_schedule(user_id, matches[0].program_id, self._pool)
                await self._users.add_action(user_id, "Program adapted")
                await self._notif.upsert_task(task_id, user_id, "success")
            except Exception:
                await self._notif.upsert_task(task_id, user_id, "error")

        asyncio.create_task(_run())
        return {"task_id": task_id, "comment": "Generation started"}

    async def get_task_status(self, task_id: str) -> dict:
        task = await self._notif.get_task(task_id)
        if not task:
            raise HTTPException(404, detail="Task not found")
        return {"task_id": task_id, "status": task["status"]}

    # ── Schedule ──────────────────────────────────────────────────────────────

    async def get_schedule(self, user_id: int) -> dict:
        program = await self._repo.get_user_active_program(user_id)
        rows = await self._repo.get_user_schedule(user_id)
        await self._users.add_action(user_id, "Opened schedule")
        return {
            "program": dict(program) if program else None,
            "schedule": [dict(r) for r in rows],
        }

    async def get_schedule_exercises(self, schedule_id: int, user_id: int, lang: str) -> list[dict]:
        await self._ensure_schedule_access(schedule_id, user_id)
        await self._users.add_action(user_id, f"Opened training exercises - {schedule_id}")
        rows = await self._repo.get_schedule_exercises(schedule_id, user_id, lang)
        return [dict(r) for r in rows]

    async def get_exercise_detail(self, schedule_id: int, exercise_id: int, user_id: int, lang: str) -> dict:
        await self._ensure_schedule_access(schedule_id, user_id)
        await self._users.add_action(user_id, f"Started exercise - {schedule_id} - {exercise_id}")
        exercise = await self._repo.get_exercise_by_id(exercise_id, lang)
        if not exercise:
            raise HTTPException(404, detail="Exercise not found")

        async with self._pool.acquire() as conn:
            approaches = await conn.fetch(
                """SELECT uep.approach_number, uep.repetitions, uep.weight,
                          ed.repetitions default_reps, ed.weight default_weight,
                          ed.repetition_margin
                   FROM workout_exercises we
                   JOIN user_schedules us ON us.workout_id = we.workout_id AND us.id = $1
                   LEFT JOIN exercise_defaults ed
                       ON ed.exercise_id = we.exercise_id AND ed.workout_id = we.workout_id
                   LEFT JOIN user_exercise_params uep
                       ON uep.user_id = $2 AND uep.schedule_id = $1
                       AND uep.exercise_id = we.exercise_id AND uep.approach_number = ed.approach_number
                   WHERE we.exercise_id = $3 AND we.workout_id = us.workout_id
                   ORDER BY ed.approach_number""",
                schedule_id, user_id, exercise_id,
            )
            max_weight = await conn.fetchval(
                """SELECT weight FROM user_max_weights
                   WHERE user_id = $1 AND exercise_id = $2
                   ORDER BY weight DESC LIMIT 1""",
                user_id, exercise_id,
            )
            last_results = await conn.fetch(
                """SELECT approach_number, repetitions, weight, created_at
                   FROM exercise_results
                   WHERE user_id = $1 AND exercise_id = $2
                   ORDER BY created_at DESC LIMIT 10""",
                user_id, exercise_id,
            )
            next_exercise = await conn.fetchrow(
                """SELECT we2.exercise_id, e.title
                   FROM user_schedules us
                   JOIN workout_exercises we ON we.workout_id = us.workout_id
                   JOIN workout_exercises we2
                       ON we2.workout_id = us.workout_id AND we2.id > we.id
                   JOIN exercises e ON e.id = we2.exercise_id
                   WHERE us.id = $1 AND we.exercise_id = $2
                   ORDER BY we2.id LIMIT 1""",
                schedule_id, exercise_id,
            )
            durations = await conn.fetchrow(
                "SELECT repetition_duration, break_duration FROM duration_exercizes WHERE exercise_id = $1",
                exercise_id,
            )

        rep_dur = (durations["repetition_duration"] if durations else None) or 5
        break_dur = (durations["break_duration"] if durations else None) or 30

        return {
            "exercise": {
                "title": exercise["display_title"],
                "description": exercise["display_description"],
                "photo_url": exercise["photo_url"],
                "video_url": exercise["video_url"],
                "muscle_group": exercise["muscle_group"],
                "progression_level": exercise["progression_level"],
            },
            "approaches": [
                {
                    "approach_number": a["approach_number"],
                    "repetitions": a["repetitions"] or a["default_reps"],
                    "repetition_margin": a["repetition_margin"] or 0,
                    "weight_percent": a["weight"] or a["default_weight"],
                    "duration": rep_dur * (a["repetitions"] or a["default_reps"] or 10),
                }
                for a in approaches
            ],
            "break_duration": break_dur,
            "next_exercise_id": next_exercise["exercise_id"] if next_exercise else None,
            "user_max_weight": float(max_weight) if max_weight else None,
            "last_results": [dict(r) for r in last_results],
        }

    async def reschedule(self, schedule_id: int, user_id: int, new_date: datetime.date) -> None:
        await self._ensure_schedule_access(schedule_id, user_id)
        await self._repo.update_schedule_date(schedule_id, new_date)
        await self._users.add_action(user_id, f"Rescheduled training {schedule_id}")

    # ── Results ───────────────────────────────────────────────────────────────

    async def save_results(
        self,
        user_id: int,
        schedule_id: int,
        exercise_id: int,
        approaches: list,
        training_complete: bool,
    ) -> None:
        await self._ensure_schedule_access(schedule_id, user_id)
        for a in approaches:
            await self._repo.upsert_exercise_result(
                user_id, schedule_id, exercise_id,
                a.approach_number, a.repetitions, a.weight, None, True,
            )
            if a.weight:
                await self._repo.add_max_weight(user_id, exercise_id, a.weight)
        if training_complete:
            await self._repo.update_schedule_status(schedule_id, "completed")
            await self._users.add_action(user_id, f"Completed training {schedule_id}")

    async def set_max_weight(self, user_id: int, exercise_id: int, weight: float) -> None:
        await self._repo.add_max_weight(user_id, exercise_id, weight)

    async def get_last_week_results(self, user_id: int) -> list[dict]:
        rows = await self._repo.get_last_week_results(user_id)
        return [dict(r) for r in rows]

    # ── Exercises ─────────────────────────────────────────────────────────────

    async def get_alternatives(self, exercise_id: int, user_id: int, lang: str) -> list[dict]:
        await self._users.add_action(user_id, f"Got alternatives for exercise {exercise_id}")
        rows = await self._repo.get_alternatives(exercise_id, lang)
        return [dict(r) for r in rows]

    async def replace_exercises(self, schedule_id: int, user_id: int, replacements: list) -> None:
        await self._ensure_schedule_access(schedule_id, user_id)
        for item in replacements:
            await self._repo.replace_exercise_in_schedule(
                schedule_id, user_id, item.old_exercise_id, item.new_exercise_id
            )

    # ── Calculations ──────────────────────────────────────────────────────────

    async def calculate_weight_loss_date(self, user_id: int, body) -> dict:
        if body.current_fat_pct <= 0 or body.desired_fat_pct <= 0:
            raise HTTPException(400, "Fat percentage must be > 0")
        if body.weight <= 0 or body.height <= 0:
            raise HTTPException(400, "Weight and height must be > 0")

        training_days_ans = await self._quiz.get_answer(user_id, "training_days")
        if training_days_ans and training_days_ans["answer_type"] == "many_buttons":
            workouts_per_week = len([v for v in training_days_ans["answer"].split("%") if v.isdigit()])
        else:
            workouts_per_week = 3
        workouts_per_week = max(1, workouts_per_week)

        fat_free = body.weight * (1 - body.current_fat_pct / 100)
        target_w = fat_free / (1 - body.desired_fat_pct / 100)
        fat_to_burn = body.weight - target_w

        if fat_to_burn <= 0:
            return {"target_weight": body.weight, "date_to_goal": datetime.date.today().isoformat(), "muscle_gain": None}

        caloric_deficit = fat_to_burn * 7700

        async with self._pool.acquire() as conn:
            avg_duration = float(await conn.fetchval(
                """SELECT COALESCE(AVG(pw.duration_min), 45)
                   FROM user_programs up
                   JOIN program_workouts pw ON pw.program_id = up.program_id
                   WHERE up.user_id = $1""",
                user_id,
            ) or 45)
            avg_duration = max(avg_duration, 30)
            program_row = await conn.fetchrow(
                """SELECT tp.category FROM user_programs up
                   JOIN training_programs tp ON tp.id = up.program_id
                   WHERE up.user_id = $1 ORDER BY up.assigned_at DESC LIMIT 1""",
                user_id,
            )

        intensity = 4.0
        if program_row:
            cat = (program_row["category"] or "").lower()
            for key, mapped in GOAL_INTENSITY_MAP.items():
                if key in cat:
                    intensity = float(INTENSITY_COEFFICIENTS.get(mapped, 4))
                    break

        calories_per_workout = body.weight * intensity * (avg_duration / 60)
        weekly_deficit = calories_per_workout * workouts_per_week + 400 * 7
        if weekly_deficit <= 0:
            weeks = 52.0
        else:
            weeks = max(4.0, min(104.0, caloric_deficit / weekly_deficit))
        date_to_goal = datetime.date.today() + datetime.timedelta(days=int(weeks * 7))

        muscle_gain = None
        goal_ans = await self._quiz.get_answer(user_id, "goal")
        if goal_ans and "lose_weight" not in (goal_ans["answer"] or ""):
            exp_ans = await self._quiz.get_answer(user_id, "experience")
            exp = int(exp_ans["answer"]) if exp_ans and exp_ans["answer"].isdigit() else 2
            coeffs = self._calc_coefficients(body.age, float(body.current_fat_pct), exp, body.weight, body.height)
            muscle_gain = round(math.prod(coeffs), 3)

        return {
            "target_weight": round(body.weight - fat_to_burn, 2),
            "date_to_goal": date_to_goal.isoformat(),
            "muscle_gain": muscle_gain,
        }

    # ── Helpers ───────────────────────────────────────────────────────────────

    async def _ensure_schedule_access(self, schedule_id: int, user_id: int) -> None:
        schedule = await self._repo.get_schedule_by_id(schedule_id, user_id)
        if not schedule:
            raise HTTPException(404, detail="Schedule entry not found")

    @staticmethod
    def _calc_coefficients(age: int, fat_pct: float, experience: int, weight: float, height: float) -> list[float]:
        data = [1.2 if experience <= 2 else 0.7 if experience == 3 else 0.3]
        data.append(1.1 if age < 25 else 1.0 if age < 36 else 0.85 if age < 46 else 0.7)
        data.append(1.1 if fat_pct <= 12 else 1.0 if fat_pct <= 17 else 0.9 if fat_pct <= 22 else 0.75)
        h = height if height < 10 else height / 100
        bmi = weight / (h ** 2)
        data.append(0.85 if bmi < 18.5 else 1.0 if bmi <= 23 else 0.95 if bmi <= 27 else 0.85)
        return data

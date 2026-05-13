import asyncpg
from datetime import date
from app.repositories.base import BaseRepository


class TrainingRepository(BaseRepository):

    async def get_programs(self, category: str | None = None, lang: str = "ru") -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            query = """
                SELECT tp.*, tt.title training_type_title,
                       COALESCE(tr_title.value, tp.title) AS display_title,
                       COALESCE(tr_desc.value, tp.description) AS display_description
                FROM training_programs tp
                LEFT JOIN training_types tt ON tt.id = tp.training_type_id
                LEFT JOIN translations tr_title ON tr_title.entity_type = 'training_programs'
                    AND tr_title.entity_id = tp.id AND tr_title.lang = $1 AND tr_title.field = 'title'
                LEFT JOIN translations tr_desc ON tr_desc.entity_type = 'training_programs'
                    AND tr_desc.entity_id = tp.id AND tr_desc.lang = $1 AND tr_desc.field = 'description'
            """
            params: list = [lang]
            if category:
                query += " WHERE tp.category = $2"
                params.append(category)
            return await conn.fetch(query, *params)

    async def get_program_by_id(self, program_id: int) -> asyncpg.Record | None:
        async with self.pool.acquire() as conn:
            return await conn.fetchrow(
                "SELECT * FROM training_programs WHERE id = $1", program_id
            )

    async def get_program_workouts(self, program_id: int, lang: str = "ru") -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            return await conn.fetch(
                """SELECT pw.*,
                          COALESCE(tr.value, pw.title) AS display_title
                   FROM program_workouts pw
                   LEFT JOIN translations tr ON tr.entity_type = 'program_workouts'
                       AND tr.entity_id = pw.id AND tr.lang = $2 AND tr.field = 'title'
                   WHERE pw.program_id = $1
                   ORDER BY pw.position""",
                program_id, lang,
            )

    async def get_workout_exercises(self, workout_id: int, lang: str = "ru") -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            return await conn.fetch(
                """SELECT we.*, e.title, e.description, e.photo_url, e.video_url,
                          e.muscle_group, e.progression_level,
                          COALESCE(tr_title.value, e.title) AS display_title,
                          COALESCE(tr_desc.value, e.description) AS display_description,
                          json_agg(
                              json_build_object(
                                  'approach_number', ed.approach_number,
                                  'repetitions', ed.repetitions,
                                  'weight', ed.weight,
                                  'repetition_margin', ed.repetition_margin
                              ) ORDER BY ed.approach_number
                          ) FILTER (WHERE ed.id IS NOT NULL) AS defaults
                   FROM workout_exercises we
                   JOIN exercises e ON e.id = we.exercise_id
                   LEFT JOIN exercise_defaults ed ON ed.exercise_id = e.id AND ed.workout_id = $1
                   LEFT JOIN translations tr_title ON tr_title.entity_type = 'exercises'
                       AND tr_title.entity_id = e.id AND tr_title.lang = $2 AND tr_title.field = 'title'
                   LEFT JOIN translations tr_desc ON tr_desc.entity_type = 'exercises'
                       AND tr_desc.entity_id = e.id AND tr_desc.lang = $2 AND tr_desc.field = 'description'
                   WHERE we.workout_id = $1
                   GROUP BY we.id, e.id, tr_title.value, tr_desc.value""",
                workout_id, lang,
            )

    async def get_programs_for_matching(self) -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            return await conn.fetch(
                "SELECT id, sample_type, training_count, gender, experience, intensity, category FROM training_programs"
            )

    async def assign_program(self, user_id: int, program_id: int, assigned_by: str = "system") -> int:
        async with self.pool.acquire() as conn:
            return await conn.fetchval(
                """INSERT INTO user_programs (user_id, program_id, assigned_by)
                   VALUES ($1, $2, $3) RETURNING id""",
                user_id, program_id, assigned_by,
            )

    async def get_user_active_program(self, user_id: int) -> asyncpg.Record | None:
        async with self.pool.acquire() as conn:
            return await conn.fetchrow(
                """SELECT up.*, tp.title, tp.training_count
                   FROM user_programs up
                   JOIN training_programs tp ON tp.id = up.program_id
                   WHERE up.user_id = $1 ORDER BY up.assigned_at DESC LIMIT 1""",
                user_id,
            )

    async def create_schedule_entries(
        self, user_id: int, program_id: int, entries: list[tuple]
    ) -> None:
        async with self.pool.acquire() as conn:
            await conn.executemany(
                """INSERT INTO user_schedules (user_id, program_id, workout_id, scheduled_date)
                   VALUES ($1, $2, $3, $4) ON CONFLICT DO NOTHING""",
                [(user_id, program_id, workout_id, sched_date) for workout_id, sched_date in entries],
            )

    async def get_user_schedule(self, user_id: int) -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            return await conn.fetch(
                """SELECT us.*, pw.title workout_title, pw.duration_min, pw.muscle_group
                   FROM user_schedules us
                   JOIN program_workouts pw ON pw.id = us.workout_id
                   WHERE us.user_id = $1 ORDER BY us.scheduled_date""",
                user_id,
            )

    async def get_schedule_by_id(self, schedule_id: int, user_id: int) -> asyncpg.Record | None:
        async with self.pool.acquire() as conn:
            return await conn.fetchrow(
                "SELECT * FROM user_schedules WHERE id = $1 AND user_id = $2",
                schedule_id, user_id,
            )

    async def update_schedule_status(self, schedule_id: int, status: str) -> None:
        async with self.pool.acquire() as conn:
            await conn.execute(
                "UPDATE user_schedules SET status = $1 WHERE id = $2",
                status, schedule_id,
            )

    async def update_schedule_date(self, schedule_id: int, new_date: date) -> None:
        async with self.pool.acquire() as conn:
            await conn.execute(
                "UPDATE user_schedules SET scheduled_date = $1 WHERE id = $2",
                new_date, schedule_id,
            )

    async def upsert_exercise_result(
        self, user_id: int, schedule_id: int, exercise_id: int,
        approach_number: int, repetitions: int, weight: float | None,
        video_url: str | None, succeeded: bool | None,
    ) -> None:
        async with self.pool.acquire() as conn:
            await conn.execute(
                """INSERT INTO exercise_results
                       (user_id, schedule_id, exercise_id, approach_number, repetitions, weight, video_url, succeeded)
                   VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                   ON CONFLICT (user_id, schedule_id, exercise_id, approach_number)
                   DO UPDATE SET repetitions = EXCLUDED.repetitions, weight = EXCLUDED.weight,
                                 video_url = EXCLUDED.video_url, succeeded = EXCLUDED.succeeded,
                                 created_at = NOW()""",
                user_id, schedule_id, exercise_id, approach_number,
                repetitions, weight, video_url, succeeded,
            )

    async def upsert_exercise_params(
        self, user_id: int, schedule_id: int, exercise_id: int,
        approach_number: int, repetitions: int, weight: float | None,
    ) -> None:
        async with self.pool.acquire() as conn:
            await conn.execute(
                """INSERT INTO user_exercise_params
                       (user_id, schedule_id, exercise_id, approach_number, repetitions, weight)
                   VALUES ($1, $2, $3, $4, $5, $6)
                   ON CONFLICT (user_id, schedule_id, exercise_id, approach_number)
                   DO UPDATE SET repetitions = EXCLUDED.repetitions, weight = EXCLUDED.weight,
                                 updated_at = NOW()""",
                user_id, schedule_id, exercise_id, approach_number, repetitions, weight,
            )

    async def add_max_weight(self, user_id: int, exercise_id: int, weight: float) -> None:
        async with self.pool.acquire() as conn:
            current = await conn.fetchval(
                "SELECT weight FROM user_max_weights WHERE user_id = $1 AND exercise_id = $2 ORDER BY weight DESC LIMIT 1",
                user_id, exercise_id,
            )
            if current is None or weight > current:
                await conn.execute(
                    "INSERT INTO user_max_weights (user_id, exercise_id, weight) VALUES ($1, $2, $3)",
                    user_id, exercise_id, weight,
                )

    async def get_schedule_exercises(self, schedule_id: int, user_id: int, lang: str = "ru") -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            return await conn.fetch(
                """SELECT
                       we.exercise_id AS original_exercise_id,
                       COALESCE(ueo.new_exercise_id, we.exercise_id) AS exercise_id,
                       e.title, e.description, e.photo_url, e.video_url,
                       e.muscle_group, e.progression_level,
                       COALESCE(tr_title.value, e.title) AS display_title,
                       uep.repetitions user_reps, uep.weight user_weight, uep.approach_number,
                       ed.repetitions default_reps, ed.weight default_weight,
                       ed.repetition_margin, er.succeeded, er.weight result_weight,
                       (ueo.new_exercise_id IS NOT NULL) AS is_overridden
                   FROM user_schedules us
                   JOIN workout_exercises we ON we.workout_id = us.workout_id
                   LEFT JOIN user_exercise_overrides ueo
                       ON ueo.user_id = $2 AND ueo.schedule_id = $1
                       AND ueo.old_exercise_id = we.exercise_id
                   JOIN exercises e ON e.id = COALESCE(ueo.new_exercise_id, we.exercise_id)
                   LEFT JOIN exercise_defaults ed
                       ON ed.exercise_id = we.exercise_id AND ed.workout_id = us.workout_id
                   LEFT JOIN user_exercise_params uep ON uep.user_id = $2 AND uep.schedule_id = $1
                       AND uep.exercise_id = COALESCE(ueo.new_exercise_id, we.exercise_id)
                       AND uep.approach_number = ed.approach_number
                   LEFT JOIN exercise_results er ON er.user_id = $2 AND er.schedule_id = $1
                       AND er.exercise_id = COALESCE(ueo.new_exercise_id, we.exercise_id)
                       AND er.approach_number = ed.approach_number
                   LEFT JOIN translations tr_title ON tr_title.entity_type = 'exercises'
                       AND tr_title.entity_id = COALESCE(ueo.new_exercise_id, we.exercise_id)
                       AND tr_title.lang = $3 AND tr_title.field = 'title'
                   WHERE us.id = $1 AND us.user_id = $2""",
                schedule_id, user_id, lang,
            )

    async def get_alternatives(self, exercise_id: int, lang: str = "ru") -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            return await conn.fetch(
                """SELECT e.id, e.title, e.photo_url, e.video_url, e.muscle_group,
                          COALESCE(tr.value, e.title) AS display_title
                   FROM alternative_exercises ae
                   JOIN exercises e ON e.id = ae.alternative_id
                   LEFT JOIN translations tr ON tr.entity_type = 'exercises'
                       AND tr.entity_id = e.id AND tr.lang = $2 AND tr.field = 'title'
                   WHERE ae.exercise_id = $1""",
                exercise_id, lang,
            )

    async def replace_exercise_in_schedule(
        self, schedule_id: int, user_id: int, old_exercise_id: int, new_exercise_id: int
    ) -> None:
        """
        Store a per-user exercise override for a schedule entry.
        Never mutates shared workout_exercises — each user's overrides are isolated.
        """
        async with self.pool.acquire() as conn:
            await conn.execute(
                """INSERT INTO user_exercise_overrides
                       (user_id, schedule_id, old_exercise_id, new_exercise_id)
                   VALUES ($1, $2, $3, $4)
                   ON CONFLICT (user_id, schedule_id, old_exercise_id)
                   DO UPDATE SET new_exercise_id = EXCLUDED.new_exercise_id""",
                user_id, schedule_id, old_exercise_id, new_exercise_id,
            )

    async def get_last_week_results(self, user_id: int) -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            return await conn.fetch(
                """SELECT er.exercise_id, e.title, MAX(er.weight) max_weight,
                          SUM(er.repetitions) total_reps,
                          COUNT(DISTINCT er.schedule_id) sessions_count
                   FROM exercise_results er
                   JOIN exercises e ON e.id = er.exercise_id
                   WHERE er.user_id = $1 AND er.created_at > NOW() - INTERVAL '7 days'
                   GROUP BY er.exercise_id, e.title""",
                user_id,
            )

    async def get_exercise_by_id(self, exercise_id: int, lang: str = "ru") -> asyncpg.Record | None:
        async with self.pool.acquire() as conn:
            return await conn.fetchrow(
                """SELECT e.*, COALESCE(tr_title.value, e.title) AS display_title,
                          COALESCE(tr_desc.value, e.description) AS display_description
                   FROM exercises e
                   LEFT JOIN translations tr_title ON tr_title.entity_type = 'exercises'
                       AND tr_title.entity_id = e.id AND tr_title.lang = $2 AND tr_title.field = 'title'
                   LEFT JOIN translations tr_desc ON tr_desc.entity_type = 'exercises'
                       AND tr_desc.entity_id = e.id AND tr_desc.lang = $2 AND tr_desc.field = 'description'
                   WHERE e.id = $1""",
                exercise_id, lang,
            )

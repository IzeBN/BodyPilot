import datetime
import calendar
from asyncpg import Pool
from app.repositories.training import TrainingRepository
from app.repositories.quiz import QuizRepository

SCHEDULE_DEFAULTS = {
    1: [2], 2: [1, 3], 3: [0, 2, 4], 4: [0, 1, 3, 5],
    5: [0, 1, 2, 3, 4], 6: [0, 1, 2, 3, 4, 5], 7: list(range(7)),
}


async def build_schedule(user_id: int, program_id: int, pool: Pool) -> None:
    training_repo = TrainingRepository(pool)
    quiz_repo = QuizRepository(pool)

    program = await training_repo.get_program_by_id(program_id)
    if not program:
        return

    workouts_raw = await training_repo.get_program_workouts(program_id)
    if not workouts_raw:
        return

    days_answer = await quiz_repo.get_answer(user_id, "training_days")
    if days_answer and days_answer["answer_type"] == "many_buttons":
        user_days = [int(v) - 1 for v in days_answer["answer"].split("%") if v.isdigit()]
    else:
        user_days = SCHEDULE_DEFAULTS.get(program["training_count"], [0, 2, 4])

    weeks_map: dict[str, list] = {}
    for w in workouts_raw:
        week_range = w["week_range"] or "1-1"
        if week_range not in weeks_map:
            weeks_map[week_range] = []
        weeks_map[week_range].append(w)

    all_workouts: list = []
    for week_range, workouts in weeks_map.items():
        try:
            start_w, end_w = map(int, week_range.split("-"))
        except ValueError:
            start_w, end_w = 1, 1
        for _ in range(start_w, end_w + 1):
            all_workouts.extend(workouts)

    all_workouts.reverse()

    entries: list[tuple] = []
    current = datetime.date.today() + datetime.timedelta(days=1)

    if program["training_count"] == len(user_days):
        while all_workouts:
            weekday = calendar.weekday(current.year, current.month, current.day)
            if weekday in user_days:
                workout = all_workouts.pop()
                entries.append((workout["id"], current))
            current += datetime.timedelta(days=1)
    else:
        target_days = SCHEDULE_DEFAULTS.get(program["training_count"], [0, 2, 4])
        while all_workouts:
            weekday = calendar.weekday(current.year, current.month, current.day)
            if weekday in target_days:
                workout = all_workouts.pop()
                entries.append((workout["id"], current))
            current += datetime.timedelta(days=1)

    if entries:
        await training_repo.create_schedule_entries(user_id, program_id, entries)

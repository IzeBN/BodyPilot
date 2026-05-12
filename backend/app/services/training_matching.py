from dataclasses import dataclass
from asyncpg import Pool
from app.repositories.quiz import QuizRepository
from app.repositories.training import TrainingRepository


@dataclass
class MatchedProgram:
    program_id: int
    score: int


async def match_training_program(user_id: int, pool: Pool) -> list[MatchedProgram]:
    quiz_repo = QuizRepository(pool)
    training_repo = TrainingRepository(pool)

    answers = await quiz_repo.get_answers(user_id)
    programs = await training_repo.get_programs_for_matching()

    if not answers or not programs:
        return []

    user_map: dict[str, list[int]] = {}
    for row in answers:
        key = row["question_key"]
        atype = row["answer_type"]
        val = row["answer"]
        if atype == "many_buttons":
            user_map[key] = [int(v) for v in val.split("%") if v.isdigit()]
        elif atype == "one_button":
            if val.isdigit():
                user_map[key] = [int(val)]

    training_days_answer = user_map.get("training_days", [])

    results: list[MatchedProgram] = []
    for prog in programs:
        sample_type = prog["sample_type"].lstrip("s").strip()
        parts = sample_type.split("%")

        prog_criteria: dict[str, list[int]] = {}
        for part in parts:
            if ":" not in part:
                continue
            key, ans_str = part.split(":", 1)
            prog_criteria[key] = [int(v) for v in ans_str.split("-") if v.isdigit()]

        score = 0
        if training_days_answer and prog["training_count"] == len(training_days_answer):
            score += 5

        for key, desired in prog_criteria.items():
            user_vals = user_map.get(key, [])
            score += len(set(user_vals) & set(desired))

        results.append(MatchedProgram(program_id=prog["id"], score=score))

    results.sort(key=lambda x: x.score, reverse=True)
    return results

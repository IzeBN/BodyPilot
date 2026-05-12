"""Integration tests for TrainingRepository and quiz answer matching."""
import pytest
import pytest_asyncio
from datetime import date

from app.repositories.auth import AuthRepository
from app.repositories.training import TrainingRepository
from app.repositories.quiz import QuizRepository
from app.services.auth import hash_password


@pytest_asyncio.fixture
async def auth_repo(pool_fixture):
    return AuthRepository(pool_fixture)


@pytest_asyncio.fixture
async def training_repo(pool_fixture):
    return TrainingRepository(pool_fixture)


@pytest_asyncio.fixture
async def quiz_repo(pool_fixture):
    return QuizRepository(pool_fixture)


@pytest_asyncio.fixture
async def user_id(auth_repo):
    return await auth_repo.create_user("training_test@example.com", hash_password("pass12345"), None)


# ─── get_programs ─────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_get_programs_returns_list(training_repo):
    """DB may have no programs initially — just check it doesn't raise."""
    programs = await training_repo.get_programs(None, "ru")
    assert isinstance(programs, list)


@pytest.mark.asyncio
async def test_get_program_by_id_not_found(training_repo):
    program = await training_repo.get_program_by_id(999_999)
    assert program is None


# ─── quiz answers ────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_upsert_and_get_answer(quiz_repo, user_id):
    await quiz_repo.upsert_answer(user_id, "goal", "many_buttons", "1%2")
    answer = await quiz_repo.get_answer(user_id, "goal")
    assert answer is not None
    assert answer["answer"] == "1%2"


@pytest.mark.asyncio
async def test_upsert_answer_updates_existing(quiz_repo, user_id):
    await quiz_repo.upsert_answer(user_id, "weight", "text", "80")
    await quiz_repo.upsert_answer(user_id, "weight", "text", "75")
    answer = await quiz_repo.get_answer(user_id, "weight")
    assert answer["answer"] == "75"


@pytest.mark.asyncio
async def test_get_answers_multiple_keys(quiz_repo, user_id):
    await quiz_repo.upsert_answer(user_id, "age", "text", "28")
    await quiz_repo.upsert_answer(user_id, "height", "text", "175")
    answers = await quiz_repo.get_answers(user_id, ["age", "height"])
    keys = {a["question_key"] for a in answers}
    assert keys == {"age", "height"}


@pytest.mark.asyncio
async def test_get_all_answers(quiz_repo, user_id):
    await quiz_repo.upsert_answer(user_id, "gender", "one_button", "1")
    all_answers = await quiz_repo.get_answers(user_id)
    assert any(a["question_key"] == "gender" for a in all_answers)


# ─── user_schedules ───────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_get_user_schedule_empty(training_repo, user_id):
    schedule = await training_repo.get_user_schedule(user_id)
    assert schedule == []


@pytest.mark.asyncio
async def test_get_last_week_results_empty(training_repo, user_id):
    results = await training_repo.get_last_week_results(user_id)
    assert results == []

"""Unit tests for QuizService."""
import pytest
from unittest.mock import patch, AsyncMock

from app.services.quiz_service import QuizService


@pytest.fixture
def service(mock_quiz_repo, mock_user_repo, mock_pool):
    return QuizService(mock_quiz_repo, mock_user_repo, mock_pool)


# ─── save_answer: serialization ───────────────────────────────────────────────

async def test_save_answer_text(service, mock_quiz_repo, mock_user_repo):
    await service.save_answer(1, "weight", "text", "75")
    mock_quiz_repo.upsert_answer.assert_awaited_once_with(1, "weight", "text", "75")
    mock_user_repo.add_action.assert_awaited_once()


async def test_save_answer_many_buttons(service, mock_quiz_repo):
    await service.save_answer(1, "training_days", "many_buttons", [1, 3, 5])
    mock_quiz_repo.upsert_answer.assert_awaited_once_with(1, "training_days", "many_buttons", "1%3%5")


async def test_save_answer_one_button_int(service, mock_quiz_repo):
    await service.save_answer(1, "gender", "one_button", 2)
    mock_quiz_repo.upsert_answer.assert_awaited_once_with(1, "gender", "one_button", "2")


async def test_save_answer_logs_action(service, mock_user_repo):
    await service.save_answer(1, "age", "text", "30")
    call_args = mock_user_repo.add_action.call_args
    assert "age" in call_args[0][1]


async def test_save_answer_single_item_list(service, mock_quiz_repo):
    await service.save_answer(1, "goal", "many_buttons", [2])
    mock_quiz_repo.upsert_answer.assert_awaited_once_with(1, "goal", "many_buttons", "2")


# ─── find_answers ─────────────────────────────────────────────────────────────

async def test_find_answers_empty(service, mock_quiz_repo):
    mock_quiz_repo.get_answers.return_value = []
    result = await service.find_answers(1, ["goal"])
    assert result == []


async def test_find_answers_returns_rows(service, mock_quiz_repo):
    mock_quiz_repo.get_answers.return_value = [
        {"question_key": "goal", "answer": "1%2", "answer_type": "many_buttons"}
    ]
    result = await service.find_answers(1, ["goal"])
    assert len(result) == 1
    assert result[0]["question_key"] == "goal"
    mock_quiz_repo.get_answers.assert_awaited_once_with(1, ["goal"])


# ─── get_all_answers ──────────────────────────────────────────────────────────

async def test_get_all_answers_empty(service, mock_quiz_repo):
    result = await service.get_all_answers(1)
    assert result == []


async def test_get_all_answers_returns_all(service, mock_quiz_repo):
    mock_quiz_repo.get_answers.return_value = [
        {"question_key": "age", "answer": "28", "answer_type": "text"},
        {"question_key": "weight", "answer": "80", "answer_type": "text"},
    ]
    result = await service.get_all_answers(1)
    assert len(result) == 2
    # get_all_answers calls get_answers with no keys filter
    mock_quiz_repo.get_answers.assert_awaited_once_with(1)


# ─── request_consultation ─────────────────────────────────────────────────────

async def test_request_consultation_logs_action(service, mock_user_repo, mock_pool, mock_conn):
    mock_conn.fetchrow.return_value = {"id": 1, "fullname": "Ivan"}

    with patch("app.config.get_settings") as mock_settings:
        mock_settings.return_value.telegram_bot_token = None
        mock_settings.return_value.telegram_users_chat_id = None
        await service.request_consultation(1, "2025-06-01", "14:00")

    mock_user_repo.add_action.assert_awaited_once()
    call_text = mock_user_repo.add_action.call_args[0][1]
    assert "2025-06-01" in call_text
    assert "14:00" in call_text


async def test_request_consultation_no_user(service, mock_user_repo, mock_pool, mock_conn):
    mock_conn.fetchrow.return_value = None

    with patch("app.config.get_settings") as mock_settings:
        mock_settings.return_value.telegram_bot_token = None
        await service.request_consultation(99, "2025-07-15", "10:30")

    mock_user_repo.add_action.assert_awaited_once()

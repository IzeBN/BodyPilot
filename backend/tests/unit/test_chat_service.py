"""Unit tests for ChatService — training and nutrition chats."""
import pytest
from unittest.mock import AsyncMock, patch


from app.services.chat_service import ChatService


@pytest.fixture
def service(mock_chat_repo, mock_user_repo, mock_pool):
    return ChatService(mock_chat_repo, mock_user_repo, mock_pool)


# ─── Training: send_training_message ─────────────────────────────────────────

async def test_send_training_message_returns_result(service, mock_user_repo):
    fake = {"reply": "Тренируйся!", "thread_id": "training_1", "agent_type": "training"}
    with patch("app.services.chat_service.process_training_message", new=AsyncMock(return_value=fake)):
        result = await service.send_training_message(1, "Как улучшить жим?", None)
    assert result["agent_type"] == "training"
    assert result["reply"] == "Тренируйся!"


async def test_send_training_message_logs_action(service, mock_user_repo):
    fake = {"reply": "ok", "thread_id": "training_1", "agent_type": "training"}
    with patch("app.services.chat_service.process_training_message", new=AsyncMock(return_value=fake)):
        await service.send_training_message(1, "Программа на массу?", None)
    mock_user_repo.add_action.assert_awaited_once()
    assert "training" in mock_user_repo.add_action.call_args[0][1].lower()


async def test_send_training_message_passes_thread_id(service, mock_user_repo):
    fake = {"reply": "ok", "thread_id": "t-custom", "agent_type": "training"}
    with patch("app.services.chat_service.process_training_message", new=AsyncMock(return_value=fake)) as mock_p:
        await service.send_training_message(1, "Вопрос", "t-custom")
    mock_p.assert_awaited_once_with(1, "Вопрос", "t-custom", service._pool)


# ─── Training: get_training_history ──────────────────────────────────────────

async def test_get_training_history_default_thread(service, mock_chat_repo):
    mock_chat_repo.get_history.return_value = []
    await service.get_training_history(1, None, 50)
    mock_chat_repo.get_history.assert_awaited_once_with(1, "training_1", 50)


async def test_get_training_history_custom_thread(service, mock_chat_repo):
    mock_chat_repo.get_history.return_value = []
    await service.get_training_history(1, "t-custom", 20)
    mock_chat_repo.get_history.assert_awaited_once_with(1, "t-custom", 20)


async def test_get_training_history_reversed(service, mock_chat_repo):
    mock_chat_repo.get_history.return_value = [
        {"id": 3, "role": "assistant", "content": "C"},
        {"id": 2, "role": "user", "content": "B"},
        {"id": 1, "role": "user", "content": "A"},
    ]
    result = await service.get_training_history(1, None, 50)
    assert result[0]["id"] == 1
    assert result[-1]["id"] == 3


# ─── Training: clear_training_history ────────────────────────────────────────

async def test_clear_training_history_calls_repo(service, mock_chat_repo):
    await service.clear_training_history(1)
    mock_chat_repo.delete_history_by_agent.assert_awaited_once_with(1, "training")


async def test_clear_training_history_logs_action(service, mock_user_repo):
    await service.clear_training_history(1)
    mock_user_repo.add_action.assert_awaited_once()
    text = mock_user_repo.add_action.call_args[0][1].lower()
    assert "training" in text


# ─── Nutrition: send_nutrition_message ───────────────────────────────────────

async def test_send_nutrition_message_returns_result(service, mock_user_repo):
    fake = {"reply": "Ешь больше белка!", "thread_id": "nutrition_1", "agent_type": "nutrition"}
    with patch("app.services.chat_service.process_nutrition_message", new=AsyncMock(return_value=fake)):
        result = await service.send_nutrition_message(1, "Что съесть после тренировки?", None)
    assert result["agent_type"] == "nutrition"
    assert result["reply"] == "Ешь больше белка!"


async def test_send_nutrition_message_logs_action(service, mock_user_repo):
    fake = {"reply": "ok", "thread_id": "nutrition_1", "agent_type": "nutrition"}
    with patch("app.services.chat_service.process_nutrition_message", new=AsyncMock(return_value=fake)):
        await service.send_nutrition_message(1, "Сколько калорий?", None)
    mock_user_repo.add_action.assert_awaited_once()
    assert "nutrition" in mock_user_repo.add_action.call_args[0][1].lower()


async def test_send_nutrition_message_passes_thread_id(service, mock_user_repo):
    fake = {"reply": "ok", "thread_id": "n-custom", "agent_type": "nutrition"}
    with patch("app.services.chat_service.process_nutrition_message", new=AsyncMock(return_value=fake)) as mock_p:
        await service.send_nutrition_message(1, "Вопрос", "n-custom")
    mock_p.assert_awaited_once_with(1, "Вопрос", "n-custom", service._pool)


# ─── Nutrition: get_nutrition_history ────────────────────────────────────────

async def test_get_nutrition_history_default_thread(service, mock_chat_repo):
    mock_chat_repo.get_history.return_value = []
    await service.get_nutrition_history(1, None, 50)
    mock_chat_repo.get_history.assert_awaited_once_with(1, "nutrition_1", 50)


async def test_get_nutrition_history_custom_thread(service, mock_chat_repo):
    mock_chat_repo.get_history.return_value = []
    await service.get_nutrition_history(1, "n-custom", 30)
    mock_chat_repo.get_history.assert_awaited_once_with(1, "n-custom", 30)


async def test_get_nutrition_history_reversed(service, mock_chat_repo):
    mock_chat_repo.get_history.return_value = [
        {"id": 2, "role": "assistant", "content": "B"},
        {"id": 1, "role": "user", "content": "A"},
    ]
    result = await service.get_nutrition_history(1, None, 50)
    assert result[0]["id"] == 1
    assert result[1]["id"] == 2


# ─── Nutrition: clear_nutrition_history ──────────────────────────────────────

async def test_clear_nutrition_history_calls_repo(service, mock_chat_repo):
    await service.clear_nutrition_history(1)
    mock_chat_repo.delete_history_by_agent.assert_awaited_once_with(1, "nutrition")


async def test_clear_nutrition_history_logs_action(service, mock_user_repo):
    await service.clear_nutrition_history(1)
    mock_user_repo.add_action.assert_awaited_once()
    text = mock_user_repo.add_action.call_args[0][1].lower()
    assert "nutrition" in text


# ─── Legacy: send_message (backward compat) ──────────────────────────────────

async def test_legacy_send_message_returns_result(service, mock_user_repo):
    fake = {"reply": "ok", "thread_id": "t1", "agent_type": "nutrition"}
    with patch("app.services.chat_service.process_chat_message", new=AsyncMock(return_value=fake)):
        result = await service.send_message(1, "Что съесть?", None)
    assert result["agent_type"] == "nutrition"


async def test_legacy_send_message_logs_action(service, mock_user_repo):
    fake = {"reply": "ok", "thread_id": "t1", "agent_type": "training"}
    with patch("app.services.chat_service.process_chat_message", new=AsyncMock(return_value=fake)):
        await service.send_message(1, "Тренировка?", None)
    mock_user_repo.add_action.assert_awaited_once()
    assert "training" in mock_user_repo.add_action.call_args[0][1]


# ─── Legacy: get_history / clear_history ─────────────────────────────────────

async def test_legacy_get_history_empty(service, mock_chat_repo):
    mock_chat_repo.get_history.return_value = []
    result = await service.get_history(1, None, 50)
    assert result == []


async def test_legacy_get_history_reversed(service, mock_chat_repo):
    mock_chat_repo.get_history.return_value = [
        {"id": 3, "role": "assistant", "content": "C"},
        {"id": 1, "role": "user", "content": "A"},
    ]
    result = await service.get_history(1, None, 50)
    assert result[0]["id"] == 1


async def test_legacy_clear_history_calls_repo(service, mock_chat_repo):
    await service.clear_history(1)
    mock_chat_repo.delete_history.assert_awaited_once_with(1)


async def test_legacy_clear_history_logs_action(service, mock_user_repo):
    await service.clear_history(1)
    mock_user_repo.add_action.assert_awaited_once()
    text = mock_user_repo.add_action.call_args[0][1].lower()
    assert "chat" in text or "history" in text

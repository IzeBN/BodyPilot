from fastapi import APIRouter, Depends
from app.dependencies import get_chat_service, get_current_user_id
from app.models.chat import SendMessageRequest, MessageResponse, ChatHistoryResponse
from app.models.common import OkResponse
from app.services.chat_service import ChatService

router = APIRouter(tags=["chat"])


# ─── Training chat ────────────────────────────────────────────────────────────

@router.post(
    "/chat/training",
    response_model=MessageResponse,
    summary="Send a message to the Training AI assistant",
    description=(
        "Ask about workout programs, exercise technique, recovery, progression, or training plans. "
        "The assistant is aware of your active program, fitness profile, injuries, and recent workout results. "
        "Each user has a default persistent thread (`training_{user_id}`); "
        "pass `thread_id` to start a separate sub-conversation."
    ),
)
async def send_training_message(
    body: SendMessageRequest,
    user_id: int = Depends(get_current_user_id),
    service: ChatService = Depends(get_chat_service),
):
    result = await service.send_training_message(user_id, body.message, body.thread_id)
    return MessageResponse(**result)


@router.get(
    "/chat/training",
    response_model=ChatHistoryResponse,
    summary="Get training chat history",
    description=(
        "Returns messages from the training chat in chronological order (oldest first). "
        "Defaults to the user's main thread (`training_{user_id}`). "
        "Pass `thread_id` to fetch a specific sub-conversation."
    ),
)
async def get_training_history(
    thread_id: str | None = None,
    limit: int = 50,
    user_id: int = Depends(get_current_user_id),
    service: ChatService = Depends(get_chat_service),
):
    messages = await service.get_training_history(user_id, thread_id, limit)
    used_thread = thread_id or f"training_{user_id}"
    return ChatHistoryResponse(thread_id=used_thread, messages=messages, total=len(messages))


@router.delete(
    "/chat/training",
    response_model=OkResponse,
    summary="Clear training chat history",
    description="Permanently deletes all training chat messages for the current user.",
)
async def clear_training_history(
    user_id: int = Depends(get_current_user_id),
    service: ChatService = Depends(get_chat_service),
):
    await service.clear_training_history(user_id)
    return OkResponse()


# ─── Nutrition chat ───────────────────────────────────────────────────────────

@router.post(
    "/chat/nutrition",
    response_model=MessageResponse,
    summary="Send a message to the Nutrition AI assistant",
    description=(
        "Ask about calories, macros, meal planning, food choices, dietary strategies, or supplements. "
        "The assistant is aware of your nutrition goals, today's logged meals, caloric balance, "
        "and body profile (weight, height, age, goal). "
        "Each user has a default persistent thread (`nutrition_{user_id}`); "
        "pass `thread_id` to start a separate sub-conversation."
    ),
)
async def send_nutrition_message(
    body: SendMessageRequest,
    user_id: int = Depends(get_current_user_id),
    service: ChatService = Depends(get_chat_service),
):
    result = await service.send_nutrition_message(user_id, body.message, body.thread_id)
    return MessageResponse(**result)


@router.get(
    "/chat/nutrition",
    response_model=ChatHistoryResponse,
    summary="Get nutrition chat history",
    description=(
        "Returns messages from the nutrition chat in chronological order (oldest first). "
        "Defaults to the user's main thread (`nutrition_{user_id}`). "
        "Pass `thread_id` to fetch a specific sub-conversation."
    ),
)
async def get_nutrition_history(
    thread_id: str | None = None,
    limit: int = 50,
    user_id: int = Depends(get_current_user_id),
    service: ChatService = Depends(get_chat_service),
):
    messages = await service.get_nutrition_history(user_id, thread_id, limit)
    used_thread = thread_id or f"nutrition_{user_id}"
    return ChatHistoryResponse(thread_id=used_thread, messages=messages, total=len(messages))


@router.delete(
    "/chat/nutrition",
    response_model=OkResponse,
    summary="Clear nutrition chat history",
    description="Permanently deletes all nutrition chat messages for the current user.",
)
async def clear_nutrition_history(
    user_id: int = Depends(get_current_user_id),
    service: ChatService = Depends(get_chat_service),
):
    await service.clear_nutrition_history(user_id)
    return OkResponse()


# ─── Legacy endpoint (kept for backward compatibility) ────────────────────────

@router.post(
    "/chat/message",
    response_model=MessageResponse,
    summary="[Legacy] Send a message — auto-routed to training or nutrition",
    description=(
        "Deprecated. Use `POST /chat/training` or `POST /chat/nutrition` instead. "
        "This endpoint routes to the appropriate assistant based on message keywords."
    ),
    deprecated=True,
)
async def send_message(
    body: SendMessageRequest,
    user_id: int = Depends(get_current_user_id),
    service: ChatService = Depends(get_chat_service),
):
    result = await service.send_message(user_id, body.message, body.thread_id)
    return MessageResponse(**result)


@router.get(
    "/chat/history",
    response_model=ChatHistoryResponse,
    summary="[Legacy] Get all chat history",
    description="Deprecated. Use `GET /chat/training` or `GET /chat/nutrition` instead.",
    deprecated=True,
)
async def get_history(
    thread_id: str | None = None,
    limit: int = 50,
    user_id: int = Depends(get_current_user_id),
    service: ChatService = Depends(get_chat_service),
):
    messages = await service.get_history(user_id, thread_id, limit)
    return ChatHistoryResponse(thread_id=thread_id or "", messages=messages, total=len(messages))


@router.delete(
    "/chat/history",
    response_model=OkResponse,
    summary="[Legacy] Clear all chat history",
    description="Deprecated. Use `DELETE /chat/training` or `DELETE /chat/nutrition` instead.",
    deprecated=True,
)
async def clear_history(
    user_id: int = Depends(get_current_user_id),
    service: ChatService = Depends(get_chat_service),
):
    await service.clear_history(user_id)
    return OkResponse()

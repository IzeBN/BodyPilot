from datetime import datetime
from pydantic import BaseModel, Field
from typing import Optional


class SendMessageRequest(BaseModel):
    message: str = Field(
        ..., min_length=1, max_length=4000,
        description="User message text.",
    )
    thread_id: Optional[str] = Field(
        None,
        description=(
            "Conversation thread ID. If omitted, the user's default thread for this chat "
            "is used automatically (training_{user_id} or nutrition_{user_id})."
        ),
    )


class MessageResponse(BaseModel):
    reply: str = Field(..., description="AI assistant reply")
    thread_id: str = Field(..., description="Thread ID used for this conversation")
    agent_type: str = Field(
        ...,
        description="Assistant that handled the request: 'training' or 'nutrition'",
        examples=["training", "nutrition"],
    )


class ChatMessageItem(BaseModel):
    id: int = Field(..., description="Message ID")
    role: str = Field(..., description="'user' or 'assistant'")
    content: str = Field(..., description="Message text")
    agent_type: Optional[str] = Field(None, description="'training' or 'nutrition'")
    thread_id: Optional[str] = Field(None, description="Conversation thread ID")
    created_at: datetime = Field(..., description="Timestamp (ISO 8601)")


class ChatHistoryResponse(BaseModel):
    thread_id: str = Field(..., description="Thread ID whose history is returned")
    messages: list[ChatMessageItem] = Field(..., description="Messages in chronological order (oldest first)")
    total: int = Field(..., description="Number of messages returned")

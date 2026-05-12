from pydantic import BaseModel, Field
from typing import Optional


class GenerateProgramResponse(BaseModel):
    program: str = Field(..., description="Generated training program text (Markdown or structured JSON string)")
    model: Optional[str] = Field(None, description="AI model used for generation")
    tokens_used: Optional[int] = Field(None, description="Total tokens consumed (prompt + completion)")


class ConsultResponse(BaseModel):
    reply: str = Field(..., description="AI assistant reply to the consultation question")
    conversation_id: Optional[str] = Field(None, description="Conversation ID for follow-up messages")
    model: Optional[str] = Field(None, description="AI model used")

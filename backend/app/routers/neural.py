from typing import Optional
from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.dependencies import get_neural_service, get_current_user_id
from app.models.neural import GenerateProgramResponse, ConsultResponse
from app.services.neural_service import NeuralService

router = APIRouter(prefix="/neural", tags=["neural"])


class GenerateProgramRequest(BaseModel):
    quiz: str = Field(..., description="Serialised quiz answers (JSON string or key:value format)")
    equipments: Optional[str] = Field(None, description="Serialised user equipment list")
    user_msg: Optional[str] = Field(None, description="Optional user message to include in generation context")
    patterns: Optional[str] = Field(None, description="Serialised user patterns for personalisation")
    lang: Optional[str] = Field(None, description="Response language ('ru' or 'en')")


class ConsultRequest(BaseModel):
    message: str = Field(..., description="User's question or message")
    conversation_id: Optional[str] = Field(None, description="Conversation ID to maintain context")
    context: Optional[str] = Field(None, description="Additional context string for the model")


@router.post(
    "/sample/generate",
    response_model=GenerateProgramResponse,
    summary="Generate a training program via AI",
    description=(
        "Uses the neural assistant to generate a personalised training program "
        "based on quiz answers, available equipment, and user patterns. "
        "Requires OPENAI_API_KEY to be configured."
    ),
)
async def generate_program(
    body: GenerateProgramRequest,
    user_id: int = Depends(get_current_user_id),
    service: NeuralService = Depends(get_neural_service),
):
    return await service.generate_program(
        body.quiz,
        body.equipments or "",
        body.user_msg,
        body.patterns,
        body.lang,
    )


@router.post(
    "/chat/message",
    response_model=ConsultResponse,
    summary="Send a message to the neural assistant",
    description=(
        "Direct access to the neural assistant for consultations. "
        "Unlike /chat/message, this endpoint bypasses intent routing and always uses "
        "the full neural consultation model."
    ),
)
async def chat_message(
    body: ConsultRequest,
    user_id: int = Depends(get_current_user_id),
    service: NeuralService = Depends(get_neural_service),
):
    return await service.consult(body.message, body.conversation_id, body.context)

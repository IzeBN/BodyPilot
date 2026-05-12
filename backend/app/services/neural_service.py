from typing import Optional
from fastapi import HTTPException

from app.neural.assistant import NeuralAssistant


class NeuralService:
    def __init__(self, assistant: NeuralAssistant) -> None:
        self._assistant = assistant

    def _check_ready(self) -> None:
        if not self._assistant or not self._assistant._ready:
            raise HTTPException(503, detail="Neural service not initialized")

    async def generate_program(
        self,
        quiz: str,
        equipments: str,
        user_msg: Optional[str] = None,
        patterns: Optional[str] = None,
        lang: Optional[str] = None,
    ) -> dict:
        self._check_ready()
        return await self._assistant.generate_program(quiz, equipments, user_msg, patterns, lang)

    async def consult(
        self,
        user_msg: str,
        conversation_id,
        context: Optional[str] = None,
    ) -> dict:
        self._check_ready()
        return await self._assistant.consult(user_msg, conversation_id, context)

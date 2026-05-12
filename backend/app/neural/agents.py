import json
import datetime
import logging
from typing import Literal, Optional

import httpx
import openai

from .embeddings import Embeddings

logger = logging.getLogger("neural.agents")

_LANG_INSTRUCTIONS = {
    "ru": "Отвечай исключительно на русском языке.",
    "en": "Respond exclusively in English.",
    "de": "Antworte ausschließlich auf Deutsch.",
    "fr": "Réponds exclusivement en français.",
    "es": "Responde exclusivamente en español.",
    "pt": "Responda exclusivamente em português.",
    "zh": "请只用中文回答。",
    "ar": "أجب حصريًا باللغة العربية.",
    "tr": "Yalnızca Türkçe yanıt ver.",
}


def _lang_msg(lang: Optional[str]) -> list:
    if not lang or lang == "ru":
        return []
    instruction = _LANG_INSTRUCTIONS.get(lang, f'Respond exclusively in the language with code "{lang}".')
    return [{"role": "system", "content": instruction}]


def _make_client(api_key: str, proxy: Optional[str]) -> openai.AsyncOpenAI:
    kwargs = {"api_key": api_key}
    if proxy:
        kwargs["http_client"] = httpx.AsyncClient(proxy=proxy)
    return openai.AsyncOpenAI(**kwargs)


class RouteAgent:
    def __init__(self, api_key: str, proxy: Optional[str], prompts: dict) -> None:
        self._prompts = prompts
        self._client = _make_client(api_key, proxy)

    async def get_route(self, msg: str) -> Literal["consult", "generate"]:
        resp = await self._client.chat.completions.create(
            model="gpt-4.1",
            messages=[
                {"role": "system", "content": self._prompts["Route"]},
                {"role": "user", "content": msg},
            ],
            temperature=0,
        )
        route = resp.choices[0].message.content.strip().lower().rstrip(".,!?;:")
        return route if route in {"consult", "generate"} else "consult"


class PatternsAgent:
    def __init__(self, api_key: str, proxy: Optional[str], prompts: dict) -> None:
        self._prompts = prompts
        self._client = _make_client(api_key, proxy)

    async def get_patterns(self, msg: str) -> Optional[str]:
        resp = await self._client.chat.completions.create(
            model="gpt-4.1",
            messages=[
                {"role": "system", "content": self._prompts["Patterns"]},
                {"role": "user", "content": msg},
            ],
            temperature=0.5,
        )
        text = resp.choices[0].message.content.strip()
        return None if text == "null" else text


class InterpretationAgent:
    def __init__(self, api_key: str, proxy: Optional[str], prompts: dict) -> None:
        self._prompts = prompts
        self._client = _make_client(api_key, proxy)

    async def get_interpretation(self, analyzed_quiz: str, lang: Optional[str] = None) -> Optional[str]:
        resp = await self._client.chat.completions.create(
            model="gpt-4.1",
            messages=[
                {"role": "system", "content": self._prompts["Interpretation"]},
                *_lang_msg(lang),
                {"role": "user", "content": analyzed_quiz},
            ],
            max_completion_tokens=350,
            temperature=0.9,
        )
        return resp.choices[0].message.content.strip()


class StagesAgent:
    def __init__(self, api_key: str, proxy: Optional[str], prompts: dict, schemas: dict) -> None:
        self._prompts = prompts
        self._schemas = schemas
        self._client = _make_client(api_key, proxy)

    async def get_stages(self, analyzed_quiz: str, lang: Optional[str] = None) -> Optional[list]:
        resp = await self._client.chat.completions.create(
            model="gpt-4.1",
            messages=[
                {"role": "system", "content": self._prompts["Stages"]},
                *_lang_msg(lang),
                {"role": "user", "content": analyzed_quiz},
            ],
            max_completion_tokens=100,
            response_format={"type": "json_schema", "json_schema": self._schemas["Stages"]},
            temperature=0.9,
        )
        try:
            parsed = json.loads(resp.choices[0].message.content.strip())
            if isinstance(parsed, dict) and "stages" in parsed:
                return parsed["stages"]
            if isinstance(parsed, list):
                return parsed
        except Exception:
            pass
        return None


class ExercisesAgent:
    def __init__(self, api_key: str, proxy: Optional[str], prompts: dict, embeddings: Embeddings) -> None:
        self._prompts = prompts
        self._embeddings = embeddings
        self._client = _make_client(api_key, proxy)

    async def get_exercises(self, analyzed_quiz: str, lang: Optional[str] = None) -> Optional[str]:
        exercises = await self._embeddings.search_exercises_by_query(analyzed_quiz, to_string=True)
        resp = await self._client.chat.completions.create(
            model="gpt-4.1",
            messages=[
                {"role": "system", "content": self._prompts["Exercizes"]},
                *_lang_msg(lang),
                {"role": "user", "content": f"Анкета:\n{analyzed_quiz}"},
                {"role": "user", "content": f"Список упражнений:\n{exercises}"},
            ],
            temperature=0.3,
        )
        return resp.choices[0].message.content.strip()


class QuizAgent:
    def __init__(self, api_key: str, proxy: Optional[str], prompts: dict) -> None:
        self._prompts = prompts
        self._client = _make_client(api_key, proxy)

    def _no_equipment_requested(self, user_msg: Optional[str]) -> bool:
        if not user_msg:
            return False
        keywords = [
            "без оборудования", "нет оборудования", "не используя оборудование",
            "без инвентаря", "нет инвентаря", "без тренажеров", "нет тренажеров",
            "только с весом тела", "с весом собственного тела", "без снаряжения", "нет снаряжения",
        ]
        lower = user_msg.lower()
        return any(k in lower for k in keywords)

    async def analyze_quiz(
        self,
        quiz: str,
        equipments: str,
        user_msg: Optional[str] = None,
        patterns: Optional[str] = None,
        lang: Optional[str] = None,
    ) -> Optional[str]:
        no_equip = self._no_equipment_requested(user_msg)
        additional = [] if not user_msg else [{"role": "user", "content": user_msg}]

        if no_equip or not equipments or not equipments.strip():
            additional.append({
                "role": "user",
                "content": "ВАЖНО: У пользователя НЕТ оборудования. Составь программу только с упражнениями без оборудования (с весом собственного тела).",
            })
        elif equipments:
            additional.append({"role": "user", "content": f"Оборудование: {equipments}"})

        if patterns:
            additional.append({"role": "user", "content": patterns})

        resp = await self._client.chat.completions.create(
            model="gpt-4.1",
            messages=[
                {"role": "system", "content": self._prompts["AnalizeQuiz"]},
                *_lang_msg(lang),
                {"role": "user", "content": quiz},
                *additional,
            ],
            temperature=0.2,
        )
        return resp.choices[0].message.content.strip()


class GenerateProgramAgent:
    def __init__(self, api_key: str, proxy: Optional[str], prompts: dict, schemas: dict) -> None:
        self._prompts = prompts
        self._schemas = schemas
        self._client = _make_client(api_key, proxy)

    async def generate_program(
        self,
        analyzed_quiz: str,
        exercises: str,
        lang: Optional[str] = None,
    ) -> dict:
        today = datetime.date.today()
        resp = await self._client.chat.completions.create(
            model="gpt-4.1",
            messages=[
                {"role": "system", "content": self._prompts["GenerateSample"]},
                {"role": "system", "content": f"Дата сегодня: {today}"},
                *_lang_msg(lang),
                {"role": "user", "content": analyzed_quiz},
                {"role": "user", "content": exercises},
            ],
            temperature=0.3,
            response_format={"type": "json_schema", "json_schema": self._schemas["GenerateSample"]},
        )
        return json.loads(resp.choices[0].message.content.strip())


class ConsultantAgent:
    def __init__(self, api_key: str, proxy: Optional[str], prompts: dict) -> None:
        self._prompts = prompts
        self._client = _make_client(api_key, proxy)

    async def get_consultation(self, msg: str, conversation_id, context: Optional[str]) -> dict:
        if not conversation_id:
            chat = await self._client.conversations.create()
            conversation_id = chat.id

        if context:
            msg = f"ЗАДАЮ ВОПРОС ПО ТРЕНИРОВКЕ: {context}\n\n{msg}"

        resp = await self._client.responses.create(
            model="gpt-4.1",
            instructions=self._prompts["Consult"],
            input=msg,
            conversation=conversation_id,
        )
        text = resp.output[-1].content[-1].text
        try:
            result = json.loads(text)
        except Exception:
            result = None

        return {"agent": "consult", "result": result, "conversation_id": conversation_id}

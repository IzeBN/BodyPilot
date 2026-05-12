import json
import logging
from pathlib import Path
from typing import Optional

from .embeddings import Embeddings
from .agents import (
    RouteAgent, QuizAgent, PatternsAgent,
    InterpretationAgent, StagesAgent, ExercisesAgent,
    GenerateProgramAgent, ConsultantAgent,
)

logger = logging.getLogger("neural.assistant")

ASSETS_PATH = Path(__file__).parent / "assets"


class NeuralAssistant:
    def __init__(self, api_key: str, proxy: Optional[str] = None) -> None:
        self._api_key = api_key
        self._proxy = proxy
        self._ready = False
        self._prompts: dict = {}
        self._schemas: dict = {}
        self.embeddings: Embeddings = Embeddings()
        self.routing: RouteAgent = None
        self.quiz: QuizAgent = None
        self.patterns: PatternsAgent = None
        self.interpretation: InterpretationAgent = None
        self.stages: StagesAgent = None
        self.exercises: ExercisesAgent = None
        self.program: GenerateProgramAgent = None
        self.consultation: ConsultantAgent = None

    async def initialize(self) -> None:
        await self._load_assets()
        await self.embeddings.initialize()
        self.routing = RouteAgent(self._api_key, self._proxy, self._prompts)
        self.quiz = QuizAgent(self._api_key, self._proxy, self._prompts)
        self.patterns = PatternsAgent(self._api_key, self._proxy, self._prompts)
        self.interpretation = InterpretationAgent(self._api_key, self._proxy, self._prompts)
        self.stages = StagesAgent(self._api_key, self._proxy, self._prompts, self._schemas)
        self.exercises = ExercisesAgent(self._api_key, self._proxy, self._prompts, self.embeddings)
        self.program = GenerateProgramAgent(self._api_key, self._proxy, self._prompts, self._schemas)
        self.consultation = ConsultantAgent(self._api_key, self._proxy, self._prompts)
        self._ready = True
        logger.info("NeuralAssistant initialized")

    async def _load_assets(self) -> None:
        for path in (ASSETS_PATH / "promts").iterdir():
            if path.suffix == ".txt":
                self._prompts[path.stem] = path.read_text(encoding="utf-8")

        for path in (ASSETS_PATH / "schemas").iterdir():
            if path.suffix == ".json":
                self._schemas[path.stem] = json.loads(path.read_text(encoding="utf-8"))

    # ── Public API ────────────────────────────────────────────────────────────

    async def generate_program(
        self,
        quiz: str,
        equipments: str,
        user_msg: Optional[str] = None,
        patterns: Optional[str] = None,
        lang: Optional[str] = None,
    ) -> dict:
        logger.info(f"generate_program start (lang={lang})")
        analyzed_quiz = await self.quiz.analyze_quiz(quiz, equipments, user_msg, patterns, lang=lang)
        logger.info("quiz analyzed, selecting exercises")
        exercises = await self.exercises.get_exercises(analyzed_quiz, lang=lang)
        logger.info("exercises selected, generating interpretation + stages + program")
        interpretation = await self.interpretation.get_interpretation(analyzed_quiz, lang=lang)
        stages = await self.stages.get_stages(analyzed_quiz, lang=lang)
        program = await self.program.generate_program(analyzed_quiz, exercises, lang=lang)
        logger.info("generate_program done")
        return {
            "agent": "generate",
            "result": program,
            "analized_quiz": analyzed_quiz,
            "exercizes": exercises,
            "interpretation": interpretation,
            "stages": stages,
        }

    async def consult(
        self,
        user_msg: str,
        conversation_id,
        context: Optional[str] = None,
    ) -> dict:
        route = await self.routing.get_route(user_msg)
        if route == "generate":
            return {"route": "generate"}
        response = await self.consultation.get_consultation(user_msg, conversation_id, context)
        return {"agent": "consult", "result": response}


_assistant: Optional[NeuralAssistant] = None


def get_assistant() -> NeuralAssistant:
    return _assistant


async def init_assistant(api_key: str, proxy: Optional[str] = None) -> NeuralAssistant:
    global _assistant
    _assistant = NeuralAssistant(api_key, proxy)
    await _assistant.initialize()
    return _assistant

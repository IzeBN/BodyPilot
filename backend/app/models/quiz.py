from pydantic import BaseModel, Field
from typing import Literal, Union, Optional, Any


class QuizAnswerRequest(BaseModel):
    question_key: str = Field(
        ...,
        description="Question identifier key",
        examples=["goal", "gender", "experience", "training_days", "weight", "age"],
    )
    answer_type: Literal["text", "one_button", "many_buttons"] = Field(
        ...,
        description=(
            "Answer format: "
            "'text' — free-form string or number; "
            "'one_button' — single choice (int); "
            "'many_buttons' — multiple choice (list of ints)"
        ),
    )
    answer: Union[str, int, list[int]] = Field(
        ...,
        description="Answer value matching the declared answer_type",
    )


class QuizFindRequest(BaseModel):
    keys: list[str] = Field(
        ...,
        description="List of question keys to retrieve answers for",
        examples=[["goal", "experience", "current_fat_pct"]],
    )


class ConsultationRequest(BaseModel):
    date: str = Field(..., description="Preferred consultation date (YYYY-MM-DD)", examples=["2025-05-20"])
    time: str = Field(..., description="Preferred consultation time (HH:MM)", examples=["14:00"])


# ── Response models ────────────────────────────────────────────────────────────

class QuizQuestionOption(BaseModel):
    key: int = Field(..., description="Option key (integer ID)")
    label: str = Field(..., description="Human-readable option label")


class QuizQuestionResponse(BaseModel):
    title: str = Field(..., description="Question text")
    type: str = Field(..., description="Answer type: text / one_button / many_buttons")
    answers: dict[int, str] = Field(..., description="Available answer options (empty for text questions)")


class QuizQuestionsResponse(BaseModel):
    lang: str = Field(..., description="Language of the questions (ru / en)")
    questions: dict[str, QuizQuestionResponse] = Field(
        ..., description="All quiz questions keyed by question ID"
    )


class QuizAnswerItem(BaseModel):
    question_key: str = Field(..., description="Question identifier")
    answer_type: str = Field(..., description="Answer type: text / one_button / many_buttons")
    answer: Any = Field(..., description="Stored answer value")


class QuizAnswersResponse(BaseModel):
    answers: list[QuizAnswerItem] = Field(..., description="All saved quiz answers for the user")


class QuizFindResponse(BaseModel):
    answers: dict[str, Optional[Any]] = Field(
        ...,
        description="Requested answers keyed by question key. Value is null if not yet answered.",
    )

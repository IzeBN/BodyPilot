from pydantic import BaseModel, Field


class OkResponse(BaseModel):
    ok: bool = Field(True, description="Always true when the operation succeeded")


class WebhookStatusResponse(BaseModel):
    status: int = Field(200, description="HTTP status code echo")

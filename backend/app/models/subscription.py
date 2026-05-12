from pydantic import BaseModel, EmailStr, Field
from typing import Optional


class CreatePaymentRequest(BaseModel):
    plan_id: int = Field(..., description="ID of the subscription plan to purchase")
    email: Optional[EmailStr] = Field(
        None,
        description="Email for payment receipt. Required for paid plans, optional for free/trial.",
    )
    is_trial: bool = Field(False, description="Activate trial period (1 RUB charge)")


class LandingBidRequest(BaseModel):
    name: Optional[str] = Field(None, description="Applicant name")
    email: Optional[EmailStr] = Field(None, description="Contact email")
    phone: Optional[str] = Field(None, description="Contact phone number", examples=["+79001234567"])


class SubscriptionPlanResponse(BaseModel):
    id: int = Field(..., description="Plan ID")
    name: str = Field(..., description="Plan name")
    description: Optional[str] = Field(None, description="Plan description")
    price_rub: Optional[float] = Field(None, description="Price in RUB (null = free)")
    duration_days: Optional[int] = Field(None, description="Subscription duration in days (null = unlimited)")
    is_trial: bool = Field(..., description="Whether this is a trial plan")
    features: Optional[dict] = Field(None, description="Feature flags as JSON object")


class CreatePaymentResponse(BaseModel):
    payment_url: Optional[str] = Field(
        None,
        description="YooKassa payment URL to redirect the user. Null for free plans.",
    )
    plan_id: int = Field(..., description="Activated plan ID")
    payment_id: Optional[str] = Field(None, description="YooKassa payment ID (for paid plans)")


# ── Response models ────────────────────────────────────────────────────────────

class ActiveSubscriptionResponse(BaseModel):
    id: int = Field(..., description="Subscription record ID")
    plan_id: int = Field(..., description="Plan ID")
    plan_name: str = Field(..., description="Plan name")
    status: str = Field(..., description="Subscription status: active / cancelled / expired")
    cost_rub: Optional[float] = Field(None, description="Amount paid in RUB")
    start_date: str = Field(..., description="Subscription start date (ISO 8601)")
    end_date: Optional[str] = Field(None, description="Subscription end date (ISO 8601); null = unlimited")
    is_trial: bool = Field(..., description="Whether this is a trial subscription")

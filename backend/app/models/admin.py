from pydantic import BaseModel, Field
from typing import Optional, Any


class NotificationSendResult(BaseModel):
    success_count: int = Field(..., description="Number of devices that received the notification")
    failure_count: int = Field(..., description="Number of delivery failures")


class NotificationHistoryItem(BaseModel):
    id: int = Field(..., description="Notification record ID")
    admin_id: int = Field(..., description="Admin user ID who sent the notification")
    title: str = Field(..., description="Notification title")
    body: str = Field(..., description="Notification body text")
    target: str = Field(..., description="Target description: 'all' or comma-separated user IDs")
    success_count: int = Field(..., description="Successfully delivered count")
    failure_count: int = Field(..., description="Failed delivery count")
    sent_at: str = Field(..., description="Timestamp the notification was sent (ISO 8601)")


class AdminUserItem(BaseModel):
    id: int = Field(..., description="User ID")
    email: Optional[str] = Field(None, description="User email")
    fullname: Optional[str] = Field(None, description="Full name")
    telegram_user_id: Optional[int] = Field(None, description="Linked Telegram user ID")
    ai_consent: bool = Field(..., description="AI consent status")
    created_at: str = Field(..., description="Registration timestamp (ISO 8601)")
    subscription_status: Optional[str] = Field(None, description="Active subscription status")


class UserActionItem(BaseModel):
    id: int = Field(..., description="Action record ID")
    action: str = Field(..., description="Action name/description")
    created_at: str = Field(..., description="Timestamp (ISO 8601)")


class AnalyticsDayItem(BaseModel):
    date: str = Field(..., description="Date (YYYY-MM-DD)")
    registrations: int = Field(..., description="New user registrations")
    new_subscribers: int = Field(..., description="New paid subscriptions")
    active_users: int = Field(..., description="Unique users with at least one action")


class AnalyticsResponse(BaseModel):
    date_from: str = Field(..., description="Range start (YYYY-MM-DD)")
    date_to: str = Field(..., description="Range end (YYYY-MM-DD)")
    total_registrations: int = Field(..., description="Total registrations in the period")
    total_subscribers: int = Field(..., description="Total new subscriptions in the period")
    days: list[AnalyticsDayItem] = Field(..., description="Per-day breakdown")


class UserFullDataResponse(BaseModel):
    user: dict = Field(..., description="Basic user record")
    nutrition_profile: Optional[dict] = Field(None, description="Nutrition profile")
    training_profile: Optional[dict] = Field(None, description="Training profile")
    subscription: Optional[dict] = Field(None, description="Active subscription")
    quiz_answers: list[dict] = Field(default_factory=list, description="All quiz answers")
    equipment: list[dict] = Field(default_factory=list, description="User equipment list")


class UserMessageItem(BaseModel):
    id: int = Field(..., description="Message ID")
    role: str = Field(..., description="'user' or 'assistant'")
    content: str = Field(..., description="Message text")
    created_at: str = Field(..., description="Timestamp (ISO 8601)")

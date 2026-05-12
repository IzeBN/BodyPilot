from datetime import date, timedelta
from typing import Optional
from fastapi import APIRouter, Depends, UploadFile, File, Form
from pydantic import BaseModel

from app.dependencies import get_admin_service, require_admin
from app.models.admin import (
    NotificationSendResult, NotificationHistoryItem,
    AdminUserItem, UserActionItem, UserFullDataResponse,
    UserMessageItem, AnalyticsResponse,
)
from app.models.common import OkResponse
from app.services.admin_service import AdminService

router = APIRouter(
    prefix="/admin",
    tags=["admin"],
    # All admin endpoints require admin role — validated in require_admin dependency
)

PERIODS = {
    "week": timedelta(7), "month": timedelta(30),
    "threeMonths": timedelta(90), "sixMonths": timedelta(180),
    "year": timedelta(365), "all": timedelta(weeks=999),
}


class SendNotificationRequest(BaseModel):
    title: str
    body: str
    user_ids: Optional[list[int]] = None
    all_users: bool = False
    data: Optional[dict] = None


@router.post(
    "/notifications/send",
    response_model=NotificationSendResult,
    summary="Send push notifications",
    description="Send FCM push to specific users or all users. Saves history for audit.",
)
async def send_notification(
    body: SendNotificationRequest,
    admin_id: int = Depends(require_admin),
    service: AdminService = Depends(get_admin_service),
):
    return await service.send_push(
        admin_id, body.title, body.body, body.user_ids, body.all_users, body.data
    )


@router.get(
    "/notifications/history",
    response_model=list[NotificationHistoryItem],
    summary="Notification send history",
    description="Returns the last N notification sends with delivery stats.",
)
async def get_notification_history(
    limit: int = 50,
    admin_id: int = Depends(require_admin),
    service: AdminService = Depends(get_admin_service),
):
    return await service.get_notification_history(limit)


@router.get(
    "/users",
    response_model=list[AdminUserItem],
    summary="List all users",
    description="Returns all registered users with basic info and subscription status.",
)
async def get_all_users(
    admin_id: int = Depends(require_admin),
    service: AdminService = Depends(get_admin_service),
):
    return await service.get_all_users()


@router.get(
    "/users/{user_id}/actions",
    response_model=list[UserActionItem],
    summary="Get user action log",
    description="Returns all recorded actions for the given user, newest first.",
)
async def get_user_actions(
    user_id: int,
    admin_id: int = Depends(require_admin),
    service: AdminService = Depends(get_admin_service),
):
    return await service.get_user_actions(user_id)


@router.get(
    "/users/{user_id}/data",
    response_model=UserFullDataResponse,
    summary="Get full user data snapshot",
    description="Returns a complete snapshot of the user's data: profile, quiz answers, equipment, subscription.",
)
async def get_user_full_data(
    user_id: int,
    admin_id: int = Depends(require_admin),
    service: AdminService = Depends(get_admin_service),
):
    return await service.get_user_full_data(user_id)


@router.get(
    "/users/{user_id}/messages",
    response_model=list[UserMessageItem],
    summary="Get user chat messages",
    description="Returns all AI chat messages for the given user, oldest first.",
)
async def get_user_messages(
    user_id: int,
    admin_id: int = Depends(require_admin),
    service: AdminService = Depends(get_admin_service),
):
    return await service.get_user_messages(user_id)


@router.post(
    "/users/{user_id}/send-message",
    response_model=OkResponse,
    summary="Send Telegram message to user",
    description="Send a text message and/or image to the user via Telegram bot.",
)
async def send_message_to_user(
    user_id: int,
    msg: Optional[str] = Form(None),
    image: Optional[UploadFile] = File(None),
    admin_id: int = Depends(require_admin),
    service: AdminService = Depends(get_admin_service),
):
    image_data = await image.read() if image else None
    await service.send_telegram_message(
        admin_id, user_id, msg,
        image_data,
        image.filename if image else None,
        image.content_type if image else None,
    )
    return OkResponse()


@router.get(
    "/analytics",
    response_model=AnalyticsResponse,
    summary="Daily analytics: registrations, subscribers, active users",
    description=(
        "Returns daily breakdown of registrations, new subscriptions, and active users "
        "for the given period. Use for admin dashboard charts."
    ),
)
async def get_analytics(
    period: Optional[str] = "month",
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    admin_id: int = Depends(require_admin),
    service: AdminService = Depends(get_admin_service),
):
    end = date.today() if not end_date else date.fromisoformat(end_date)
    start = date.fromisoformat(start_date) if start_date else end - PERIODS.get(period, timedelta(30))
    return await service.get_analytics(start, end)

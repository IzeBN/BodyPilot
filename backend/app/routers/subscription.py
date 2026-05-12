from fastapi import APIRouter, Depends
from app.dependencies import get_subscription_service, get_current_user_id
from app.models.subscription import (
    CreatePaymentRequest, LandingBidRequest,
    CreatePaymentResponse, SubscriptionPlanResponse, ActiveSubscriptionResponse,
)
from app.models.common import OkResponse
from app.services.subscription_service import SubscriptionService

router = APIRouter(prefix="/subscription", tags=["subscription"])


@router.get(
    "/plans",
    response_model=list[SubscriptionPlanResponse],
    summary="List subscription plans",
    description=(
        "Returns all available subscription plans ordered by price. "
        "Includes trial and free plans. Use to build the paywall/tariffs screen."
    ),
)
async def get_plans(service: SubscriptionService = Depends(get_subscription_service)):
    return await service.get_plans()


@router.get(
    "/active",
    response_model=ActiveSubscriptionResponse | None,
    summary="Get active subscription",
    description=(
        "Returns the user's current active subscription with plan details and expiry date. "
        "Returns null if no active subscription exists."
    ),
)
async def get_active(
    user_id: int = Depends(get_current_user_id),
    service: SubscriptionService = Depends(get_subscription_service),
):
    return await service.get_active(user_id)


@router.post(
    "/create-payment",
    response_model=CreatePaymentResponse,
    summary="Create payment or activate plan",
    description=(
        "For paid plans: creates a YooKassa payment and returns a redirect URL. "
        "For free or trial plans: activates immediately and returns payment_url=null. "
        "Email is required for paid plans to generate a fiscal receipt."
    ),
)
async def create_payment(
    body: CreatePaymentRequest,
    user_id: int = Depends(get_current_user_id),
    service: SubscriptionService = Depends(get_subscription_service),
):
    return await service.create_payment(user_id, body.plan_id, body.email, body.is_trial)


@router.post(
    "/cancel",
    response_model=OkResponse,
    summary="Cancel active subscription",
    description="Marks the user's active subscription as cancelled. Does not issue refunds.",
)
async def cancel(
    user_id: int = Depends(get_current_user_id),
    service: SubscriptionService = Depends(get_subscription_service),
):
    await service.cancel(user_id)
    return OkResponse()


@router.post(
    "/landing-bid",
    response_model=OkResponse,
    summary="Submit a landing page lead",
    description=(
        "Record a contact request from the landing page. "
        "Data is stored for CRM follow-up. No authentication required."
    ),
    status_code=201,
)
async def landing_bid(
    body: LandingBidRequest,
    service: SubscriptionService = Depends(get_subscription_service),
):
    await service.add_landing_bid(body.name, body.email, body.phone)
    return OkResponse()

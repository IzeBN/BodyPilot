from fastapi import APIRouter, Depends, Request
from app.dependencies import get_auth_service, get_current_user_id
from app.models.auth import (
    RegisterRequest, LoginRequest, RefreshRequest, LogoutRequest,
    TokenResponse, AccessTokenResponse, FcmTokenRequest,
)
from app.models.user import UserProfile
from app.models.common import OkResponse
from app.models.user import AiConsentRequest
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post(
    "/register",
    response_model=TokenResponse,
    summary="Register new account",
    description="Create a new user account with email and password. Returns access and refresh tokens.",
    status_code=201,
)
async def register(
    body: RegisterRequest,
    request: Request,
    service: AuthService = Depends(get_auth_service),
):
    ip = request.client.host if request.client else None
    ua = request.headers.get("user-agent")
    return await service.register(body.email, body.password, body.fullname, ip, ua)


@router.post(
    "/login",
    response_model=TokenResponse,
    summary="Login with email/password",
    description="Authenticate with email and password. Returns access and refresh tokens.",
)
async def login(
    body: LoginRequest,
    request: Request,
    service: AuthService = Depends(get_auth_service),
):
    ip = request.client.host if request.client else None
    ua = request.headers.get("user-agent")
    return await service.login(body.email, body.password, ip, ua)


@router.post(
    "/refresh",
    response_model=AccessTokenResponse,
    summary="Refresh access token",
    description="Exchange a valid refresh token for a new short-lived access token.",
)
async def refresh(
    body: RefreshRequest,
    service: AuthService = Depends(get_auth_service),
):
    return await service.refresh(body.refresh_token)


@router.post(
    "/logout",
    response_model=OkResponse,
    summary="Logout (invalidate refresh token)",
    description="Invalidates the provided refresh token. The access token remains valid until expiry.",
)
async def logout(
    body: LogoutRequest,
    service: AuthService = Depends(get_auth_service),
):
    await service.logout(body.refresh_token)
    return OkResponse()


@router.get(
    "/me",
    response_model=UserProfile,
    summary="Get current user",
    description="Returns basic profile info for the authenticated user.",
)
async def me(
    user_id: int = Depends(get_current_user_id),
    service: AuthService = Depends(get_auth_service),
):
    return await service.get_me(user_id)


@router.delete(
    "/account",
    response_model=OkResponse,
    summary="Delete account",
    description="Permanently deletes the user's account and all associated data.",
)
async def delete_account(
    user_id: int = Depends(get_current_user_id),
    service: AuthService = Depends(get_auth_service),
):
    await service.delete_account(user_id)
    return OkResponse()


@router.post(
    "/ai-consent",
    response_model=OkResponse,
    summary="Update AI consent",
    description="Record user's consent (or revocation) for AI data processing. Required before AI features can be used.",
)
async def update_ai_consent(
    body: AiConsentRequest,
    user_id: int = Depends(get_current_user_id),
    service: AuthService = Depends(get_auth_service),
):
    await service.update_ai_consent(user_id, body.consent)
    return OkResponse()


@router.post(
    "/fcm-token",
    response_model=OkResponse,
    summary="Register FCM push token",
    description="Register or update a Firebase Cloud Messaging token for push notifications.",
)
async def register_fcm_token(
    body: FcmTokenRequest,
    user_id: int = Depends(get_current_user_id),
    service: AuthService = Depends(get_auth_service),
):
    await service.register_fcm_token(user_id, body.token, body.platform)
    return OkResponse()

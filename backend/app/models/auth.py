from pydantic import BaseModel, EmailStr, Field
from typing import Optional


class RegisterRequest(BaseModel):
    email: EmailStr = Field(..., description="User email address", examples=["user@example.com"])
    password: str = Field(..., min_length=8, description="Password (min 8 characters)")
    fullname: Optional[str] = Field(None, description="Full name", examples=["Ivan Petrov"])


class LoginRequest(BaseModel):
    email: EmailStr = Field(..., description="Registered email address")
    password: str = Field(..., description="Account password")


class AppleAuthRequest(BaseModel):
    identity_token: str = Field(..., description="Apple Sign In identity token")
    fullname: Optional[str] = Field(None, description="Full name from Apple ID")


class RefreshRequest(BaseModel):
    refresh_token: str = Field(..., description="Opaque refresh token from previous auth")


class LogoutRequest(BaseModel):
    refresh_token: str = Field(..., description="Refresh token to invalidate")


class TokenResponse(BaseModel):
    access_token: str = Field(..., description="JWT access token (short-lived, 15 min)")
    refresh_token: str = Field(..., description="Opaque refresh token (30 days)")
    token_type: str = Field("bearer", description="Token type, always 'bearer'")


class AccessTokenResponse(BaseModel):
    access_token: str = Field(..., description="New JWT access token")
    token_type: str = Field("bearer", description="Token type, always 'bearer'")


class FcmTokenRequest(BaseModel):
    token: str = Field(..., description="Firebase Cloud Messaging device token")
    platform: str = Field(..., description="Device platform", examples=["android", "ios"])

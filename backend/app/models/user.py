from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import date


class UserProfile(BaseModel):
    id: int = Field(..., description="Internal user ID")
    email: Optional[str] = Field(None, description="User email (may be absent for Telegram-only accounts)")
    fullname: Optional[str] = Field(None, description="Full name")
    telegram_user_id: Optional[int] = Field(None, description="Linked Telegram user ID")
    ai_consent: bool = Field(..., description="Whether user has agreed to AI data processing")


class UpdateProfileRequest(BaseModel):
    fullname: Optional[str] = Field(None, description="New full name")
    email: Optional[EmailStr] = Field(None, description="New email address")


class AiConsentRequest(BaseModel):
    consent: bool = Field(..., description="true = user agrees to AI processing, false = revoke")


class NutritionProfileRequest(BaseModel):
    gender: Optional[str] = Field(None, description="Gender: 'male' / 'female'", examples=["male"])
    birth_date: Optional[date] = Field(None, description="Date of birth", examples=["1995-04-15"])
    height_cm: Optional[int] = Field(None, ge=100, le=250, description="Height in centimeters")
    weight_kg: Optional[float] = Field(None, gt=0, le=500, description="Current weight in kg")
    target_weight_kg: Optional[float] = Field(None, gt=0, le=500, description="Goal weight in kg")
    activity_level: Optional[int] = Field(
        None, ge=1, le=5,
        description="Activity level 1–5: 1=sedentary, 2=low, 3=moderate, 4=active, 5=very active",
    )
    goal: Optional[str] = Field(
        None,
        description="Primary goal",
        examples=["lose_weight", "gain_mass", "tone", "health"],
    )
    dietary_restrictions: Optional[str] = Field(
        None, description="Dietary restrictions or allergies (free text)"
    )


class TrainingProfileRequest(BaseModel):
    experience: Optional[str] = Field(
        None,
        description="Training experience level",
        examples=["beginner", "intermediate", "advanced"],
    )
    training_type: Optional[str] = Field(
        None,
        description="Preferred training type",
        examples=["strength", "cardio", "mixed"],
    )
    preferred_duration_min: Optional[int] = Field(
        None, ge=15, le=180, description="Preferred workout duration in minutes"
    )
    injuries: Optional[str] = Field(None, description="Known injuries or physical limitations")
    current_fat_pct: Optional[int] = Field(None, ge=1, le=60, description="Current body fat percentage")
    target_fat_pct: Optional[int] = Field(None, ge=1, le=60, description="Target body fat percentage")
    training_days: Optional[list[int]] = Field(
        None,
        description="Preferred training weekdays (0=Monday … 6=Sunday)",
        examples=[[0, 2, 4]],
    )


class CalculateWeightLossRequest(BaseModel):
    age: int = Field(..., ge=14, le=100, description="Age in years")
    weight: float = Field(..., gt=0, description="Current weight in kg")
    height: float = Field(..., gt=0, description="Height in cm (or meters, auto-detected)")
    current_fat_pct: int = Field(..., ge=1, le=60, description="Current body fat %")
    desired_fat_pct: int = Field(..., ge=1, le=60, description="Target body fat %")


# ── Response models ────────────────────────────────────────────────────────────

class NutritionProfileResponse(BaseModel):
    user_id: int = Field(..., description="User ID")
    gender: Optional[str] = Field(None, description="Gender")
    birth_date: Optional[date] = Field(None, description="Date of birth")
    height_cm: Optional[int] = Field(None, description="Height in centimeters")
    weight_kg: Optional[float] = Field(None, description="Current weight in kg")
    target_weight_kg: Optional[float] = Field(None, description="Goal weight in kg")
    activity_level: Optional[int] = Field(None, description="Activity level 1–5")
    goal: Optional[str] = Field(None, description="Primary fitness goal")
    dietary_restrictions: Optional[str] = Field(None, description="Dietary restrictions")


class TrainingProfileResponse(BaseModel):
    user_id: int = Field(..., description="User ID")
    experience: Optional[str] = Field(None, description="Experience level")
    training_type: Optional[str] = Field(None, description="Preferred training type")
    preferred_duration_min: Optional[int] = Field(None, description="Preferred workout duration in minutes")
    injuries: Optional[str] = Field(None, description="Known injuries or limitations")
    current_fat_pct: Optional[int] = Field(None, description="Current body fat %")
    target_fat_pct: Optional[int] = Field(None, description="Target body fat %")
    training_days: Optional[list[int]] = Field(None, description="Preferred training weekdays (0=Mon)")


class ActiveSubscriptionInfo(BaseModel):
    plan_name: Optional[str] = Field(None, description="Subscription plan name")
    end_date: Optional[str] = Field(None, description="Subscription expiry date (ISO 8601)")
    status: Optional[str] = Field(None, description="Subscription status: active / cancelled / expired")


class FullProfileResponse(BaseModel):
    user: UserProfile = Field(..., description="Basic user info")
    nutrition_profile: Optional[NutritionProfileResponse] = Field(None, description="Nutrition/health data")
    training_profile: Optional[TrainingProfileResponse] = Field(None, description="Fitness preferences")
    subscription: Optional[ActiveSubscriptionInfo] = Field(None, description="Active subscription, if any")


class DayProgressItem(BaseModel):
    date: str = Field(..., description="Calendar date (YYYY-MM-DD)")
    status: str = Field(..., description="Training status: 'completed' | 'pending' | 'none'")
    workout_name: Optional[str] = Field(None, description="Workout name for that day, if scheduled")


class WeeklyProgressResponse(BaseModel):
    week_start: str = Field(..., description="Monday of the current week (YYYY-MM-DD)")
    days: list[DayProgressItem] = Field(..., description="Training status for each day Mon–Sun")


class WeightLossDateResponse(BaseModel):
    estimated_date: Optional[str] = Field(None, description="Estimated date to reach target body fat (YYYY-MM-DD)")
    weeks_needed: Optional[float] = Field(None, description="Estimated weeks to reach the goal")
    daily_deficit_kcal: Optional[float] = Field(None, description="Required daily calorie deficit (kcal)")
    bmr: Optional[float] = Field(None, description="Basal Metabolic Rate (kcal/day)")
    tdee: Optional[float] = Field(None, description="Total Daily Energy Expenditure (kcal/day)")

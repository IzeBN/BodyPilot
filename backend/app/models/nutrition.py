from pydantic import BaseModel, Field
from typing import Optional, Literal
from datetime import date


# ─── Shared nutrient mixin ────────────────────────────────────────────────────

class _MicronutrientMixin(BaseModel):
    """All optional micronutrient / vitamin fields stored per actual portion."""
    fiber: Optional[float] = Field(None, ge=0, description="Dietary fiber (g)")
    sugar: Optional[float] = Field(None, ge=0, description="Sugar (g)")
    sugar_alcohols: Optional[float] = Field(None, ge=0, description="Sugar alcohols (g)")
    saturated_fat: Optional[float] = Field(None, ge=0, description="Saturated fat (g)")
    unsaturated_fat: Optional[float] = Field(None, ge=0, description="Unsaturated fat (g)")
    glycemic_index: Optional[int] = Field(None, ge=0, description="Glycemic index")
    # Minerals
    sodium_mg: Optional[float] = Field(None, ge=0, description="Sodium (mg)")
    calcium_mg: Optional[float] = Field(None, ge=0, description="Calcium (mg)")
    iron_mg: Optional[float] = Field(None, ge=0, description="Iron (mg)")
    potassium_mg: Optional[float] = Field(None, ge=0, description="Potassium (mg)")
    magnesium_mg: Optional[float] = Field(None, ge=0, description="Magnesium (mg)")
    phosphorus_mg: Optional[float] = Field(None, ge=0, description="Phosphorus (mg)")
    zinc_mg: Optional[float] = Field(None, ge=0, description="Zinc (mg)")
    selenium_mcg: Optional[float] = Field(None, ge=0, description="Selenium (mcg)")
    manganese_mg: Optional[float] = Field(None, ge=0, description="Manganese (mg)")
    copper_mg: Optional[float] = Field(None, ge=0, description="Copper (mg)")
    cholesterol_mg: Optional[float] = Field(None, ge=0, description="Cholesterol (mg)")
    # Vitamins
    vitamin_a_mcg: Optional[float] = Field(None, ge=0, description="Vitamin A (mcg)")
    vitamin_c_mg: Optional[float] = Field(None, ge=0, description="Vitamin C (mg)")
    vitamin_d_mcg: Optional[float] = Field(None, ge=0, description="Vitamin D (mcg)")
    vitamin_e_mg: Optional[float] = Field(None, ge=0, description="Vitamin E (mg)")
    vitamin_k_mcg: Optional[float] = Field(None, ge=0, description="Vitamin K (mcg)")
    vitamin_b1_mg: Optional[float] = Field(None, ge=0, description="Vitamin B1 / Thiamine (mg)")
    vitamin_b2_mg: Optional[float] = Field(None, ge=0, description="Vitamin B2 / Riboflavin (mg)")
    vitamin_b3_mg: Optional[float] = Field(None, ge=0, description="Vitamin B3 / Niacin (mg)")
    vitamin_b5_mg: Optional[float] = Field(None, ge=0, description="Vitamin B5 / Pantothenic acid (mg)")
    vitamin_b6_mg: Optional[float] = Field(None, ge=0, description="Vitamin B6 (mg)")
    vitamin_b7_mcg: Optional[float] = Field(None, ge=0, description="Vitamin B7 / Biotin (mcg)")
    vitamin_b9_mcg: Optional[float] = Field(None, ge=0, description="Vitamin B9 / Folate (mcg)")
    vitamin_b12_mcg: Optional[float] = Field(None, ge=0, description="Vitamin B12 (mcg)")


# ─── Request models ───────────────────────────────────────────────────────────

class AddMealRequest(_MicronutrientMixin):
    log_date: date = Field(..., description="Date the meal was consumed")
    meal_type: Literal["breakfast", "lunch", "dinner", "snack"] = Field(
        ..., description="Type of meal"
    )
    food_id: Optional[int] = Field(None, description="ID of a food item from the database (optional)")
    food_name: Optional[str] = Field(
        None, description="Custom food name when not from the database", examples=["Домашний борщ"]
    )
    food_name_en: Optional[str] = Field(None, description="English food name (for cache key)")
    amount_g: float = Field(..., gt=0, description="Amount consumed in grams")
    calories: float = Field(..., ge=0, description="Total calories (kcal)")
    protein: Optional[float] = Field(None, ge=0, description="Protein in grams")
    fat: Optional[float] = Field(None, ge=0, description="Fat in grams")
    carbs: Optional[float] = Field(None, ge=0, description="Carbohydrates in grams")
    source: Optional[str] = Field(None, description="Nutrient data source (local_db/claude/fatsecret)")
    source_url: Optional[str] = Field(None, description="URL of the nutrient data source")


class EditMealRequest(BaseModel):
    amount_g: Optional[float] = Field(None, gt=0, description="Updated amount in grams")
    calories: Optional[float] = Field(None, ge=0, description="Updated calories (kcal)")
    protein: Optional[float] = Field(None, ge=0, description="Updated protein in grams")
    fat: Optional[float] = Field(None, ge=0, description="Updated fat in grams")
    carbs: Optional[float] = Field(None, ge=0, description="Updated carbohydrates in grams")


class FoodSearchRequest(BaseModel):
    query: str = Field(..., min_length=1, description="Search term (name prefix or substring)")
    limit: int = Field(20, ge=1, le=100, description="Maximum number of results")


class NutritionGoalsRequest(BaseModel):
    calories: int = Field(..., ge=100, le=10000, description="Daily calorie goal (kcal)")
    protein_g: Optional[int] = Field(None, ge=0, description="Daily protein goal (g)")
    fat_g: Optional[int] = Field(None, ge=0, description="Daily fat goal (g)")
    carbs_g: Optional[int] = Field(None, ge=0, description="Daily carbohydrates goal (g)")
    water_ml: Optional[int] = Field(None, ge=0, description="Daily water intake goal (ml)")


class RecognizeTextRequest(BaseModel):
    text: str = Field(..., min_length=1, description="Free-text description of what was eaten")
    language: str = Field("ru", description="Language hint: 'ru' or 'en'")


# ─── Response models ──────────────────────────────────────────────────────────

class MealResponse(_MicronutrientMixin):
    id: int = Field(..., description="Meal entry ID")
    log_date: date = Field(..., description="Date of the meal")
    meal_type: str = Field(..., description="Meal type: breakfast / lunch / dinner / snack")
    food_id: Optional[int] = Field(None, description="Food DB item ID (null for custom entries)")
    food_name: Optional[str] = Field(None, description="Food name")
    food_name_en: Optional[str] = Field(None, description="English food name")
    amount_g: float = Field(..., description="Amount consumed in grams")
    calories: float = Field(..., description="Total calories (kcal)")
    protein: Optional[float] = Field(None, description="Protein (g)")
    fat: Optional[float] = Field(None, description="Fat (g)")
    carbs: Optional[float] = Field(None, description="Carbohydrates (g)")
    source: Optional[str] = Field(None, description="Nutrient data source")
    source_url: Optional[str] = Field(None, description="URL of nutrient data source")


class DailySummary(BaseModel):
    total_calories: float = Field(..., description="Total calories consumed (kcal)")
    total_protein: float = Field(..., description="Total protein (g)")
    total_fat: float = Field(..., description="Total fat (g)")
    total_carbs: float = Field(..., description="Total carbohydrates (g)")
    meal_count: int = Field(..., description="Number of meal entries for the day")


class MealListResponse(BaseModel):
    meals: list[MealResponse] = Field(..., description="All meal entries for the day")
    summary: DailySummary = Field(..., description="Aggregated daily nutrition totals")


class FoodItemResponse(BaseModel):
    id: int = Field(..., description="Food item ID")
    name: str = Field(..., description="Food name")
    name_en: Optional[str] = Field(None, description="English food name")
    calories_per_100g: float = Field(..., description="Calories per 100g (kcal)")
    protein_per_100g: Optional[float] = Field(None, description="Protein per 100g (g)")
    fat_per_100g: Optional[float] = Field(None, description="Fat per 100g (g)")
    carbs_per_100g: Optional[float] = Field(None, description="Carbohydrates per 100g (g)")
    fiber_per_100g: Optional[float] = Field(None, description="Fiber per 100g (g)")
    sugar_per_100g: Optional[float] = Field(None, description="Sugar per 100g (g)")
    barcode: Optional[str] = Field(None, description="EAN/UPC barcode")
    source_url: Optional[str] = Field(None, description="URL of nutrient data source")


class NutritionGoalsResponse(BaseModel):
    user_id: int = Field(..., description="User ID")
    calories: int = Field(..., description="Daily calorie goal (kcal)")
    protein_g: Optional[int] = Field(None, description="Daily protein goal (g)")
    fat_g: Optional[int] = Field(None, description="Daily fat goal (g)")
    carbs_g: Optional[int] = Field(None, description="Daily carbs goal (g)")
    water_ml: Optional[int] = Field(None, description="Daily water goal (ml)")
    valid_from: date = Field(..., description="Date from which these goals apply")


class DailyNutritionStat(BaseModel):
    log_date: date = Field(..., description="Day date")
    total_calories: float = Field(..., description="Total calories (kcal)")
    total_protein: float = Field(..., description="Total protein (g)")
    total_fat: float = Field(..., description="Total fat (g)")
    total_carbs: float = Field(..., description="Total carbohydrates (g)")


class NutritionStatsResponse(BaseModel):
    days: list[DailyNutritionStat] = Field(..., description="Per-day nutrition totals")


# ─── Recognition response models ─────────────────────────────────────────────

class RecognizedFoodItem(_MicronutrientMixin):
    name: str = Field(..., description="Food name (in user language)")
    name_en: str = Field(..., description="English name (used as cache/DB key)")
    weight_grams: float = Field(..., description="Estimated or specified portion weight (g)")
    calories: float = Field(..., description="Calories for this portion (kcal)")
    protein: float = Field(..., description="Protein for this portion (g)")
    fat: float = Field(..., description="Fat for this portion (g)")
    carbs: float = Field(..., description="Carbohydrates for this portion (g)")
    source: Optional[str] = Field(None, description="Nutrient data source (local_db/claude/fatsecret)")
    source_url: Optional[str] = Field(None, description="URL of nutrient data source")


class RecognitionTotal(BaseModel):
    calories: float = Field(..., description="Total calories (kcal)")
    protein: float = Field(..., description="Total protein (g)")
    fat: float = Field(..., description="Total fat (g)")
    carbs: float = Field(..., description="Total carbohydrates (g)")


class RecognizeResponse(BaseModel):
    items: list[RecognizedFoodItem] = Field(..., description="Recognised food items with nutrients")
    total: RecognitionTotal = Field(..., description="Sum of nutrients across all items")


class RecognizeVoiceResponse(RecognizeResponse):
    transcript: str = Field(..., description="Transcribed text from the audio")

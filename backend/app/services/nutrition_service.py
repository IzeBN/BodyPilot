from datetime import date
from fastapi import HTTPException

from app.repositories.nutrition import NutritionRepository

_MICRO_FIELDS = (
    "food_name_en", "fiber", "sugar", "sugar_alcohols", "saturated_fat", "unsaturated_fat",
    "glycemic_index", "sodium_mg", "calcium_mg", "iron_mg", "potassium_mg", "magnesium_mg",
    "phosphorus_mg", "zinc_mg", "selenium_mcg", "manganese_mg", "copper_mg", "cholesterol_mg",
    "vitamin_a_mcg", "vitamin_c_mg", "vitamin_d_mcg", "vitamin_e_mg", "vitamin_k_mcg",
    "vitamin_b1_mg", "vitamin_b2_mg", "vitamin_b3_mg", "vitamin_b5_mg", "vitamin_b6_mg",
    "vitamin_b7_mcg", "vitamin_b9_mcg", "vitamin_b12_mcg", "source", "source_url",
)


class NutritionService:
    def __init__(self, repo: NutritionRepository) -> None:
        self._repo = repo

    async def add_meal(self, user_id: int, data: dict) -> dict:
        micro = {k: data.get(k) for k in _MICRO_FIELDS}
        row = await self._repo.add_meal(
            user_id,
            data["log_date"], data["meal_type"],
            data.get("food_id"), data.get("food_name"),
            data["amount_g"], data["calories"],
            data.get("protein"), data.get("fat"), data.get("carbs"),
            **micro,
        )
        return dict(row)

    async def get_meals(self, user_id: int, log_date: date) -> dict:
        rows = await self._repo.get_meals_by_date(user_id, log_date)
        summary = await self._repo.get_daily_summary(user_id, log_date)
        return {
            "meals": [dict(r) for r in rows],
            "summary": dict(summary) if summary else {},
        }

    async def edit_meal(self, meal_id: int, user_id: int, fields: dict) -> None:
        meal = await self._repo.get_meal_by_id(meal_id, user_id)
        if not meal:
            raise HTTPException(404, detail="Meal not found")
        if fields:
            await self._repo.update_meal(meal_id, user_id, **fields)

    async def delete_meal(self, meal_id: int, user_id: int) -> None:
        meal = await self._repo.get_meal_by_id(meal_id, user_id)
        if not meal:
            raise HTTPException(404, detail="Meal not found")
        await self._repo.delete_meal(meal_id, user_id)

    async def search_foods(self, query: str, limit: int) -> list[dict]:
        rows = await self._repo.search_foods(query, limit)
        return [dict(r) for r in rows]

    async def get_food_by_barcode(self, barcode: str) -> dict:
        row = await self._repo.get_food_by_barcode(barcode)
        if not row:
            raise HTTPException(404, detail="Food not found")
        return dict(row)

    async def upsert_goals(self, user_id: int, data: dict) -> None:
        await self._repo.upsert_nutrition_goals(
            user_id,
            data["calories"], data.get("protein_g"),
            data.get("fat_g"), data.get("carbs_g"), data.get("water_ml"),
        )

    async def get_goals(self, user_id: int) -> dict:
        row = await self._repo.get_nutrition_goals(user_id)
        if row:
            return dict(row)
        return {
            "user_id": user_id,
            "calories": 2000,
            "protein_g": None,
            "fat_g": None,
            "carbs_g": None,
            "water_ml": None,
            "valid_from": date.today(),
        }

    async def get_stats(self, user_id: int, date_from: date, date_to: date) -> list[dict]:
        if date_from > date_to:
            raise HTTPException(400, detail="date_from must be <= date_to")
        rows = await self._repo.get_stats_range(user_id, date_from, date_to)
        return [dict(r) for r in rows]

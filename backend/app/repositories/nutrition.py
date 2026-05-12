import asyncpg
from datetime import date
from app.repositories.base import BaseRepository

_VITAMIN_COLS = (
    "fiber", "sugar", "sugar_alcohols", "saturated_fat", "unsaturated_fat", "glycemic_index",
    "sodium_mg", "calcium_mg", "iron_mg", "potassium_mg", "magnesium_mg", "phosphorus_mg",
    "zinc_mg", "selenium_mcg", "manganese_mg", "copper_mg", "cholesterol_mg",
    "vitamin_a_mcg", "vitamin_c_mg", "vitamin_d_mcg", "vitamin_e_mg", "vitamin_k_mcg",
    "vitamin_b1_mg", "vitamin_b2_mg", "vitamin_b3_mg", "vitamin_b5_mg", "vitamin_b6_mg",
    "vitamin_b7_mcg", "vitamin_b9_mcg", "vitamin_b12_mcg",
)


class NutritionRepository(BaseRepository):

    async def add_meal(
        self,
        user_id: int,
        log_date: date,
        meal_type: str,
        food_id: "int | None",
        food_name: "str | None",
        amount_g: float,
        calories: float,
        protein: "float | None",
        fat: "float | None",
        carbs: "float | None",
        *,
        food_name_en: "str | None" = None,
        fiber: "float | None" = None,
        sugar: "float | None" = None,
        sugar_alcohols: "float | None" = None,
        saturated_fat: "float | None" = None,
        unsaturated_fat: "float | None" = None,
        glycemic_index: "int | None" = None,
        sodium_mg: "float | None" = None,
        calcium_mg: "float | None" = None,
        iron_mg: "float | None" = None,
        potassium_mg: "float | None" = None,
        magnesium_mg: "float | None" = None,
        phosphorus_mg: "float | None" = None,
        zinc_mg: "float | None" = None,
        selenium_mcg: "float | None" = None,
        manganese_mg: "float | None" = None,
        copper_mg: "float | None" = None,
        cholesterol_mg: "float | None" = None,
        vitamin_a_mcg: "float | None" = None,
        vitamin_c_mg: "float | None" = None,
        vitamin_d_mcg: "float | None" = None,
        vitamin_e_mg: "float | None" = None,
        vitamin_k_mcg: "float | None" = None,
        vitamin_b1_mg: "float | None" = None,
        vitamin_b2_mg: "float | None" = None,
        vitamin_b3_mg: "float | None" = None,
        vitamin_b5_mg: "float | None" = None,
        vitamin_b6_mg: "float | None" = None,
        vitamin_b7_mcg: "float | None" = None,
        vitamin_b9_mcg: "float | None" = None,
        vitamin_b12_mcg: "float | None" = None,
        source: "str | None" = None,
        source_url: "str | None" = None,
    ) -> int:
        extra_vals = (
            food_name_en,
            fiber, sugar, sugar_alcohols, saturated_fat, unsaturated_fat, glycemic_index,
            sodium_mg, calcium_mg, iron_mg, potassium_mg, magnesium_mg, phosphorus_mg,
            zinc_mg, selenium_mcg, manganese_mg, copper_mg, cholesterol_mg,
            vitamin_a_mcg, vitamin_c_mg, vitamin_d_mcg, vitamin_e_mg, vitamin_k_mcg,
            vitamin_b1_mg, vitamin_b2_mg, vitamin_b3_mg, vitamin_b5_mg, vitamin_b6_mg,
            vitamin_b7_mcg, vitamin_b9_mcg, vitamin_b12_mcg,
            source, source_url,
        )
        n = len(extra_vals)
        placeholders = ", ".join(f"${i}" for i in range(12, 12 + n))
        extra_cols = (
            "food_name_en, fiber, sugar, sugar_alcohols, saturated_fat, unsaturated_fat, glycemic_index, "
            "sodium_mg, calcium_mg, iron_mg, potassium_mg, magnesium_mg, phosphorus_mg, "
            "zinc_mg, selenium_mcg, manganese_mg, copper_mg, cholesterol_mg, "
            "vitamin_a_mcg, vitamin_c_mg, vitamin_d_mcg, vitamin_e_mg, vitamin_k_mcg, "
            "vitamin_b1_mg, vitamin_b2_mg, vitamin_b3_mg, vitamin_b5_mg, vitamin_b6_mg, "
            "vitamin_b7_mcg, vitamin_b9_mcg, vitamin_b12_mcg, source, source_url"
        )
        async with self.pool.acquire() as conn:
            return await conn.fetchval(
                f"""INSERT INTO meal_logs
                       (user_id, log_date, meal_type, food_id, food_name, amount_g,
                        calories, protein, fat, carbs, net_carbs, {extra_cols})
                   VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,{placeholders})
                   RETURNING id""",
                user_id, log_date, meal_type, food_id, food_name, amount_g,
                calories, protein, fat, carbs, None,
                *extra_vals,
            )

    async def get_meals_by_date(self, user_id: int, log_date: date) -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            return await conn.fetch(
                """SELECT ml.*, f.name food_db_name, f.barcode
                   FROM meal_logs ml
                   LEFT JOIN foods f ON f.id = ml.food_id
                   WHERE ml.user_id = $1 AND ml.log_date = $2
                   ORDER BY ml.created_at""",
                user_id, log_date,
            )

    async def get_meal_by_id(self, meal_id: int, user_id: int) -> "asyncpg.Record | None":
        async with self.pool.acquire() as conn:
            return await conn.fetchrow(
                "SELECT * FROM meal_logs WHERE id = $1 AND user_id = $2",
                meal_id, user_id,
            )

    async def update_meal(self, meal_id: int, user_id: int, **fields) -> None:
        if not fields:
            return
        sets = ", ".join(f"{k} = ${i+3}" for i, k in enumerate(fields))
        async with self.pool.acquire() as conn:
            await conn.execute(
                f"UPDATE meal_logs SET {sets} WHERE id = $1 AND user_id = $2",
                meal_id, user_id, *fields.values(),
            )

    async def delete_meal(self, meal_id: int, user_id: int) -> None:
        async with self.pool.acquire() as conn:
            await conn.execute(
                "DELETE FROM meal_logs WHERE id = $1 AND user_id = $2",
                meal_id, user_id,
            )

    async def get_daily_summary(self, user_id: int, log_date: date) -> "asyncpg.Record | None":
        async with self.pool.acquire() as conn:
            return await conn.fetchrow(
                """SELECT
                       COALESCE(SUM(calories), 0) total_calories,
                       COALESCE(SUM(protein), 0) total_protein,
                       COALESCE(SUM(fat), 0) total_fat,
                       COALESCE(SUM(carbs), 0) total_carbs,
                       COUNT(*) meal_count
                   FROM meal_logs WHERE user_id = $1 AND log_date = $2""",
                user_id, log_date,
            )

    async def search_foods(self, query: str, limit: int = 20) -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            return await conn.fetch(
                """SELECT id, name, name_en,
                          calories    AS calories_per_100g,
                          protein     AS protein_per_100g,
                          fat         AS fat_per_100g,
                          carbs       AS carbs_per_100g,
                          fiber       AS fiber_per_100g,
                          sugar       AS sugar_per_100g,
                          barcode, source_url
                   FROM foods
                   WHERE name ILIKE $1 OR name_en ILIKE $1
                   ORDER BY name LIMIT $2""",
                f"%{query}%", limit,
            )

    async def get_food_by_barcode(self, barcode: str) -> "asyncpg.Record | None":
        async with self.pool.acquire() as conn:
            return await conn.fetchrow(
                """SELECT id, name, name_en,
                          calories AS calories_per_100g,
                          protein  AS protein_per_100g,
                          fat      AS fat_per_100g,
                          carbs    AS carbs_per_100g,
                          fiber    AS fiber_per_100g,
                          sugar    AS sugar_per_100g,
                          barcode, source_url
                   FROM foods WHERE barcode = $1""",
                barcode,
            )

    async def get_food_by_id(self, food_id: int) -> "asyncpg.Record | None":
        async with self.pool.acquire() as conn:
            return await conn.fetchrow(
                "SELECT * FROM foods WHERE id = $1", food_id
            )

    async def upsert_nutrition_goals(
        self, user_id: int, calories: int, protein_g: "int | None",
        fat_g: "int | None", carbs_g: "int | None", water_ml: "int | None",
    ) -> None:
        async with self.pool.acquire() as conn:
            await conn.execute(
                """INSERT INTO nutrition_goals (user_id, calories, protein_g, fat_g, carbs_g, water_ml)
                   VALUES ($1, $2, $3, $4, $5, $6)
                   ON CONFLICT (user_id, valid_from)
                   DO UPDATE SET calories  = EXCLUDED.calories,
                                 protein_g = EXCLUDED.protein_g,
                                 fat_g     = EXCLUDED.fat_g,
                                 carbs_g   = EXCLUDED.carbs_g,
                                 water_ml  = EXCLUDED.water_ml""",
                user_id, calories, protein_g, fat_g, carbs_g, water_ml,
            )

    async def get_nutrition_goals(self, user_id: int) -> "asyncpg.Record | None":
        async with self.pool.acquire() as conn:
            return await conn.fetchrow(
                """SELECT * FROM nutrition_goals WHERE user_id = $1
                   ORDER BY valid_from DESC LIMIT 1""",
                user_id,
            )

    async def get_stats_range(self, user_id: int, date_from: date, date_to: date) -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            return await conn.fetch(
                """SELECT log_date,
                       SUM(calories) total_calories,
                       SUM(protein)  total_protein,
                       SUM(fat)      total_fat,
                       SUM(carbs)    total_carbs
                   FROM meal_logs
                   WHERE user_id = $1 AND log_date BETWEEN $2 AND $3
                   GROUP BY log_date ORDER BY log_date""",
                user_id, date_from, date_to,
            )

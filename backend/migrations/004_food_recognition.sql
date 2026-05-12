-- ─── Migration 004: Food recognition & full micronutrient support ─────────────
-- Extends foods and meal_logs with all macro/micro nutrient + vitamin columns.
-- Adds food_nutrients_cache for AI nutrient lookup results.

-- ─── Extend foods table ───────────────────────────────────────────────────────

ALTER TABLE foods
    ADD COLUMN IF NOT EXISTS name_en          VARCHAR(255),
    ADD COLUMN IF NOT EXISTS sugar_alcohols   NUMERIC(6,2),
    ADD COLUMN IF NOT EXISTS net_carbs        NUMERIC(6,2),
    ADD COLUMN IF NOT EXISTS saturated_fat    NUMERIC(6,2),
    ADD COLUMN IF NOT EXISTS unsaturated_fat  NUMERIC(6,2),
    ADD COLUMN IF NOT EXISTS glycemic_index   SMALLINT,
    -- Minerals
    ADD COLUMN IF NOT EXISTS sodium_mg        NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS calcium_mg       NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS iron_mg          NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS potassium_mg     NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS magnesium_mg     NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS phosphorus_mg    NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS zinc_mg          NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS selenium_mcg     NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS manganese_mg     NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS copper_mg        NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS cholesterol_mg   NUMERIC(8,3),
    -- Vitamins
    ADD COLUMN IF NOT EXISTS vitamin_a_mcg    NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_c_mg     NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_d_mcg    NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_e_mg     NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_k_mcg    NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_b1_mg    NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_b2_mg    NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_b3_mg    NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_b5_mg    NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_b6_mg    NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_b7_mcg   NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_b9_mcg   NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_b12_mcg  NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS source_url       TEXT;

CREATE INDEX IF NOT EXISTS idx_foods_name_en ON foods(name_en);

-- ─── Extend meal_logs table ───────────────────────────────────────────────────

ALTER TABLE meal_logs
    ADD COLUMN IF NOT EXISTS food_name_en     VARCHAR(255),
    ADD COLUMN IF NOT EXISTS fiber            NUMERIC(6,2),
    ADD COLUMN IF NOT EXISTS sugar            NUMERIC(6,2),
    ADD COLUMN IF NOT EXISTS sugar_alcohols   NUMERIC(6,2),
    ADD COLUMN IF NOT EXISTS net_carbs        NUMERIC(6,2),
    ADD COLUMN IF NOT EXISTS saturated_fat    NUMERIC(6,2),
    ADD COLUMN IF NOT EXISTS unsaturated_fat  NUMERIC(6,2),
    ADD COLUMN IF NOT EXISTS glycemic_index   SMALLINT,
    -- Minerals
    ADD COLUMN IF NOT EXISTS sodium_mg        NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS calcium_mg       NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS iron_mg          NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS potassium_mg     NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS magnesium_mg     NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS phosphorus_mg    NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS zinc_mg          NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS selenium_mcg     NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS manganese_mg     NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS copper_mg        NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS cholesterol_mg   NUMERIC(8,3),
    -- Vitamins
    ADD COLUMN IF NOT EXISTS vitamin_a_mcg    NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_c_mg     NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_d_mcg    NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_e_mg     NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_k_mcg    NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_b1_mg    NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_b2_mg    NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_b3_mg    NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_b5_mg    NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_b6_mg    NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_b7_mcg   NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_b9_mcg   NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS vitamin_b12_mcg  NUMERIC(8,3),
    ADD COLUMN IF NOT EXISTS source           VARCHAR(50),
    ADD COLUMN IF NOT EXISTS source_url       TEXT;

-- ─── Food nutrients cache (AI / FatSecret enrichment results) ────────────────

CREATE TABLE IF NOT EXISTS food_nutrients_cache (
    id               SERIAL PRIMARY KEY,
    name_en          VARCHAR(255) NOT NULL UNIQUE,
    calories         NUMERIC(7,2),
    protein          NUMERIC(6,2),
    fat              NUMERIC(6,2),
    carbs            NUMERIC(6,2),
    fiber            NUMERIC(6,2),
    sugar            NUMERIC(6,2),
    sugar_alcohols   NUMERIC(6,2),
    saturated_fat    NUMERIC(6,2),
    unsaturated_fat  NUMERIC(6,2),
    glycemic_index   SMALLINT,
    sodium_mg        NUMERIC(8,3),
    calcium_mg       NUMERIC(8,3),
    iron_mg          NUMERIC(8,3),
    potassium_mg     NUMERIC(8,3),
    magnesium_mg     NUMERIC(8,3),
    phosphorus_mg    NUMERIC(8,3),
    zinc_mg          NUMERIC(8,3),
    selenium_mcg     NUMERIC(8,3),
    manganese_mg     NUMERIC(8,3),
    copper_mg        NUMERIC(8,3),
    cholesterol_mg   NUMERIC(8,3),
    vitamin_a_mcg    NUMERIC(8,3),
    vitamin_c_mg     NUMERIC(8,3),
    vitamin_d_mcg    NUMERIC(8,3),
    vitamin_e_mg     NUMERIC(8,3),
    vitamin_k_mcg    NUMERIC(8,3),
    vitamin_b1_mg    NUMERIC(8,3),
    vitamin_b2_mg    NUMERIC(8,3),
    vitamin_b3_mg    NUMERIC(8,3),
    vitamin_b5_mg    NUMERIC(8,3),
    vitamin_b6_mg    NUMERIC(8,3),
    vitamin_b7_mcg   NUMERIC(8,3),
    vitamin_b9_mcg   NUMERIC(8,3),
    vitamin_b12_mcg  NUMERIC(8,3),
    source           VARCHAR(50),
    source_url       TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_food_cache_name_en ON food_nutrients_cache(name_en);

"""
Import FitnesBot exercise database into the unified backend.

Data sources (relative to FITNESBOT_DIR):
  to_translate/_parsed.json                  — Russian base data (exercises, equipment, details)
  to_translate/translations_exercizes.json   — English exercise translations
  to_translate/translations_equipments.json  — English equipment-category translations
  to_translate/translations_equipment_details.json — English equipment-item translations

Usage:
    python scripts/import_exercises.py \
        --dsn "postgresql://user:pass@localhost:5432/fitkeep" \
        --src "C:/Data/projects/FitnesBot"

    # Or via env variables:
    DB_DSN="..." FITNESBOT_DIR="..." python scripts/import_exercises.py
"""

import argparse
import asyncio
import json
import os
import sys
from pathlib import Path


async def run(dsn: str, fitnesbot_dir: str) -> None:
    import asyncpg

    base = Path(fitnesbot_dir) / "to_translate"

    # ── Load source files ─────────────────────────────────────────────────────
    with open(base / "_parsed.json", encoding="utf-8") as f:
        parsed = json.load(f)

    with open(base / "translations_exercizes.json", encoding="utf-8") as f:
        ex_en_list = json.load(f)

    with open(base / "translations_equipments.json", encoding="utf-8") as f:
        eq_en_list = json.load(f)

    with open(base / "translations_equipment_details.json", encoding="utf-8") as f:
        det_en_list = json.load(f)

    exercises_ru: list[dict] = parsed["exercizes"]       # 260 items: id, title, muscle_group, doc
    equipments_ru: list[dict] = parsed["equipments"]     # 4 items: id, title
    details_ru: list[dict] = parsed["details"]           # 90 items: id, name

    # en lookup maps
    ex_en: dict[int, dict] = {t["entity_id"]: t["fields"] for t in ex_en_list}
    eq_en: dict[int, dict] = {t["entity_id"]: t["fields"] for t in eq_en_list}
    det_en: dict[int, dict] = {t["entity_id"]: t["fields"] for t in det_en_list}

    # ── Connect ───────────────────────────────────────────────────────────────
    conn = await asyncpg.connect(dsn)
    print(f"Connected to database.")

    try:
        async with conn.transaction():
            # ── 1. Exercises ──────────────────────────────────────────────────
            print(f"\n[1/4] Importing {len(exercises_ru)} exercises …")

            upserted_ex = 0
            trans_ex = 0

            for ex in exercises_ru:
                ex_id: int = ex["id"]
                title_ru: str = ex.get("title") or ""
                muscle_ru: str = ex.get("muscle_group") or ""
                doc_ru: str = ex.get("doc") or ""

                en = ex_en.get(ex_id, {})
                title_en: str = en.get("title") or ""
                muscle_en: str = en.get("muscle_group") or ""
                doc_en: str = en.get("documentation") or ""

                # Upsert exercise row (preserve original IDs with OVERRIDING SYSTEM VALUE)
                await conn.execute(
                    """INSERT INTO exercises (id, title, muscle_group, documentation)
                       OVERRIDING SYSTEM VALUE
                       VALUES ($1, $2, $3, $4)
                       ON CONFLICT (id) DO UPDATE SET
                           title         = EXCLUDED.title,
                           muscle_group  = EXCLUDED.muscle_group,
                           documentation = EXCLUDED.documentation""",
                    ex_id, title_ru, muscle_ru, doc_ru,
                )
                upserted_ex += 1

                # Translations: RU
                for field, value in (
                    ("title", title_ru),
                    ("muscle_group", muscle_ru),
                    ("documentation", doc_ru),
                ):
                    if value:
                        await conn.execute(
                            """INSERT INTO translations (entity_type, entity_id, lang, field, value)
                               VALUES ('exercises', $1, 'ru', $2, $3)
                               ON CONFLICT (entity_type, entity_id, lang, field) DO UPDATE SET value = EXCLUDED.value""",
                            ex_id, field, value,
                        )
                        trans_ex += 1

                # Translations: EN
                for field, value in (
                    ("title", title_en),
                    ("muscle_group", muscle_en),
                    ("documentation", doc_en),
                ):
                    if value:
                        await conn.execute(
                            """INSERT INTO translations (entity_type, entity_id, lang, field, value)
                               VALUES ('exercises', $1, 'en', $2, $3)
                               ON CONFLICT (entity_type, entity_id, lang, field) DO UPDATE SET value = EXCLUDED.value""",
                            ex_id, field, value,
                        )
                        trans_ex += 1

            # Reset the exercises_id_seq so future auto-inserts don't collide
            await conn.execute(
                "SELECT setval('exercises_id_seq', (SELECT MAX(id) FROM exercises))"
            )

            print(f"    ✓ {upserted_ex} exercises upserted, {trans_ex} translation rows upserted")

            # ── 2. Equipment categories ───────────────────────────────────────
            print(f"\n[2/4] Importing {len(equipments_ru)} equipment categories …")

            upserted_eq = 0
            trans_eq = 0

            for eq in equipments_ru:
                eq_id: int = eq["id"]
                title_ru = eq.get("title") or ""
                title_en = eq_en.get(eq_id, {}).get("title") or ""

                await conn.execute(
                    """INSERT INTO equipment_categories (id, title)
                       OVERRIDING SYSTEM VALUE
                       VALUES ($1, $2)
                       ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title""",
                    eq_id, title_ru,
                )
                upserted_eq += 1

                for lang, value in (("ru", title_ru), ("en", title_en)):
                    if value:
                        await conn.execute(
                            """INSERT INTO translations (entity_type, entity_id, lang, field, value)
                               VALUES ('equipment_categories', $1, $2, 'title', $3)
                               ON CONFLICT (entity_type, entity_id, lang, field) DO UPDATE SET value = EXCLUDED.value""",
                            eq_id, lang, value,
                        )
                        trans_eq += 1

            await conn.execute(
                "SELECT setval('equipment_categories_id_seq', (SELECT MAX(id) FROM equipment_categories))"
            )
            print(f"    ✓ {upserted_eq} categories upserted, {trans_eq} translation rows upserted")

            # ── 3. Equipment items (details) ──────────────────────────────────
            # FitnesBot "details" map to equipment_items.
            # They are individual pieces of equipment (скамья, гантели, тренажеры…).
            # We assign them to category 1 (Инвентарь) by default since FitnesBot
            # didn't store an explicit category_id per detail.
            # Callers can remap categories in the DB admin afterwards.

            print(f"\n[3/4] Importing {len(details_ru)} equipment items …")

            # Determine per-detail category based on name heuristic
            MACHINES_KEYWORDS = ("тренажер", "блок", "кросс", "кабель")
            BARBELL_KEYWORDS = ("гриф", "штанга", "блин")
            DUMBBELL_KEYWORDS = ("гантел",)

            def _guess_category(name: str) -> int:
                nl = name.lower()
                if any(k in nl for k in MACHINES_KEYWORDS):
                    return 2  # Тренажеры
                if any(k in nl for k in BARBELL_KEYWORDS):
                    return 3  # Штанги
                if any(k in nl for k in DUMBBELL_KEYWORDS):
                    return 4  # Гантели
                return 1  # Инвентарь

            upserted_det = 0
            trans_det = 0

            for det in details_ru:
                det_id: int = det["id"]
                name_ru: str = det.get("name") or ""
                name_en: str = det_en.get(det_id, {}).get("name") or ""
                cat_id = _guess_category(name_ru)

                await conn.execute(
                    """INSERT INTO equipment_items (id, category_id, title)
                       OVERRIDING SYSTEM VALUE
                       VALUES ($1, $2, $3)
                       ON CONFLICT (id) DO UPDATE SET
                           category_id = EXCLUDED.category_id,
                           title       = EXCLUDED.title""",
                    det_id, cat_id, name_ru,
                )
                upserted_det += 1

                for lang, value in (("ru", name_ru), ("en", name_en)):
                    if value:
                        await conn.execute(
                            """INSERT INTO translations (entity_type, entity_id, lang, field, value)
                               VALUES ('equipment_items', $1, $2, 'title', $3)
                               ON CONFLICT (entity_type, entity_id, lang, field) DO UPDATE SET value = EXCLUDED.value""",
                            det_id, lang, value,
                        )
                        trans_det += 1

            await conn.execute(
                "SELECT setval('equipment_items_id_seq', (SELECT MAX(id) FROM equipment_items))"
            )
            print(f"    ✓ {upserted_det} items upserted, {trans_det} translation rows upserted")

            # ── 4. Summary ────────────────────────────────────────────────────
            total_trans = await conn.fetchval("SELECT COUNT(*) FROM translations")
            total_ex = await conn.fetchval("SELECT COUNT(*) FROM exercises")
            total_eq_cat = await conn.fetchval("SELECT COUNT(*) FROM equipment_categories")
            total_eq_items = await conn.fetchval("SELECT COUNT(*) FROM equipment_items")

            print(f"\n[4/4] Done.")
            print(f"    exercises:            {total_ex}")
            print(f"    equipment_categories: {total_eq_cat}")
            print(f"    equipment_items:      {total_eq_items}")
            print(f"    translations total:   {total_trans}")

    finally:
        await conn.close()


def main() -> None:
    parser = argparse.ArgumentParser(description="Import FitnesBot exercises into unified backend DB")
    parser.add_argument(
        "--dsn",
        default=os.environ.get("DB_DSN", ""),
        help="PostgreSQL DSN (or set DB_DSN env var)",
    )
    parser.add_argument(
        "--src",
        default=os.environ.get("FITNESBOT_DIR", str(Path(__file__).parent.parent.parent / "FitnesBot")),
        help="Path to the FitnesBot project root (or set FITNESBOT_DIR env var)",
    )
    args = parser.parse_args()

    if not args.dsn:
        print("ERROR: --dsn or DB_DSN env var required", file=sys.stderr)
        sys.exit(1)

    if not Path(args.src).exists():
        print(f"ERROR: FitnesBot dir not found: {args.src}", file=sys.stderr)
        sys.exit(1)

    asyncio.run(run(args.dsn, args.src))


if __name__ == "__main__":
    main()

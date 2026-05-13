"""
Migrate equipment and exercise data directly from the FitnesBot PostgreSQL database
into the unified KayFit_Fitkeep backend database.

What is migrated:
  - equipment_categories  (FitnesBot: equipments)
  - equipment_items       (FitnesBot: equipment_details)
  - equipment_options     (FitnesBot: equipment_options)
  - exercises             (FitnesBot: exercizes + files for photo/video URLs)
  - alternative_exercises (FitnesBot: alternative_exercizes)
  - exercise_defaults     (FitnesBot: exercize_default_parameters)
  - duration_exercizes    (FitnesBot: duration_exercizes)
  - translations          (FitnesBot: translations — exercises + equipment rows)

Original IDs are preserved via OVERRIDING SYSTEM VALUE so all FK relations
inside the target DB stay consistent.

Usage:
    python scripts/migrate_from_fitnesbot_db.py

    # Override target DSN:
    TARGET_DB_DSN="postgresql://..." python scripts/migrate_from_fitnesbot_db.py

    # Dry run (read source only, print counts, no writes):
    python scripts/migrate_from_fitnesbot_db.py --dry-run
"""

import argparse
import asyncio
import os
import sys

# ── Connection strings ────────────────────────────────────────────────────────
# Source: FitnesBot production DB (from FitnesBot/.env)
SOURCE_DSN = "postgresql://izeb:eT,jmikBsDnP5n@103.74.94.96:5432/main"

# Target: KayFit_Fitkeep backend DB
# Override via TARGET_DB_DSN env var or --target-dsn flag.
DEFAULT_TARGET_DSN = "postgresql://kayfit:kayfit_secret@localhost:5432/kayfit_fitkeep"


# ─────────────────────────────────────────────────────────────────────────────

async def run(source_dsn: str, target_dsn: str, dry_run: bool) -> None:
    import asyncpg

    print(f"Connecting to source (FitnesBot):  {_safe_dsn(source_dsn)}")
    src = await asyncpg.connect(source_dsn)

    if not dry_run:
        print(f"Connecting to target (KayFit):     {_safe_dsn(target_dsn)}")
        dst = await asyncpg.connect(target_dsn)
    else:
        dst = None
        print("DRY RUN — nothing will be written to the target DB.\n")

    try:
        # ── 1. Equipment categories (equipments) ──────────────────────────────
        print("\n[1/7] Equipment categories (equipments) …")
        rows = await src.fetch("""
            SELECT e.id, e.title, f.file_url AS photo_url
            FROM equipments e
            LEFT JOIN files f ON f.file_id = e.title_photo
        """)
        print(f"      {len(rows)} rows found")
        if not dry_run:
            async with dst.transaction():
                for r in rows:
                    await dst.execute("""
                        INSERT INTO equipment_categories (id, title, photo_url)
                        OVERRIDING SYSTEM VALUE
                        VALUES ($1, $2, $3)
                        ON CONFLICT (id) DO UPDATE SET
                            title     = EXCLUDED.title,
                            photo_url = EXCLUDED.photo_url
                    """, r["id"], r["title"], r["photo_url"])
                await dst.execute(
                    "SELECT setval('equipment_categories_id_seq', "
                    "(SELECT COALESCE(MAX(id), 1) FROM equipment_categories))"
                )
            print(f"      OK — {len(rows)} upserted")

        # ── 2. Equipment items (equipment_details) ────────────────────────────
        print("\n[2/7] Equipment items (equipment_details) …")
        rows = await src.fetch("""
            SELECT ed.id, ed.equipment_id AS category_id, ed.name AS title,
                   f.file_url AS photo_url
            FROM equipment_details ed
            LEFT JOIN files f ON f.file_id = ed.title_photo
        """)
        print(f"      {len(rows)} rows found")
        if not dry_run:
            async with dst.transaction():
                for r in rows:
                    await dst.execute("""
                        INSERT INTO equipment_items (id, category_id, title, photo_url)
                        OVERRIDING SYSTEM VALUE
                        VALUES ($1, $2, $3, $4)
                        ON CONFLICT (id) DO UPDATE SET
                            category_id = EXCLUDED.category_id,
                            title       = EXCLUDED.title,
                            photo_url   = EXCLUDED.photo_url
                    """, r["id"], r["category_id"], r["title"], r["photo_url"])
                await dst.execute(
                    "SELECT setval('equipment_items_id_seq', "
                    "(SELECT COALESCE(MAX(id), 1) FROM equipment_items))"
                )
            print(f"      OK — {len(rows)} upserted")

        # ── 3. Equipment options ──────────────────────────────────────────────
        # FitnesBot: equipment_options(id, equipment_id, detail_id, value)
        # Target:    equipment_options(id, item_id, title)
        # item_id maps to detail_id (the equipment_items FK)
        print("\n[3/7] Equipment options …")
        rows = await src.fetch("""
            SELECT id, detail_id AS item_id, value AS title
            FROM equipment_options
            WHERE detail_id IS NOT NULL
        """)
        print(f"      {len(rows)} rows found")
        if not dry_run:
            async with dst.transaction():
                for r in rows:
                    await dst.execute("""
                        INSERT INTO equipment_options (id, item_id, title)
                        OVERRIDING SYSTEM VALUE
                        VALUES ($1, $2, $3)
                        ON CONFLICT (id) DO UPDATE SET
                            item_id = EXCLUDED.item_id,
                            title   = EXCLUDED.title
                    """, r["id"], r["item_id"], r["title"])
                await dst.execute(
                    "SELECT setval('equipment_options_id_seq', "
                    "(SELECT COALESCE(MAX(id), 1) FROM equipment_options))"
                )
            print(f"      OK — {len(rows)} upserted")

        # ── 4. Exercises ──────────────────────────────────────────────────────
        # progression column may be NULL if not yet populated in FitnesBot
        print("\n[4/7] Exercises (exercizes) …")
        rows = await src.fetch("""
            SELECT
                e.id,
                e.title,
                e.description,
                fph.file_url  AS photo_url,
                fvid.file_url AS video_url,
                e.muscle_group,
                e.documentation,
                e.progression::text AS progression_level
            FROM exercizes e
            LEFT JOIN files fph  ON fph.file_id  = e.title_photo
            LEFT JOIN files fvid ON fvid.file_id = e.video_file_id
        """)
        print(f"      {len(rows)} rows found")
        if not dry_run:
            async with dst.transaction():
                for r in rows:
                    await dst.execute("""
                        INSERT INTO exercises (
                            id, title, description, photo_url, video_url,
                            muscle_group, documentation, progression_level
                        )
                        OVERRIDING SYSTEM VALUE
                        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                        ON CONFLICT (id) DO UPDATE SET
                            title            = EXCLUDED.title,
                            description      = EXCLUDED.description,
                            photo_url        = EXCLUDED.photo_url,
                            video_url        = EXCLUDED.video_url,
                            muscle_group     = EXCLUDED.muscle_group,
                            documentation    = EXCLUDED.documentation,
                            progression_level = EXCLUDED.progression_level
                    """,
                        r["id"], r["title"], r["description"],
                        r["photo_url"], r["video_url"],
                        r["muscle_group"], r["documentation"], r["progression_level"],
                    )
                await dst.execute(
                    "SELECT setval('exercises_id_seq', "
                    "(SELECT COALESCE(MAX(id), 1) FROM exercises))"
                )
            print(f"      OK — {len(rows)} upserted")

        # ── 5. Alternative exercises ──────────────────────────────────────────
        print("\n[5/7] Alternative exercises …")
        rows = await src.fetch("""
            SELECT DISTINCT exercize_id AS exercise_id, alternative_exercize AS alternative_id
            FROM alternative_exercizes
            WHERE exercize_id IS NOT NULL AND alternative_exercize IS NOT NULL
        """)
        print(f"      {len(rows)} rows found")
        if not dry_run:
            async with dst.transaction():
                for r in rows:
                    await dst.execute("""
                        INSERT INTO alternative_exercises (exercise_id, alternative_id)
                        VALUES ($1, $2)
                        ON CONFLICT (exercise_id, alternative_id) DO NOTHING
                    """, r["exercise_id"], r["alternative_id"])
            print(f"      OK — {len(rows)} upserted")

        # ── 6. Exercise durations ─────────────────────────────────────────────
        print("\n[6/7] Exercise durations (duration_exercizes) …")
        rows = await src.fetch("""
            SELECT
                exercize_id             AS exercise_id,
                ROUND(repetition_duration)::smallint AS repetition_duration,
                ROUND(break_duration)::smallint      AS break_duration
            FROM duration_exercizes
            WHERE exercize_id IS NOT NULL
        """)
        print(f"      {len(rows)} rows found")
        if not dry_run:
            try:
                async with dst.transaction():
                    for r in rows:
                        await dst.execute("""
                            INSERT INTO duration_exercizes (
                                exercise_id, repetition_duration, break_duration
                            )
                            VALUES ($1, $2, $3)
                            ON CONFLICT (exercise_id) DO UPDATE SET
                                repetition_duration = EXCLUDED.repetition_duration,
                                break_duration      = EXCLUDED.break_duration
                        """, r["exercise_id"], r["repetition_duration"], r["break_duration"])
                print(f"      OK — {len(rows)} upserted")
            except Exception as e:
                print(f"      SKIPPED — {e} (apply migrations/003_fixes.sql first)")

        # ── 8. Translations ───────────────────────────────────────────────────
        # Copy only rows that concern entity types relevant to us.
        ENTITY_TYPES = ("exercizes", "equipments", "equipment_details")
        ENTITY_TYPE_MAP = {
            "exercizes":         "exercises",
            "equipments":        "equipment_categories",
            "equipment_details": "equipment_items",
        }
        print("\n[7/7] Translations …")
        rows = await src.fetch("""
            SELECT entity_type, entity_id, lang, field, value
            FROM translations
            WHERE entity_type = ANY($1::text[])
        """, list(ENTITY_TYPES))
        print(f"      {len(rows)} rows found")
        if not dry_run:
            async with dst.transaction():
                for r in rows:
                    target_type = ENTITY_TYPE_MAP.get(r["entity_type"], r["entity_type"])
                    await dst.execute("""
                        INSERT INTO translations (entity_type, entity_id, lang, field, value)
                        VALUES ($1, $2, $3, $4, $5)
                        ON CONFLICT (entity_type, entity_id, lang, field)
                        DO UPDATE SET value = EXCLUDED.value
                    """, target_type, r["entity_id"], r["lang"], r["field"], r["value"])
            print(f"      OK — {len(rows)} upserted")

        # ── Summary ───────────────────────────────────────────────────────────
        print("\n── Migration complete ──────────────────────────────────────────────")
        if not dry_run:
            counts = await dst.fetch("""
                SELECT 'equipment_categories' AS t, COUNT(*) FROM equipment_categories UNION ALL
                SELECT 'equipment_items',            COUNT(*) FROM equipment_items UNION ALL
                SELECT 'equipment_options',          COUNT(*) FROM equipment_options UNION ALL
                SELECT 'exercises',                  COUNT(*) FROM exercises UNION ALL
                SELECT 'alternative_exercises',      COUNT(*) FROM alternative_exercises UNION ALL
                SELECT 'translations',               COUNT(*) FROM translations
            """)
            for row in counts:
                print(f"  {row['t']:28s} {row['count']}")
        else:
            print("  Dry run complete — no data was written.")

    finally:
        await src.close()
        if dst is not None:
            await dst.close()


def _safe_dsn(dsn: str) -> str:
    """Hide password in DSN for display."""
    import re
    return re.sub(r"(:)[^:@]+(@)", r"\1***\2", dsn)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Migrate equipment + exercises from FitnesBot DB to KayFit_Fitkeep DB"
    )
    parser.add_argument(
        "--source-dsn",
        default=os.environ.get("SOURCE_DB_DSN", SOURCE_DSN),
        help="FitnesBot PostgreSQL DSN (default: from FitnesBot/.env)",
    )
    parser.add_argument(
        "--target-dsn",
        default=os.environ.get("TARGET_DB_DSN", DEFAULT_TARGET_DSN),
        help="KayFit_Fitkeep PostgreSQL DSN (or set TARGET_DB_DSN env var)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Read source data and print counts without writing to target",
    )
    args = parser.parse_args()

    try:
        asyncio.run(run(args.source_dsn, args.target_dsn, args.dry_run))
    except KeyboardInterrupt:
        print("\nInterrupted.")
        sys.exit(1)


if __name__ == "__main__":
    main()

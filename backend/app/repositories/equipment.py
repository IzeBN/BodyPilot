import asyncpg
from app.repositories.base import BaseRepository


class EquipmentRepository(BaseRepository):

    async def get_all_categories(self, lang: str = "ru") -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            return await conn.fetch(
                """SELECT ec.*,
                          COALESCE(tr.value, ec.title) AS display_title
                   FROM equipment_categories ec
                   LEFT JOIN translations tr ON tr.entity_type = 'equipment_categories'
                       AND tr.entity_id = ec.id AND tr.lang = $1 AND tr.field = 'title'
                   ORDER BY ec.id""",
                lang,
            )

    async def get_items_by_category(self, category_id: int, lang: str = "ru") -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            return await conn.fetch(
                """SELECT ei.*,
                          COALESCE(tr.value, ei.title) AS display_title,
                          json_agg(
                              json_build_object('id', eo.id, 'title', COALESCE(tr_opt.value, eo.title))
                              ORDER BY eo.id
                          ) FILTER (WHERE eo.id IS NOT NULL) AS options
                   FROM equipment_items ei
                   LEFT JOIN equipment_options eo ON eo.item_id = ei.id
                   LEFT JOIN translations tr ON tr.entity_type = 'equipment_items'
                       AND tr.entity_id = ei.id AND tr.lang = $2 AND tr.field = 'title'
                   LEFT JOIN translations tr_opt ON tr_opt.entity_type = 'equipment_options'
                       AND tr_opt.entity_id = eo.id AND tr_opt.lang = $2 AND tr_opt.field = 'title'
                   WHERE ei.category_id = $1
                   GROUP BY ei.id, tr.value ORDER BY ei.id""",
                category_id, lang,
            )

    async def get_user_equipment(self, user_id: int, lang: str = "ru") -> list[asyncpg.Record]:
        async with self.pool.acquire() as conn:
            return await conn.fetch(
                """SELECT ue.*, ec.title category_title, ei.title item_title,
                          eo.title option_title,
                          COALESCE(tr_cat.value, ec.title) display_category,
                          COALESCE(tr_item.value, ei.title) display_item
                   FROM user_equipment ue
                   JOIN equipment_categories ec ON ec.id = ue.category_id
                   JOIN equipment_items ei ON ei.id = ue.item_id
                   LEFT JOIN equipment_options eo ON eo.id = ue.option_id
                   LEFT JOIN translations tr_cat ON tr_cat.entity_type = 'equipment_categories'
                       AND tr_cat.entity_id = ec.id AND tr_cat.lang = $2 AND tr_cat.field = 'title'
                   LEFT JOIN translations tr_item ON tr_item.entity_type = 'equipment_items'
                       AND tr_item.entity_id = ei.id AND tr_item.lang = $2 AND tr_item.field = 'title'
                   WHERE ue.user_id = $1""",
                user_id, lang,
            )

    async def replace_user_equipment(
        self, user_id: int, items: list[dict]
    ) -> None:
        async with self.pool.acquire() as conn:
            async with conn.transaction():
                await conn.execute(
                    "DELETE FROM user_equipment WHERE user_id = $1", user_id
                )
                if items:
                    await conn.executemany(
                        """INSERT INTO user_equipment (user_id, category_id, item_id, option_id)
                           VALUES ($1, $2, $3, $4) ON CONFLICT (user_id, item_id) DO NOTHING""",
                        [
                            (user_id, it["category_id"], it["item_id"], it.get("option_id"))
                            for it in items
                        ],
                    )

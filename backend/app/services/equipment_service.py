import asyncio

from app.repositories.equipment import EquipmentRepository
from app.repositories.user import UserRepository


class EquipmentService:
    def __init__(self, equipment_repo: EquipmentRepository, user_repo: UserRepository) -> None:
        self._repo = equipment_repo
        self._users = user_repo

    async def get_catalog(self, lang: str) -> list[dict]:
        """
        Returns equipment catalog grouped by category.
        All DB queries run in parallel to avoid N+1.
        """
        categories = await self._repo.get_all_categories(lang)
        if not categories:
            return []
        items_lists = await asyncio.gather(
            *[self._repo.get_items_by_category(cat["id"], lang) for cat in categories]
        )
        return [
            {**dict(cat), "items": [dict(i) for i in items]}
            for cat, items in zip(categories, items_lists)
        ]

    async def get_user_equipment(self, user_id: int, lang: str) -> list[dict]:
        rows = await self._repo.get_user_equipment(user_id, lang)
        return [dict(r) for r in rows]

    async def update_user_equipment(self, user_id: int, items: list[dict]) -> None:
        await self._repo.replace_user_equipment(user_id, items)
        await self._users.add_action(user_id, "Updated equipment")

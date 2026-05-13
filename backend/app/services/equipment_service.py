import asyncio
import json

from app.repositories.equipment import EquipmentRepository
from app.repositories.user import UserRepository


def _parse_options(raw) -> list[dict]:
    """Convert options field (JSON string or list or None) to list[{id, name}]."""
    if not raw:
        return []
    if isinstance(raw, str):
        try:
            raw = json.loads(raw)
        except Exception:
            return []
    return [{"id": o["id"], "name": o.get("title", "")} for o in raw if isinstance(o, dict)]


def _map_item(row: dict) -> dict:
    return {
        "id": row["id"],
        "name": row.get("display_title") or row.get("title", ""),
        "description": None,
        "image_url": row.get("photo_url"),
        "options": _parse_options(row.get("options")),
    }


def _map_category(cat: dict, items: list) -> dict:
    return {
        "id": cat["id"],
        "name": cat.get("display_title") or cat.get("title", ""),
        "items": [_map_item(dict(i)) for i in items],
    }


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
            _map_category(dict(cat), items)
            for cat, items in zip(categories, items_lists)
        ]

    async def get_user_equipment(self, user_id: int, lang: str) -> list[dict]:
        rows = await self._repo.get_user_equipment(user_id, lang)
        return [dict(r) for r in rows]

    async def update_user_equipment(self, user_id: int, items: list[dict]) -> None:
        await self._repo.replace_user_equipment(user_id, items)
        await self._users.add_action(user_id, "Updated equipment")

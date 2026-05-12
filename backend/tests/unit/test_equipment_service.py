"""Unit tests for EquipmentService."""
import pytest

from app.services.equipment_service import EquipmentService


@pytest.fixture
def service(mock_equipment_repo, mock_user_repo):
    return EquipmentService(mock_equipment_repo, mock_user_repo)


# ─── get_catalog ─────────────────────────────────────────────────────────────

async def test_get_catalog_empty(service, mock_equipment_repo):
    mock_equipment_repo.get_all_categories.return_value = []
    result = await service.get_catalog("ru")
    assert result == []
    mock_equipment_repo.get_items_by_category.assert_not_awaited()


async def test_get_catalog_parallel_queries(service, mock_equipment_repo):
    """Each category triggers exactly one items query (in parallel)."""
    mock_equipment_repo.get_all_categories.return_value = [
        {"id": 1, "title": "Штанги", "photo_url": None},
        {"id": 2, "title": "Гантели", "photo_url": None},
    ]
    mock_equipment_repo.get_items_by_category.return_value = [
        {"id": 10, "title": "Olymp", "option_id": None}
    ]
    result = await service.get_catalog("ru")
    assert len(result) == 2
    assert "items" in result[0]
    assert "items" in result[1]
    assert mock_equipment_repo.get_items_by_category.await_count == 2


async def test_get_catalog_passes_lang(service, mock_equipment_repo):
    mock_equipment_repo.get_all_categories.return_value = [{"id": 1, "title": "Bars"}]
    mock_equipment_repo.get_items_by_category.return_value = []
    await service.get_catalog("en")
    mock_equipment_repo.get_all_categories.assert_awaited_once_with("en")
    mock_equipment_repo.get_items_by_category.assert_awaited_once_with(1, "en")


async def test_get_catalog_items_attached_per_category(service, mock_equipment_repo):
    mock_equipment_repo.get_all_categories.return_value = [
        {"id": 1, "title": "Cat1"},
        {"id": 2, "title": "Cat2"},
    ]
    # Return different items depending on category_id
    async def items_by_cat(cat_id, lang):
        return [{"id": cat_id * 10}]
    mock_equipment_repo.get_items_by_category.side_effect = items_by_cat

    result = await service.get_catalog("ru")
    assert result[0]["items"][0]["id"] == 10
    assert result[1]["items"][0]["id"] == 20


# ─── get_user_equipment ───────────────────────────────────────────────────────

async def test_get_user_equipment_empty(service, mock_equipment_repo):
    result = await service.get_user_equipment(1, "ru")
    assert result == []


async def test_get_user_equipment_returns_list(service, mock_equipment_repo):
    mock_equipment_repo.get_user_equipment.return_value = [
        {"id": 1, "category_id": 1, "item_id": 10}
    ]
    result = await service.get_user_equipment(1, "ru")
    assert len(result) == 1
    mock_equipment_repo.get_user_equipment.assert_awaited_once_with(1, "ru")


# ─── update_user_equipment ───────────────────────────────────────────────────

async def test_update_equipment_calls_replace(service, mock_equipment_repo):
    items = [{"category_id": 1, "item_id": 5, "option_id": None}]
    await service.update_user_equipment(1, items)
    mock_equipment_repo.replace_user_equipment.assert_awaited_once_with(1, items)


async def test_update_equipment_logs_action(service, mock_equipment_repo, mock_user_repo):
    await service.update_user_equipment(1, [])
    mock_user_repo.add_action.assert_awaited_once()


async def test_update_equipment_empty_list(service, mock_equipment_repo):
    """Empty list is valid — user cleared all equipment."""
    await service.update_user_equipment(1, [])
    mock_equipment_repo.replace_user_equipment.assert_awaited_once_with(1, [])

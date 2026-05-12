"""Unit tests for FoodRecognitionService."""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch

from app.services.food_recognition_service import FoodRecognitionService, _VITAMIN_KEYS


@pytest.fixture
def service(mock_pool):
    return FoodRecognitionService(mock_pool)


# ─── _build_result ────────────────────────────────────────────────────────────

def _make_enriched(cal100=100.0, prot100=10.0, fat100=5.0, carbs100=20.0, weight=200.0):
    row = {
        "name": "Тест", "name_en": "test", "weight_grams": weight,
        "calories_per_100g": cal100, "protein_per_100g": prot100,
        "fat_per_100g": fat100, "carbs_per_100g": carbs100,
        "fiber_per_100g": 1.0, "sugar_per_100g": None,
        "sugar_alcohols_per_100g": None, "saturated_fat_per_100g": None,
        "unsaturated_fat_per_100g": None, "glycemic_index": 50,
        "source": "local_db", "source_url": None,
    }
    for k in _VITAMIN_KEYS:
        row[k + "_per_100g"] = None
    return row


def test_build_result_scales_to_portion(service):
    enriched = [_make_enriched(cal100=200.0, prot100=20.0, fat100=10.0, carbs100=40.0, weight=150.0)]
    result = service._build_result(enriched)
    item = result["items"][0]
    assert item["calories"] == pytest.approx(300.0)
    assert item["protein"] == pytest.approx(30.0)
    assert item["fat"] == pytest.approx(15.0)
    assert item["carbs"] == pytest.approx(60.0)
    assert item["weight_grams"] == 150.0


def test_build_result_totals(service):
    enriched = [
        _make_enriched(cal100=100.0, weight=100.0),
        _make_enriched(cal100=200.0, weight=100.0),
    ]
    result = service._build_result(enriched)
    assert result["total"]["calories"] == pytest.approx(300.0)


def test_build_result_fiber_scaled(service):
    row = _make_enriched(weight=200.0)
    row["fiber_per_100g"] = 3.0
    result = service._build_result([row])
    assert result["items"][0]["fiber"] == pytest.approx(6.0)


def test_build_result_vitamin_none_stays_none(service):
    result = service._build_result([_make_enriched()])
    assert result["items"][0]["vitamin_c_mg"] is None


def test_build_result_vitamin_scaled(service):
    row = _make_enriched(weight=100.0)
    row["vitamin_c_mg_per_100g"] = 10.0
    result = service._build_result([row])
    assert result["items"][0]["vitamin_c_mg"] == pytest.approx(10.0)


def test_build_result_empty(service):
    result = service._build_result([])
    assert result["items"] == []
    assert result["total"]["calories"] == 0.0


# ─── _apply_nutrients ─────────────────────────────────────────────────────────

def test_apply_nutrients_from_source(service):
    row = {"name": "X", "name_en": "x", "weight_grams": 100.0}
    src = {"calories": 150, "protein": 12, "fat": 5, "carbs": 20,
           "fiber": 2.5, "source_url": "https://example.com"}
    service._apply_nutrients(row, src, "local_db")
    assert row["calories_per_100g"] == 150.0
    assert row["fiber_per_100g"] == pytest.approx(2.5)
    assert row["source"] == "local_db"
    assert row["source_url"] == "https://example.com"


def test_apply_nutrients_none_source(service):
    row = {"name": "X", "name_en": "x", "weight_grams": 100.0}
    service._apply_nutrients(row, None, None)
    assert row["calories_per_100g"] is None
    assert row["source"] == "unknown"
    for k in _VITAMIN_KEYS:
        assert row[k + "_per_100g"] is None


def test_apply_nutrients_zero_calories_treated_as_none(service):
    row = {"name": "X", "name_en": "x", "weight_grams": 100.0}
    service._apply_nutrients(row, {"calories": 0, "protein": 10}, None)
    assert row["calories_per_100g"] is None


# ─── recognize_text ───────────────────────────────────────────────────────────

async def test_recognize_text_returns_items(service, fake_items_parsed, fake_enriched):
    with (
        patch.object(service, "_parse_text", new=AsyncMock(return_value=fake_items_parsed)),
        patch.object(service, "_enrich_items", new=AsyncMock(return_value=fake_enriched)),
    ):
        result = await service.recognize_text("Гречка 200г и яйцо", "ru")

    assert len(result["items"]) == 2
    assert result["items"][0]["name"] == "Гречка"
    assert result["total"]["calories"] > 0


async def test_recognize_text_empty_parse(service):
    with patch.object(service, "_parse_text", new=AsyncMock(return_value=[])):
        result = await service.recognize_text("xyz", "ru")
    assert result["items"] == []
    assert result["total"]["calories"] == 0.0


async def test_recognize_text_auto_detect_lang(service, fake_items_parsed, fake_enriched):
    with (
        patch.object(service, "_parse_text", new=AsyncMock(return_value=fake_items_parsed)) as mock_pt,
        patch.object(service, "_enrich_items", new=AsyncMock(return_value=fake_enriched)),
    ):
        await service.recognize_text("buckwheat 200g and egg", "auto")
    # English text → detected as 'en'
    mock_pt.assert_awaited_once()
    lang_used = mock_pt.call_args[0][1]
    assert lang_used == "en"


# ─── recognize_photo ──────────────────────────────────────────────────────────

async def test_recognize_photo_returns_items(service, fake_items_parsed, fake_enriched):
    fake_image = b"\xff\xd8\xff" + b"\x00" * 10  # fake JPEG header
    with (
        patch.object(service, "_identify_photo", new=AsyncMock(return_value=fake_items_parsed)),
        patch.object(service, "_enrich_items", new=AsyncMock(return_value=fake_enriched)),
    ):
        result = await service.recognize_photo(fake_image, "ru")

    assert len(result["items"]) == 2
    assert result["total"]["calories"] > 0


async def test_recognize_photo_empty_detection(service):
    with patch.object(service, "_identify_photo", new=AsyncMock(return_value=[])):
        result = await service.recognize_photo(b"\xff\xd8\xff", "ru")
    assert result["items"] == []


async def test_recognize_photo_passes_language(service, fake_items_parsed, fake_enriched):
    with (
        patch.object(service, "_identify_photo", new=AsyncMock(return_value=fake_items_parsed)) as mock_id,
        patch.object(service, "_enrich_items", new=AsyncMock(return_value=fake_enriched)),
    ):
        await service.recognize_photo(b"\x89PNG", "en")
    mock_id.assert_awaited_once_with(b"\x89PNG", "en")


# ─── recognize_voice ─────────────────────────────────────────────────────────

async def test_recognize_voice_full_pipeline(service, fake_items_parsed, fake_enriched):
    with (
        patch.object(service, "_transcribe_voice", new=AsyncMock(return_value="Гречка 200г и яйцо")),
        patch.object(service, "_parse_text", new=AsyncMock(return_value=fake_items_parsed)),
        patch.object(service, "_enrich_items", new=AsyncMock(return_value=fake_enriched)),
    ):
        result = await service.recognize_voice(b"audio", "voice.mp3", "ru")

    assert result["transcript"] == "Гречка 200г и яйцо"
    assert len(result["items"]) == 2


async def test_recognize_voice_empty_transcript(service):
    with patch.object(service, "_transcribe_voice", new=AsyncMock(return_value="")):
        result = await service.recognize_voice(b"audio", "voice.mp3", "ru")
    assert result["items"] == []
    assert result["transcript"] == ""


async def test_recognize_voice_no_items_parsed(service):
    with (
        patch.object(service, "_transcribe_voice", new=AsyncMock(return_value="бла бла")),
        patch.object(service, "_parse_text", new=AsyncMock(return_value=[])),
    ):
        result = await service.recognize_voice(b"audio", "voice.ogg", "ru")
    assert result["items"] == []
    assert result["transcript"] == "бла бла"


# ─── _enrich_items ────────────────────────────────────────────────────────────

async def test_enrich_items_uses_cache_hit(service):
    cached = {
        "calories": 343.0, "protein": 13.0, "fat": 3.4, "carbs": 71.5,
        "fiber": 2.7, "sugar": None, "source": "local_db", "source_url": None,
        **{k: None for k in _VITAMIN_KEYS},
        "sugar_alcohols": None, "saturated_fat": None, "unsaturated_fat": None, "glycemic_index": None,
    }
    with patch.object(service, "_search_cache", new=AsyncMock(return_value=cached)):
        items = [{"name": "Гречка", "name_en": "buckwheat", "weight_grams": 100.0}]
        enriched = await service._enrich_items(items, "ru")
    assert enriched[0]["calories_per_100g"] == 343.0
    assert enriched[0]["source"] == "local_db"


async def test_enrich_items_falls_back_to_claude(service):
    claude_data = {
        "calories": 52.0, "protein": 0.3, "fat": 0.2, "carbs": 14.0,
        "fiber": 2.4, "sugar": 10.0, "source_url": None,
        **{k: None for k in _VITAMIN_KEYS},
        "sugar_alcohols": None, "saturated_fat": None, "unsaturated_fat": None, "glycemic_index": None,
    }
    with (
        patch.object(service, "_search_cache", new=AsyncMock(return_value=None)),
        patch.object(service, "_claude_get_nutrients", new=AsyncMock(return_value={"apple": claude_data})),
        patch.object(service, "_cache_nutrients", new=AsyncMock()),
    ):
        items = [{"name": "Яблоко", "name_en": "apple", "weight_grams": 150.0}]
        enriched = await service._enrich_items(items, "ru")
    assert enriched[0]["calories_per_100g"] == 52.0
    assert enriched[0]["source"] == "claude"


async def test_enrich_items_caches_claude_result(service):
    """_cache_nutrients is scheduled via asyncio.create_task; verify it was enqueued."""
    import asyncio as _asyncio
    claude_data = {"calories": 52.0, "protein": 0.3, "fat": 0.2, "carbs": 14.0}
    created_coros: list = []

    def capture_task(coro):
        created_coros.append(coro)
        # Return a real task so the event loop doesn't complain
        return _asyncio.get_event_loop().create_task(coro)

    with (
        patch.object(service, "_search_cache", new=AsyncMock(return_value=None)),
        patch.object(service, "_claude_get_nutrients", new=AsyncMock(return_value={"apple": claude_data})),
        patch.object(service, "_cache_nutrients", new=AsyncMock()),
        patch("app.services.food_recognition_service.asyncio.create_task", side_effect=capture_task),
    ):
        items = [{"name": "Яблоко", "name_en": "apple", "weight_grams": 100.0}]
        await service._enrich_items(items, "ru")

    assert len(created_coros) == 1


async def test_enrich_items_no_nutrients_available(service):
    with (
        patch.object(service, "_search_cache", new=AsyncMock(return_value=None)),
        patch.object(service, "_claude_get_nutrients", new=AsyncMock(return_value={})),
    ):
        items = [{"name": "Неизвестно", "name_en": "unknown_xyz", "weight_grams": 100.0}]
        enriched = await service._enrich_items(items, "ru")
    assert enriched[0]["calories_per_100g"] is None
    assert enriched[0]["source"] == "unknown"


# ─── _detect_language ────────────────────────────────────────────────────────

def test_detect_lang_russian():
    from app.services.food_recognition_service import _detect_language
    assert _detect_language("Гречка и яйцо") == "ru"


def test_detect_lang_english():
    from app.services.food_recognition_service import _detect_language
    assert _detect_language("buckwheat and egg") == "en"


def test_detect_lang_mixed_prefers_cyrillic():
    from app.services.food_recognition_service import _detect_language
    assert _detect_language("Гречка buckwheat гарнир") == "ru"


# ─── _parse_text: no key ─────────────────────────────────────────────────────

async def test_parse_text_no_api_key_returns_empty(service):
    with patch("app.services.food_recognition_service.get_settings") as mock_s:
        mock_s.return_value.anthropic_api_key = ""
        result = await service._parse_text("что-то", "ru")
    assert result == []


# ─── _identify_photo: no key ─────────────────────────────────────────────────

async def test_identify_photo_no_api_key_returns_empty(service):
    with patch("app.services.food_recognition_service.get_settings") as mock_s:
        mock_s.return_value.anthropic_api_key = ""
        result = await service._identify_photo(b"\xff\xd8\xff", "ru")
    assert result == []


# ─── _transcribe_voice: no key ───────────────────────────────────────────────

async def test_transcribe_voice_no_api_key_returns_empty(service):
    with patch("app.services.food_recognition_service.get_settings") as mock_s:
        mock_s.return_value.openai_api_key = ""
        result = await service._transcribe_voice(b"audio", "voice.mp3", "ru")
    assert result == ""


# ─── _claude_get_nutrients: no key ───────────────────────────────────────────

async def test_claude_get_nutrients_no_key_returns_empty(service):
    with patch("app.services.food_recognition_service.get_settings") as mock_s:
        mock_s.return_value.anthropic_api_key = ""
        result = await service._claude_get_nutrients(["apple", "banana"], "en")
    assert result == {}


async def test_claude_get_nutrients_empty_list(service):
    result = await service._claude_get_nutrients([], "ru")
    assert result == {}

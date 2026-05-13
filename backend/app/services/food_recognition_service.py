"""Food recognition from text, photo and voice using Claude + OpenAI Whisper."""
import re
import json
import base64
import asyncio
import io
import logging

import httpx
from asyncpg import Pool

from app.config import get_settings

logger = logging.getLogger(__name__)


def _make_anthropic_client(api_key: str):
    import anthropic
    proxy = get_settings().openai_proxy or None
    return anthropic.AsyncAnthropic(
        api_key=api_key,
        http_client=httpx.AsyncClient(proxy=proxy) if proxy else None,
    )


def _make_openai_client(api_key: str):
    from openai import AsyncOpenAI
    proxy = get_settings().openai_proxy or None
    return AsyncOpenAI(
        api_key=api_key,
        http_client=httpx.AsyncClient(proxy=proxy) if proxy else None,
    )

CLAUDE_MODEL = "claude-sonnet-4-6"

_VITAMIN_KEYS = (
    "sodium_mg", "calcium_mg", "iron_mg", "potassium_mg", "magnesium_mg",
    "phosphorus_mg", "zinc_mg", "selenium_mcg", "manganese_mg", "copper_mg",
    "cholesterol_mg",
    "vitamin_a_mcg", "vitamin_c_mg", "vitamin_d_mcg", "vitamin_e_mg", "vitamin_k_mcg",
    "vitamin_b1_mg", "vitamin_b2_mg", "vitamin_b3_mg", "vitamin_b5_mg", "vitamin_b6_mg",
    "vitamin_b7_mcg", "vitamin_b9_mcg", "vitamin_b12_mcg",
)

_MACRO_EXTRA_KEYS = ("fiber", "sugar", "sugar_alcohols", "net_carbs",
                     "saturated_fat", "unsaturated_fat", "glycemic_index")

# ─── Prompts ──────────────────────────────────────────────────────────────────

_PARSE_PROMPTS = {
    "ru": (
        "Ты — помощник по питанию. Пользователь описал, что съел. Разбери текст на отдельные продукты/блюда.\n"
        "Верни ТОЛЬКО валидный JSON без markdown и пояснений:\n"
        '{"items": [{"name": "название на русском", "name_en": "name in English", "weight_grams": число или null}]}\n'
        "Правила:\n"
        "- name — только кириллица, сохраняй бренды\n"
        "- name_en — короткое английское название (2-3 слова) для поиска в БД\n"
        "- weight_grams — вес порции в граммах или null если не указан\n"
        "Текст пользователя: "
    ),
    "en": (
        "You are a nutrition assistant. Parse the text into individual food items.\n"
        "Return ONLY valid JSON without markdown:\n"
        '{"items": [{"name": "food name in English", "name_ru": "название на русском", "weight_grams": grams or null}]}\n'
        "Rules:\n"
        "- name — short display name in English (2-3 words), keep brand names\n"
        "- name_ru — Russian Cyrillic name for display\n"
        "- weight_grams: portion weight in grams, null if not specified\n"
        "User text: "
    ),
}

_IDENTIFY_PROMPTS = {
    "ru": (
        "Ты — нутрициолог-фотоаналитик. Определи все блюда/продукты на фото и оцени вес каждой порции.\n\n"
        "Визуальные ориентиры масштаба:\n"
        "• Тарелка обеденная ≈ 26–28 см; Вилка ≈ 19 см; Кулак ≈ 250 мл\n"
        "• Упаковка с этикеткой → вес с этикетки\n\n"
        "Оценка веса — будь реалистичен:\n"
        "• Мясо/рыба: 100–150г; Рис/крупы: 120–180г; Овощи: 80–120г\n"
        "• Соус: 15–40г; Хлеб: 25–35г; Яйцо: 50–55г без скорлупы\n\n"
        "Верни ТОЛЬКО валидный JSON без markdown:\n"
        '{"items": [{"name": "название на русском", "name_en": "short english name", "weight_grams": вес_г}]}\n\n'
        "Правила:\n"
        '1) Нет еды → {"items": [], "error": "На изображении нет еды"}\n'
        "2) name_en — КОРОТКОЕ название (2-3 слова): 'chicken breast', 'buckwheat'. НЕ: 'baked seasoned chicken breast'\n"
        "3) Перечисляй все компоненты: основное, гарниры, соусы, напитки"
    ),
    "en": (
        "You are a nutrition photo analyst. Identify all dishes in the photo and estimate portion weight.\n\n"
        "Size references: dinner plate ≈ 26-28cm; fork ≈ 19cm; fist ≈ 250ml\n"
        "Weight estimation: meat/fish 100-150g, grains 120-180g, vegetables 80-120g, sauce 15-40g, bread 25-35g\n\n"
        "Return ONLY valid JSON without markdown:\n"
        '{"items": [{"name": "food name in English", "name_ru": "название на русском", "weight_grams": grams}]}\n\n'
        "Rules:\n"
        '1) No food → {"items": [], "error": "No food in the image"}\n'
        "2) name — SHORT generic name (2-3 words): 'chicken breast', NOT 'baked seasoned chicken breast pieces'\n"
        "3) List all visible items: main dish, sides, sauces, drinks"
    ),
}

_NUTRIENTS_PROMPTS = {
    "ru": (
        "Ты — нутрициолог. Найди точные значения питательных веществ на 100г для каждого продукта.\n"
        "Верни ТОЛЬКО валидный JSON без markdown:\n"
        '{"items": [{"name": "название", "calories": ккал/100г, "protein": г/100г, "fat": г/100г, "carbs": г/100г, '
        '"fiber": г/100г или null, "sugar": г/100г или null, "sugar_alcohols": г/100г или null, '
        '"saturated_fat": г/100г или null, "unsaturated_fat": г/100г или null, "glycemic_index": число или null, '
        '"sodium_mg": мг/100г или null, "calcium_mg": мг/100г или null, "iron_mg": мг/100г или null, '
        '"potassium_mg": мг/100г или null, "magnesium_mg": мг/100г или null, "phosphorus_mg": мг/100г или null, '
        '"zinc_mg": мг/100г или null, "selenium_mcg": мкг/100г или null, "manganese_mg": мг/100г или null, '
        '"copper_mg": мг/100г или null, "cholesterol_mg": мг/100г или null, '
        '"vitamin_a_mcg": мкг/100г или null, "vitamin_c_mg": мг/100г или null, "vitamin_d_mcg": мкг/100г или null, '
        '"vitamin_e_mg": мг/100г или null, "vitamin_k_mcg": мкг/100г или null, '
        '"vitamin_b1_mg": мг/100г или null, "vitamin_b2_mg": мг/100г или null, "vitamin_b3_mg": мг/100г или null, '
        '"vitamin_b5_mg": мг/100г или null, "vitamin_b6_mg": мг/100г или null, "vitamin_b7_mcg": мкг/100г или null, '
        '"vitamin_b9_mcg": мкг/100г или null, "vitamin_b12_mcg": мкг/100г или null, '
        '"source_url": "URL источника или null"}]}\n'
        "Продукты:\n"
    ),
    "en": (
        "You are a nutritionist. Find accurate nutritional values per 100g for each food.\n"
        "Return ONLY valid JSON without markdown:\n"
        '{"items": [{"name": "food name", "calories": kcal/100g, "protein": g/100g, "fat": g/100g, "carbs": g/100g, '
        '"fiber": g/100g or null, "sugar": g/100g or null, "sugar_alcohols": g/100g or null, '
        '"saturated_fat": g/100g or null, "unsaturated_fat": g/100g or null, "glycemic_index": number or null, '
        '"sodium_mg": mg/100g or null, "calcium_mg": mg/100g or null, "iron_mg": mg/100g or null, '
        '"potassium_mg": mg/100g or null, "magnesium_mg": mg/100g or null, "phosphorus_mg": mg/100g or null, '
        '"zinc_mg": mg/100g or null, "selenium_mcg": mcg/100g or null, "manganese_mg": mg/100g or null, '
        '"copper_mg": mg/100g or null, "cholesterol_mg": mg/100g or null, '
        '"vitamin_a_mcg": mcg/100g or null, "vitamin_c_mg": mg/100g or null, "vitamin_d_mcg": mcg/100g or null, '
        '"vitamin_e_mg": mg/100g or null, "vitamin_k_mcg": mcg/100g or null, '
        '"vitamin_b1_mg": mg/100g or null, "vitamin_b2_mg": mg/100g or null, "vitamin_b3_mg": mg/100g or null, '
        '"vitamin_b5_mg": mg/100g or null, "vitamin_b6_mg": mg/100g or null, "vitamin_b7_mcg": mcg/100g or null, '
        '"vitamin_b9_mcg": mcg/100g or null, "vitamin_b12_mcg": mcg/100g or null, '
        '"source_url": "URL of source page or null"}]}\n'
        "Foods:\n"
    ),
}


# ─── Helpers ──────────────────────────────────────────────────────────────────

def _opt_float(v, ndigits: int = 3) -> "float | None":
    if v is None or v == "":
        return None
    try:
        f = float(v)
        return round(f, ndigits) if f != 0 else None
    except (TypeError, ValueError):
        return None


def _extract_json(text: str) -> dict:
    """Strip markdown fences and extract first {...} block."""
    if "```" in text:
        text = re.sub(r"```\w*\n?", "", text).strip()
    m = re.search(r"\{[\s\S]*\}", text)
    if m:
        text = m.group(0)
    return json.loads(text)


def _detect_language(text: str) -> str:
    cyrillic = sum(1 for c in text if "\u0400" <= c <= "\u04ff")
    latin = sum(1 for c in text if "a" <= c.lower() <= "z")
    if latin > 0 and cyrillic == 0:
        return "en"
    return "ru"


# ─── Service ──────────────────────────────────────────────────────────────────

class FoodRecognitionService:
    """Recognises meals from text, photos and voice, enriches with nutrients."""

    def __init__(self, pool: Pool) -> None:
        self._pool = pool

    # ── Public API ────────────────────────────────────────────────────────────

    async def recognize_text(self, text: str, language: str = "ru") -> dict:
        """Parse free-text meal description → list of items with nutrients."""
        lang = self._resolve_lang(language, text)
        logger.info("recognize_text: text=%r lang=%s", text[:80], lang)
        items = await self._parse_text(text, lang)
        logger.info("recognize_text: parsed %d items", len(items))
        if not items:
            return {"items": [], "total": self._zero_total()}
        enriched = await self._enrich_items(items, lang)
        result = self._build_result(enriched)
        logger.info("recognize_text: returning %d enriched items", len(result["items"]))
        return result

    async def recognize_photo(self, image_data: bytes, language: str = "ru") -> dict:
        """Identify food in photo + estimate weights → items with nutrients."""
        lang = language if language in ("ru", "en") else "ru"
        items = await self._identify_photo(image_data, lang)
        if not items:
            return {"items": [], "total": self._zero_total()}
        enriched = await self._enrich_items(items, lang)
        return self._build_result(enriched)

    async def recognize_voice(self, audio_data: bytes, filename: str, language: str = "ru") -> dict:
        """Transcribe audio → parse text → items with nutrients."""
        transcript = await self._transcribe_voice(audio_data, filename, language)
        if not transcript:
            return {"items": [], "total": self._zero_total(), "transcript": ""}
        lang = self._resolve_lang(language, transcript)
        items = await self._parse_text(transcript, lang)
        if not items:
            return {"items": [], "total": self._zero_total(), "transcript": transcript}
        enriched = await self._enrich_items(items, lang)
        result = self._build_result(enriched)
        result["transcript"] = transcript
        return result

    # ── Internal: Claude text parsing ─────────────────────────────────────────

    async def _parse_text(self, text: str, language: str) -> list[dict]:
        """Ask Claude to split text into {name, name_en, weight_grams} items."""
        settings = get_settings()
        key = settings.anthropic_api_key
        if not key:
            logger.error("_parse_text: anthropic_api_key is not set")
            return []
        lang = language if language in _PARSE_PROMPTS else "ru"
        prompt = _PARSE_PROMPTS[lang] + text.strip()
        try:
            client = _make_anthropic_client(key)
            logger.info("_parse_text: calling Claude model=%s", CLAUDE_MODEL)
            resp = await client.messages.create(
                model=CLAUDE_MODEL,
                max_tokens=600,
                messages=[{"role": "user", "content": prompt}],
            )
            raw_text = (resp.content[0].text or "").strip()
            logger.info("_parse_text: Claude response: %r", raw_text[:200])
            data = _extract_json(raw_text)
            raw_items = data.get("items") or []
        except Exception as e:
            logger.error("_parse_text: exception: %s", e, exc_info=True)
            return []

        result = []
        for it in raw_items:
            name = (it.get("name") or "").strip()
            if not name:
                continue
            name_en = (it.get("name_en") or it.get("name_ru") or name).strip()
            w = it.get("weight_grams")
            try:
                w = float(w) if w is not None else 100.0
            except (TypeError, ValueError):
                w = 100.0
            result.append({"name": name, "name_en": name_en, "weight_grams": w})
        return result

    # ── Internal: Claude Vision photo identification ───────────────────────────

    async def _identify_photo(self, image_data: bytes, language: str) -> list[dict]:
        """Ask Claude Vision to identify food items and estimate weights."""
        settings = get_settings()
        key = settings.anthropic_api_key
        if not key:
            return []
        lang = language if language in _IDENTIFY_PROMPTS else "ru"
        prompt = _IDENTIFY_PROMPTS[lang]

        media_type = "image/jpeg"
        if image_data[:4] == b"\x89PNG":
            media_type = "image/png"
        elif image_data[:4] == b"RIFF" and image_data[8:12] == b"WEBP":
            media_type = "image/webp"
        elif image_data[:3] == b"GIF":
            media_type = "image/gif"

        b64 = base64.standard_b64encode(image_data).decode("ascii")
        try:
            client = _make_anthropic_client(key)
            resp = await client.messages.create(
                model=CLAUDE_MODEL,
                max_tokens=512,
                messages=[{
                    "role": "user",
                    "content": [
                        {"type": "image", "source": {"type": "base64", "media_type": media_type, "data": b64}},
                        {"type": "text", "text": prompt},
                    ],
                }],
            )
            data = _extract_json((resp.content[0].text or "").strip())
        except Exception:
            return []

        if "error" in data:
            return []
        raw_items = data.get("items") or []
        result = []
        for it in raw_items:
            name = (it.get("name") or "").strip()
            if not name:
                continue
            name_en = (it.get("name_en") or it.get("name") or name).strip()
            try:
                w = float(it.get("weight_grams") or 100)
            except (TypeError, ValueError):
                w = 100.0
            result.append({"name": name, "name_en": name_en, "weight_grams": w})
        return result

    # ── Internal: OpenAI Whisper transcription ────────────────────────────────

    async def _transcribe_voice(self, audio_data: bytes, filename: str, language: str) -> str:
        """Transcribe audio via OpenAI Whisper."""
        settings = get_settings()
        key = settings.effective_openai_key
        if not key:
            return ""
        suffix = (filename or "").lower()
        data, name = audio_data, filename or "audio"

        need_convert = (
            suffix.endswith(".ogg") or suffix.endswith(".opus") or
            suffix.endswith(".webm") or
            (len(audio_data) > 4 and audio_data[:4] == b"\x1a\x45\xdf\xa3")
        )
        if need_convert:
            import tempfile, os
            ext = ".webm" if ".webm" in suffix or audio_data[:4] == b"\x1a\x45\xdf\xa3" else ".ogg"
            with tempfile.NamedTemporaryFile(suffix=ext, delete=False) as f:
                f.write(audio_data)
                in_path = f.name
            mp3_path = in_path + ".mp3"
            try:
                proc = await asyncio.create_subprocess_exec(
                    "ffmpeg", "-y", "-i", in_path, "-acodec", "libmp3lame", "-q:a", "2", mp3_path,
                    stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE,
                )
                try:
                    await asyncio.wait_for(proc.communicate(), timeout=30)
                except asyncio.TimeoutError:
                    proc.kill()
                    await proc.communicate()
                    return ""
                if proc.returncode != 0:
                    return ""
                with open(mp3_path, "rb") as f:
                    data = f.read()
                name = "audio.mp3"
            except FileNotFoundError:
                return ""
            finally:
                for p in (in_path, mp3_path):
                    try:
                        os.unlink(p)
                    except Exception:
                        pass

        import tempfile, os
        client = _make_openai_client(key)
        with tempfile.NamedTemporaryFile(mode="wb", suffix=".mp3" if name.endswith(".mp3") else ".webm", delete=False) as tmp:
            tmp.write(data)
            tmp_path = tmp.name
        try:
            file_obj = io.BytesIO(open(tmp_path, "rb").read())
            file_obj.name = name
            whisper_lang = language if language in ("ru", "en") else "ru"
            resp = await client.audio.transcriptions.create(
                model="whisper-1", file=file_obj, language=whisper_lang,
            )
            return (resp.text or "").strip()
        except Exception:
            return ""
        finally:
            try:
                os.unlink(tmp_path)
            except Exception:
                pass

    # ── Internal: nutrient enrichment ─────────────────────────────────────────

    async def _enrich_items(self, items: list[dict], language: str) -> list[dict]:
        """
        Enrich each item with per-100g nutrients via:
        1. Local food_nutrients_cache (by name_en)
        2. Claude web_search batch fallback
        Then cache new results fire-and-forget.
        """
        en_names = [it.get("name_en") or it.get("name") or "" for it in items]

        # Step 1: parallel local cache lookup
        cache_results = await asyncio.gather(*[
            self._search_cache(en) for en in en_names
        ])

        # Step 2: Claude batch for cache misses
        miss_indices = [i for i, r in enumerate(cache_results) if not r]
        miss_names = [en_names[i] for i in miss_indices]
        claude_map: dict = {}
        if miss_names:
            claude_map = await self._claude_get_nutrients(miss_names, language)

        save_tasks: list[tuple] = []
        enriched: list[dict] = []
        for i, item in enumerate(items):
            name = item.get("name") or ""
            name_en = en_names[i]
            w = float(item.get("weight_grams") or 100)
            row: dict = {"name": name, "name_en": name_en, "weight_grams": w}

            cached = cache_results[i]
            if cached and float(cached.get("calories") or 0) > 0:
                self._apply_nutrients(row, cached, cached.get("source", "local_db"))
            elif i in miss_indices and name_en in claude_map:
                nut = claude_map[name_en] or {}
                if float(nut.get("calories") or 0) > 0:
                    self._apply_nutrients(row, nut, "claude")
                    save_tasks.append((name_en, nut, "claude"))
                else:
                    self._apply_nutrients(row, None, None)
            else:
                self._apply_nutrients(row, None, None)
            enriched.append(row)

        for name_en, data, source in save_tasks:
            asyncio.create_task(self._cache_nutrients(name_en, data, source))

        return enriched

    async def _search_cache(self, name_en: str) -> "dict | None":
        """Look up food_nutrients_cache and foods tables by English name."""
        if not name_en:
            return None
        async with self._pool.acquire() as conn:
            row = await conn.fetchrow(
                "SELECT * FROM food_nutrients_cache WHERE LOWER(name_en) = LOWER($1)",
                name_en,
            )
            if row:
                return dict(row)
            # Fallback: look in foods table (manually seeded DB)
            foods_row = await conn.fetchrow(
                """SELECT
                    calories AS calories, protein AS protein,
                    fat AS fat, carbs AS carbs,
                    fiber, sugar, saturated_fat, unsaturated_fat,
                    glycemic_index, sodium_mg, calcium_mg, iron_mg, potassium_mg,
                    magnesium_mg, phosphorus_mg, zinc_mg, selenium_mcg, manganese_mg,
                    copper_mg, cholesterol_mg, vitamin_a_mcg, vitamin_c_mg, vitamin_d_mcg,
                    vitamin_e_mg, vitamin_k_mcg, vitamin_b1_mg, vitamin_b2_mg, vitamin_b3_mg,
                    vitamin_b5_mg, vitamin_b6_mg, vitamin_b7_mcg, vitamin_b9_mcg, vitamin_b12_mcg,
                    source_url, 'local_db' AS source
                   FROM foods
                   WHERE LOWER(name_en) = LOWER($1) OR LOWER(name) = LOWER($1)
                   LIMIT 1""",
                name_en,
            )
            return dict(foods_row) if foods_row else None

    async def _cache_nutrients(self, name_en: str, data: dict, source: str) -> None:
        """Upsert nutrient data into food_nutrients_cache."""
        try:
            async with self._pool.acquire() as conn:
                await conn.execute(
                    """INSERT INTO food_nutrients_cache (
                        name_en, calories, protein, fat, carbs, fiber, sugar, sugar_alcohols,
                        saturated_fat, unsaturated_fat, glycemic_index,
                        sodium_mg, calcium_mg, iron_mg, potassium_mg, magnesium_mg, phosphorus_mg,
                        zinc_mg, selenium_mcg, manganese_mg, copper_mg, cholesterol_mg,
                        vitamin_a_mcg, vitamin_c_mg, vitamin_d_mcg, vitamin_e_mg, vitamin_k_mcg,
                        vitamin_b1_mg, vitamin_b2_mg, vitamin_b3_mg, vitamin_b5_mg, vitamin_b6_mg,
                        vitamin_b7_mcg, vitamin_b9_mcg, vitamin_b12_mcg,
                        source, source_url, updated_at
                    ) VALUES (
                        $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,
                        $21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31,$32,$33,$34,$35,$36,$37,NOW()
                    )
                    ON CONFLICT (name_en) DO UPDATE SET
                        calories=$2, protein=$3, fat=$4, carbs=$5, fiber=$6, sugar=$7,
                        sugar_alcohols=$8, saturated_fat=$9, unsaturated_fat=$10,
                        glycemic_index=$11, sodium_mg=$12, calcium_mg=$13, iron_mg=$14,
                        potassium_mg=$15, magnesium_mg=$16, phosphorus_mg=$17, zinc_mg=$18,
                        selenium_mcg=$19, manganese_mg=$20, copper_mg=$21, cholesterol_mg=$22,
                        vitamin_a_mcg=$23, vitamin_c_mg=$24, vitamin_d_mcg=$25, vitamin_e_mg=$26,
                        vitamin_k_mcg=$27, vitamin_b1_mg=$28, vitamin_b2_mg=$29, vitamin_b3_mg=$30,
                        vitamin_b5_mg=$31, vitamin_b6_mg=$32, vitamin_b7_mcg=$33, vitamin_b9_mcg=$34,
                        vitamin_b12_mcg=$35, source=$36, source_url=$37, updated_at=NOW()
                    """,
                    name_en,
                    _opt_float(data.get("calories"), 2), _opt_float(data.get("protein"), 2),
                    _opt_float(data.get("fat"), 2), _opt_float(data.get("carbs"), 2),
                    _opt_float(data.get("fiber")), _opt_float(data.get("sugar")),
                    _opt_float(data.get("sugar_alcohols")),
                    _opt_float(data.get("saturated_fat")), _opt_float(data.get("unsaturated_fat")),
                    int(data["glycemic_index"]) if data.get("glycemic_index") else None,
                    *[_opt_float(data.get(k)) for k in _VITAMIN_KEYS],
                    source, data.get("source_url"),
                )
        except Exception:
            pass

    async def _claude_get_nutrients(self, names: list[str], language: str = "ru") -> dict:
        """Batch Claude request for per-100g nutrients of multiple foods."""
        if not names:
            return {}
        settings = get_settings()
        key = settings.anthropic_api_key
        if not key:
            return {}
        lang = language if language in _NUTRIENTS_PROMPTS else "ru"
        prompt = _NUTRIENTS_PROMPTS[lang] + "\n".join(f"- {n}" for n in names)
        max_tokens = 400 + len(names) * 400
        try:
            client = _make_anthropic_client(key)
            resp = await client.messages.create(
                model=CLAUDE_MODEL,
                max_tokens=max_tokens,
                tools=[{"type": "web_search_20250305", "name": "web_search", "max_uses": 3}],
                betas=["web-search-2025-03-05"],
                messages=[{"role": "user", "content": prompt}],
            )
            content = ""
            for block in resp.content:
                if hasattr(block, "text") and block.text:
                    content = block.text.strip()
                    break
            if not content:
                return {}
            data = _extract_json(content)
            result: dict = {}
            items_list = data.get("items") or []
            for it in items_list:
                n = (it.get("name") or "").strip()
                if n:
                    result[n] = it
            # Positional fallback if name didn't match
            for idx, orig in enumerate(names):
                if orig not in result and idx < len(items_list):
                    result[orig] = items_list[idx]
            return result
        except Exception as e:
            logger.error("_claude_get_nutrients: exception: %s", e, exc_info=True)
            return {}

    # ── Helpers ───────────────────────────────────────────────────────────────

    def _apply_nutrients(self, row: dict, src: "dict | None", source: "str | None") -> None:
        """Write per-100g nutrients into row from a source dict."""
        if src and float(src.get("calories") or 0) > 0:
            row["calories_per_100g"] = round(float(src["calories"]), 1)
            row["protein_per_100g"] = round(float(src.get("protein") or 0), 1)
            row["fat_per_100g"] = round(float(src.get("fat") or 0), 1)
            row["carbs_per_100g"] = round(float(src.get("carbs") or 0), 1)
            row["fiber_per_100g"] = _opt_float(src.get("fiber"))
            row["sugar_per_100g"] = _opt_float(src.get("sugar"))
            row["sugar_alcohols_per_100g"] = _opt_float(src.get("sugar_alcohols"))
            row["saturated_fat_per_100g"] = _opt_float(src.get("saturated_fat"))
            row["unsaturated_fat_per_100g"] = _opt_float(src.get("unsaturated_fat"))
            row["glycemic_index"] = int(src["glycemic_index"]) if src.get("glycemic_index") else None
            for k in _VITAMIN_KEYS:
                row[k + "_per_100g"] = _opt_float(src.get(k))
            row["source"] = source
            row["source_url"] = src.get("source_url")
        else:
            row["calories_per_100g"] = None
            row["protein_per_100g"] = None
            row["fat_per_100g"] = None
            row["carbs_per_100g"] = None
            row["fiber_per_100g"] = None
            row["sugar_per_100g"] = None
            row["sugar_alcohols_per_100g"] = None
            row["saturated_fat_per_100g"] = None
            row["unsaturated_fat_per_100g"] = None
            row["glycemic_index"] = None
            for k in _VITAMIN_KEYS:
                row[k + "_per_100g"] = None
            row["source"] = source or "unknown"
            row["source_url"] = None

    def _build_result(self, enriched: list[dict]) -> dict:
        """Scale per-100g values to actual portion and compute totals."""
        items_out = []
        total_cal = total_p = total_f = total_c = 0.0

        for row in enriched:
            w = float(row["weight_grams"])
            k = w / 100.0
            cal = round((row.get("calories_per_100g") or 0) * k, 1)
            prot = round((row.get("protein_per_100g") or 0) * k, 1)
            fat = round((row.get("fat_per_100g") or 0) * k, 1)
            carbs = round((row.get("carbs_per_100g") or 0) * k, 1)

            item_out: dict = {
                "name": row["name"],
                "name_en": row.get("name_en", ""),
                "weight_grams": round(w, 0),
                "calories": cal,
                "protein": prot,
                "fat": fat,
                "carbs": carbs,
                "fiber": round((row.get("fiber_per_100g") or 0) * k, 2) if row.get("fiber_per_100g") else None,
                "sugar": round((row.get("sugar_per_100g") or 0) * k, 2) if row.get("sugar_per_100g") else None,
                "sugar_alcohols": round((row.get("sugar_alcohols_per_100g") or 0) * k, 2) if row.get("sugar_alcohols_per_100g") else None,
                "saturated_fat": round((row.get("saturated_fat_per_100g") or 0) * k, 2) if row.get("saturated_fat_per_100g") else None,
                "unsaturated_fat": round((row.get("unsaturated_fat_per_100g") or 0) * k, 2) if row.get("unsaturated_fat_per_100g") else None,
                "glycemic_index": row.get("glycemic_index"),
                "source": row.get("source"),
                "source_url": row.get("source_url"),
            }
            for vk in _VITAMIN_KEYS:
                v100 = row.get(vk + "_per_100g")
                item_out[vk] = round(v100 * k, 3) if v100 is not None else None

            total_cal += cal
            total_p += prot
            total_f += fat
            total_c += carbs
            items_out.append(item_out)

        return {
            "items": items_out,
            "total": {
                "calories": round(total_cal, 1),
                "protein": round(total_p, 1),
                "fat": round(total_f, 1),
                "carbs": round(total_c, 1),
            },
        }

    @staticmethod
    def _zero_total() -> dict:
        return {"calories": 0.0, "protein": 0.0, "fat": 0.0, "carbs": 0.0}

    @staticmethod
    def _resolve_lang(language: str, text: str) -> str:
        if language in ("ru", "en"):
            return language
        return _detect_language(text)

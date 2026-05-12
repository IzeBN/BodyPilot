"""Integration tests for UserRepository."""
import pytest
import pytest_asyncio

from app.repositories.auth import AuthRepository
from app.repositories.user import UserRepository
from app.services.auth import hash_password


@pytest_asyncio.fixture
async def auth_repo(pool_fixture):
    return AuthRepository(pool_fixture)


@pytest_asyncio.fixture
async def repo(pool_fixture):
    return UserRepository(pool_fixture)


@pytest_asyncio.fixture
async def user_id(auth_repo):
    """Create a test user and return its ID."""
    return await auth_repo.create_user("userrepo@example.com", hash_password("pass12345"), "Test User")


# ─── update_profile ───────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_update_profile_fullname(repo, user_id):
    await repo.update_profile(user_id, fullname="New Name")
    profile = await repo.get_profile(user_id)
    assert profile["fullname"] == "New Name"


@pytest.mark.asyncio
async def test_update_profile_unknown_field_raises(repo, user_id):
    with pytest.raises(ValueError, match="Disallowed fields"):
        await repo.update_profile(user_id, malicious_col="DROP TABLE users")


# ─── upsert_nutrition_profile ────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_upsert_nutrition_profile(repo, user_id):
    await repo.upsert_nutrition_profile(user_id, weight_kg=80.5, goal="lose_weight")
    profile = await repo.get_nutrition_profile(user_id)
    assert profile is not None
    assert float(profile["weight_kg"]) == 80.5

    # Upsert again — should update, not insert duplicate
    await repo.upsert_nutrition_profile(user_id, weight_kg=78.0)
    profile2 = await repo.get_nutrition_profile(user_id)
    assert float(profile2["weight_kg"]) == 78.0


@pytest.mark.asyncio
async def test_upsert_nutrition_unknown_field_raises(repo, user_id):
    with pytest.raises(ValueError, match="Disallowed fields"):
        await repo.upsert_nutrition_profile(user_id, bad_field="value")


# ─── upsert_training_profile ─────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_upsert_training_profile(repo, user_id):
    await repo.upsert_training_profile(user_id, experience="beginner", current_fat_pct=20)
    profile = await repo.get_training_profile(user_id)
    assert profile["experience"] == "beginner"
    assert profile["current_fat_pct"] == 20


# ─── add_action / get_actions ────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_add_action(repo, user_id):
    await repo.add_action(user_id, "Test action")
    actions = await repo.get_actions(user_id)
    assert any(a["action"] == "Test action" for a in actions)


@pytest.mark.asyncio
async def test_add_action_dedup_within_30s(repo, user_id):
    await repo.add_action(user_id, "Repeated action")
    await repo.add_action(user_id, "Repeated action")
    actions = await repo.get_actions(user_id)
    duplicates = [a for a in actions if a["action"] == "Repeated action"]
    assert len(duplicates) == 1


# ─── upsert_pattern ──────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_upsert_pattern(repo, user_id):
    await repo.upsert_pattern(user_id, "theme", "dark")
    patterns = await repo.get_all_patterns(user_id)
    assert any(p["pkey"] == "theme" and p["pvalue"] == "dark" for p in patterns)

    # Update
    await repo.upsert_pattern(user_id, "theme", "light")
    patterns2 = await repo.get_all_patterns(user_id)
    assert any(p["pkey"] == "theme" and p["pvalue"] == "light" for p in patterns2)
    # No duplicate
    assert sum(1 for p in patterns2 if p["pkey"] == "theme") == 1

"""
Integration test fixtures.

Requires a running PostgreSQL instance (the test-db service in docker-compose.yml).
Connection is established via the TEST_DB_DSN environment variable.

Run with:
    docker compose up test-db -d
    TEST_DB_DSN=postgresql://kayfit:kayfit_secret@localhost:5433/kayfit_test pytest tests/integration/
"""
import os
import pytest
import pytest_asyncio
import asyncpg


TEST_DSN = os.getenv(
    "TEST_DB_DSN",
    "postgresql://kayfit:kayfit_secret@localhost:5433/kayfit_test",
)

# ─── Schema SQL paths ─────────────────────────────────────────────────────────
MIGRATION_FILES = [
    "migrations/001_initial.sql",
    "migrations/002_notifications.sql",
    "migrations/003_fixes.sql",
]


@pytest_asyncio.fixture(scope="session")
async def db_pool():
    """Session-scoped pool pointing at the test database."""
    pool = await asyncpg.create_pool(dsn=TEST_DSN, min_size=2, max_size=10)
    yield pool
    await pool.close()


@pytest_asyncio.fixture(scope="session", autouse=True)
async def apply_migrations(db_pool):
    """Apply all migrations once per test session."""
    import pathlib
    base = pathlib.Path(__file__).parent.parent.parent  # backend/
    async with db_pool.acquire() as conn:
        for migration in MIGRATION_FILES:
            sql = (base / migration).read_text(encoding="utf-8")
            await conn.execute(sql)


@pytest_asyncio.fixture
async def conn(db_pool):
    """Provide a connection that wraps each test in a rolled-back transaction."""
    async with db_pool.acquire() as connection:
        tr = connection.transaction()
        await tr.start()
        yield connection
        await tr.rollback()


@pytest_asyncio.fixture
async def pool_fixture(db_pool):
    """Return the session pool for repo instantiation."""
    return db_pool

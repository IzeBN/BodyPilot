import asyncpg


class BaseRepository:
    def __init__(self, pool: asyncpg.Pool):
        self.pool = pool

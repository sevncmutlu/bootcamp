from dataclasses import dataclass

from sqlalchemy import text
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)


@dataclass(frozen=True, slots=True)
class AsyncDatabase:
    engine: AsyncEngine
    session_factory: async_sessionmaker[AsyncSession]


def create_database(
    dsn: str,
    *,
    pool_size: int = 10,
    max_overflow: int = 10,
    pool_timeout_seconds: float = 5.0,
) -> AsyncDatabase:
    engine = create_async_engine(
        dsn,
        pool_pre_ping=True,
        pool_recycle=1_800,
        pool_size=pool_size,
        max_overflow=max_overflow,
        pool_timeout=pool_timeout_seconds,
    )
    return AsyncDatabase(
        engine=engine,
        session_factory=async_sessionmaker(engine, expire_on_commit=False),
    )


class DatabaseProbe:
    name = "postgresql"

    def __init__(self, engine: AsyncEngine) -> None:
        self._engine = engine

    async def is_ready(self) -> bool:
        async with self._engine.connect() as connection:
            result: int | None = await connection.scalar(text("SELECT 1"))
        return result == 1

from collections.abc import AsyncIterator
from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy.ext.asyncio import AsyncEngine
from testcontainers.postgres import PostgresContainer

from maki.infrastructure.database import create_database
from maki.infrastructure.leaderboard_repository import (
    SqlAlchemyLeaderboardRepository,
)
from maki.infrastructure.tables import Base


@pytest.fixture
async def repository() -> AsyncIterator[SqlAlchemyLeaderboardRepository]:
    try:
        container = PostgresContainer("postgres:18-alpine")
        container.start()
    except Exception:  # noqa: BLE001
        pytest.skip("Docker bulunamadı; liderlik entegrasyon testi çalıştırılamadı.")
    database = create_database(
        container.get_connection_url().replace(
            "postgresql+psycopg2",
            "postgresql+asyncpg",
        )
    )
    await _create_schema(database.engine)
    try:
        yield SqlAlchemyLeaderboardRepository(database.session_factory)
    finally:
        await database.engine.dispose()
        container.stop()


async def test_daily_subject_contribution_is_upserted_once(
    repository: SqlAlchemyLeaderboardRepository,
) -> None:
    now = datetime(2026, 7, 19, 12, tzinfo=UTC)
    common = {
        "cohort_hash": "a" * 64,
        "subject_hash": "b" * 64,
        "now": now,
        "expires_at": now + timedelta(days=7),
    }

    first = await repository.record_and_list(
        **common,
        score_basis_points=2_000,
    )
    second = await repository.record_and_list(
        **common,
        score_basis_points=3_000,
    )

    assert first == ()
    assert second == ()


async def _create_schema(engine: AsyncEngine) -> None:
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)

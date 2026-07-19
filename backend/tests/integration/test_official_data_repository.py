import asyncio
import shutil
from collections.abc import AsyncIterator
from datetime import UTC, date, datetime

import pytest
from testcontainers.postgres import PostgresContainer

from maki.infrastructure.database import create_database
from maki.infrastructure.official_data_repository import (
    SqlAlchemyOfficialDataRepository,
)
from maki.infrastructure.tables import Base
from maki.official_data.models import PublicationState, SeriesPoint, SourceSnapshot
from maki.official_data.service import OfficialDataService

pytestmark = pytest.mark.integration
_NOW = datetime(2026, 7, 3, 12, tzinfo=UTC)


@pytest.fixture
async def repository() -> AsyncIterator[tuple[SqlAlchemyOfficialDataRepository, object]]:
    if shutil.which("docker") is None:
        pytest.skip("Docker bulunamadı; PostgreSQL entegrasyon testi çalıştırılamadı.")

    container = PostgresContainer("postgres:17-alpine")
    await asyncio.to_thread(container.start)
    database = create_database(_asyncpg_url(container.get_connection_url()))
    async with database.engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
    try:
        yield SqlAlchemyOfficialDataRepository(database.session_factory), database
    finally:
        await database.engine.dispose()
        await asyncio.to_thread(container.stop)


async def test_publication_round_trip_and_pointer_update(
    repository: tuple[SqlAlchemyOfficialDataRepository, object],
) -> None:
    data_repository, _ = repository
    service = OfficialDataService(repository=data_repository, clock=lambda: _NOW)
    first = await service.publish(_snapshot("a" * 64, "v1", "100.25"))
    second = await service.publish(_snapshot("b" * 64, "v2", "101.75"))

    latest = await data_repository.latest_published("tuik")

    assert first.state is PublicationState.PUBLISHED
    assert latest == second
    assert str(latest.points[0].value) == "101.750000000000000000"


async def test_concurrent_same_snapshot_is_idempotent(
    repository: tuple[SqlAlchemyOfficialDataRepository, object],
) -> None:
    data_repository, _ = repository
    service = OfficialDataService(repository=data_repository, clock=lambda: _NOW)
    snapshot = _snapshot("c" * 64, "v1", "100")

    published = await asyncio.gather(*(service.publish(snapshot) for _ in range(8)))

    assert len({item.snapshot_id for item in published}) == 1


def _snapshot(digest: str, source_version: str, value: str) -> SourceSnapshot:
    return SourceSnapshot(
        source_name="tuik",
        source_version=source_version,
        schema_version=1,
        content_sha256=digest,
        etag='"fixture"',
        points=(
            SeriesPoint(
                series_id="TUFE_GENEL",
                period=date(2026, 6, 1),
                value=value,
                unit="index",
                release_date=date(2026, 7, 3),
                source_url="https://data.tuik.gov.tr/",
                retrieved_at=_NOW,
            ),
        ),
    )


def _asyncpg_url(url: str) -> str:
    if url.startswith("postgresql+psycopg2://"):
        return url.replace("postgresql+psycopg2://", "postgresql+asyncpg://", 1)
    return url.replace("postgresql://", "postgresql+asyncpg://", 1)

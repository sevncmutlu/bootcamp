import asyncio
import shutil
from collections.abc import AsyncIterator
from datetime import UTC, datetime

import pytest
from sqlalchemy import func, select
from testcontainers.postgres import PostgresContainer

from maki.infrastructure.database import create_database
from maki.infrastructure.job_repository import SqlAlchemyJobRepository
from maki.infrastructure.tables import Base, JobTable, OutboxEventTable
from maki.jobs.models import JobKind
from maki.jobs.service import JobService

pytestmark = pytest.mark.integration


@pytest.fixture
async def repository() -> AsyncIterator[tuple[SqlAlchemyJobRepository, object]]:
    if shutil.which("docker") is None:
        pytest.skip("Docker bulunamadı; PostgreSQL entegrasyon testi çalıştırılamadı.")

    container = PostgresContainer("postgres:17-alpine")
    await asyncio.to_thread(container.start)
    database = create_database(_asyncpg_url(container.get_connection_url()))
    async with database.engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
    try:
        yield SqlAlchemyJobRepository(database.session_factory), database
    finally:
        await database.engine.dispose()
        await asyncio.to_thread(container.stop)


async def test_same_key_race_creates_one_job_and_one_event(
    repository: tuple[SqlAlchemyJobRepository, object],
) -> None:
    job_repository, database = repository
    service = JobService(
        repository=job_repository,
        clock=lambda: datetime(2026, 7, 19, 12, tzinfo=UTC),
    )

    jobs = await asyncio.gather(
        *(
            service.accept(
                JobKind.FORECAST,
                {"series_hash": "abc"},
                "device-1",
                "database-race-key",
            )
            for _ in range(50)
        )
    )

    assert len({job.job_id for job in jobs}) == 1
    async with database.session_factory() as session:
        job_count = await session.scalar(select(func.count()).select_from(JobTable))
        outbox_count = await session.scalar(select(func.count()).select_from(OutboxEventTable))
    assert job_count == 1
    assert outbox_count == 1


def _asyncpg_url(url: str) -> str:
    if url.startswith("postgresql+psycopg2://"):
        return url.replace("postgresql+psycopg2://", "postgresql+asyncpg://", 1)
    return url.replace("postgresql://", "postgresql+asyncpg://", 1)

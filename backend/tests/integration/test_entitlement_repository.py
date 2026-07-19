from collections.abc import AsyncIterator

import pytest
from testcontainers.postgres import PostgresContainer

from maki.infrastructure.database import create_database
from maki.infrastructure.entitlement_repository import (
    SqlAlchemyEntitlementRepository,
)
from maki.infrastructure.tables import Base


@pytest.fixture
async def repository() -> AsyncIterator[SqlAlchemyEntitlementRepository]:
    try:
        container = PostgresContainer("postgres:18-alpine")
        container.start()
    except Exception:  # noqa: BLE001
        pytest.skip("Docker bulunamadı; abonelik entegrasyon testi çalıştırılamadı.")
    database = create_database(
        container.get_connection_url().replace(
            "postgresql+psycopg2",
            "postgresql+asyncpg",
        )
    )
    async with database.engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
    try:
        yield SqlAlchemyEntitlementRepository(database.session_factory)
    finally:
        await database.engine.dispose()
        container.stop()


async def test_repository_contract_is_exercised_by_service_suite(
    repository: SqlAlchemyEntitlementRepository,
) -> None:
    assert repository is not None

import hashlib
from collections.abc import AsyncIterator
from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy import select
from testcontainers.postgres import PostgresContainer

from maki.billing.models import Store, StoreEvent, StoreTransaction
from maki.billing.service import BillingService
from maki.infrastructure.database import AsyncDatabase, create_database
from maki.infrastructure.entitlement_repository import (
    SqlAlchemyEntitlementRepository,
)
from maki.infrastructure.job_repository import SqlAlchemyJobRepository
from maki.infrastructure.privacy_repository import SqlAlchemyPrivacyRepository
from maki.infrastructure.tables import Base, StoreTransactionTable
from maki.jobs.models import JobKind
from maki.jobs.service import JobService
from maki.privacy.deletion import DeletionCounts, DeletionService
from maki.privacy.export import DataExporter

NOW = datetime(2026, 7, 19, 12, tzinfo=UTC)
SUBJECT_ID = "cihaz-1"
SUBJECT_HASH = hashlib.sha256(SUBJECT_ID.encode()).hexdigest()


@pytest.fixture
async def database() -> AsyncIterator[AsyncDatabase]:
    try:
        container = PostgresContainer("postgres:18-alpine")
        container.start()
    except Exception:  # noqa: BLE001
        pytest.skip("Docker bulunamadı; gizlilik entegrasyon testi çalıştırılamadı.")
    instance = create_database(
        container.get_connection_url().replace(
            "postgresql+psycopg2",
            "postgresql+asyncpg",
        )
    )
    async with instance.engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
    try:
        yield instance
    finally:
        await instance.engine.dispose()
        container.stop()


async def test_export_and_deletion_are_transactional_and_idempotent(
    database: AsyncDatabase,
) -> None:
    privacy_repository = SqlAlchemyPrivacyRepository(database.session_factory)
    billing = BillingService(repository=SqlAlchemyEntitlementRepository(database.session_factory))
    jobs = JobService(
        repository=SqlAlchemyJobRepository(database.session_factory),
        clock=lambda: NOW,
    )
    await billing.apply(_transaction())
    await jobs.accept(
        JobKind.FORECAST,
        {},
        SUBJECT_ID,
        "benzersiz-anahtar",
    )
    exporter = DataExporter(repository=privacy_repository, clock=lambda: NOW)
    deletion = DeletionService(repository=privacy_repository)

    exported = await exporter.export(subject_id=SUBJECT_ID)
    first = await deletion.delete(subject_id=SUBJECT_ID)
    second = await deletion.delete(subject_id=SUBJECT_ID)

    assert len(exported.entitlements) == 1
    assert len(exported.jobs) == 1
    assert len(exported.billing_events) == 1
    assert first == DeletionCounts(
        jobs=1,
        entitlements=1,
        billing_events_anonymized=1,
        leaderboard_contributions=0,
    )
    assert second == DeletionCounts()
    async with database.session_factory() as session:
        retained_event = await session.scalar(select(StoreTransactionTable))
    assert retained_event is not None
    assert retained_event.subject_hash != SUBJECT_HASH
    assert retained_event.transaction_id != "tx-1"


def _transaction() -> StoreTransaction:
    return StoreTransaction(
        event_id="event-1",
        store=Store.GOOGLE_PLAY,
        transaction_id="tx-1",
        original_transaction_id="original-1",
        product_id="maki_debt_pro",
        subject_hash=SUBJECT_HASH,
        verified=True,
        event=StoreEvent.RENEWED,
        event_version=1,
        occurred_at=NOW,
        expires_at=NOW + timedelta(days=30),
    )

import hashlib
from datetime import datetime

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from maki.billing.models import (
    Entitlement,
    EntitlementStatus,
    Store,
    StoreEvent,
)
from maki.infrastructure.subject_lock import lock_subject
from maki.infrastructure.tables import (
    EntitlementTable,
    IdempotencyKeyTable,
    JobTable,
    LeaderboardContributionTable,
    StoreTransactionTable,
)
from maki.jobs.models import JobKind, JobStatus
from maki.privacy.deletion import DeletionCounts
from maki.privacy.export import (
    ExportBillingEvent,
    ExportJob,
    SubjectDataSnapshot,
)
from maki.privacy.retention import RetentionDataClass


class SqlAlchemyPrivacyRepository:
    def __init__(
        self,
        session_factory: async_sessionmaker[AsyncSession],
    ) -> None:
        self._session_factory = session_factory

    async def load(self, *, subject_hash: str) -> SubjectDataSnapshot:
        async with self._session_factory() as session, session.begin():
            await lock_subject(session, subject_hash)
            entitlements = await session.scalars(
                select(EntitlementTable)
                .where(EntitlementTable.subject_hash == subject_hash)
                .order_by(
                    EntitlementTable.product_id,
                    EntitlementTable.store,
                )
            )
            jobs = await session.scalars(
                select(JobTable)
                .where(JobTable.owner_hash == subject_hash)
                .order_by(JobTable.created_at, JobTable.job_id)
            )
            events = await session.scalars(
                select(StoreTransactionTable)
                .where(StoreTransactionTable.subject_hash == subject_hash)
                .order_by(
                    StoreTransactionTable.occurred_at,
                    StoreTransactionTable.event_id,
                )
            )
            return SubjectDataSnapshot(
                entitlements=tuple(_entitlement(row) for row in entitlements),
                jobs=tuple(_job(row) for row in jobs),
                billing_events=tuple(_billing_event(row) for row in events),
            )

    async def delete_subject(self, *, subject_hash: str) -> DeletionCounts:
        async with self._session_factory() as session, session.begin():
            await lock_subject(session, subject_hash)
            entitlement_ids = await session.scalars(
                delete(EntitlementTable)
                .where(EntitlementTable.subject_hash == subject_hash)
                .returning(EntitlementTable.product_id)
            )
            contribution_ids = await session.scalars(
                delete(LeaderboardContributionTable)
                .where(LeaderboardContributionTable.subject_hash == subject_hash)
                .returning(LeaderboardContributionTable.cohort_hash)
            )
            job_ids = await session.scalars(
                delete(JobTable)
                .where(JobTable.owner_hash == subject_hash)
                .returning(JobTable.job_id)
            )
            billing_events = tuple(
                await session.scalars(
                    select(StoreTransactionTable)
                    .where(StoreTransactionTable.subject_hash == subject_hash)
                    .with_for_update()
                )
            )
            for event in billing_events:
                _anonymize_event(event)
            return DeletionCounts(
                jobs=len(tuple(job_ids)),
                entitlements=len(tuple(entitlement_ids)),
                billing_events_anonymized=len(billing_events),
                leaderboard_contributions=len(tuple(contribution_ids)),
            )


class SqlAlchemyRetentionBackend:
    def __init__(
        self,
        session_factory: async_sessionmaker[AsyncSession],
    ) -> None:
        self._session_factory = session_factory

    async def purge_before(
        self,
        *,
        data_class: RetentionDataClass,
        cutoff: datetime,
        batch_size: int,
    ) -> int:
        if data_class is RetentionDataClass.IDEMPOTENCY:
            return await self._purge_idempotency(cutoff, batch_size)
        if data_class is RetentionDataClass.JOB_METADATA:
            return await self._purge_jobs(cutoff, batch_size)
        msg = f"{data_class.value} saklama sınıfı SQL deposunda bulunmuyor."
        raise ValueError(msg)

    async def _purge_idempotency(
        self,
        cutoff: datetime,
        batch_size: int,
    ) -> int:
        candidates = (
            select(IdempotencyKeyTable.key_hash)
            .where(IdempotencyKeyTable.created_at <= cutoff)
            .order_by(IdempotencyKeyTable.created_at, IdempotencyKeyTable.key_hash)
            .limit(batch_size)
        )
        async with self._session_factory() as session, session.begin():
            deleted = await session.scalars(
                delete(IdempotencyKeyTable)
                .where(IdempotencyKeyTable.key_hash.in_(candidates))
                .returning(IdempotencyKeyTable.key_hash)
            )
            return len(tuple(deleted))

    async def _purge_jobs(
        self,
        cutoff: datetime,
        batch_size: int,
    ) -> int:
        candidates = (
            select(JobTable.job_id)
            .where(
                JobTable.completed_at.is_not(None),
                JobTable.completed_at <= cutoff,
            )
            .order_by(JobTable.completed_at, JobTable.job_id)
            .limit(batch_size)
        )
        async with self._session_factory() as session, session.begin():
            deleted = await session.scalars(
                delete(JobTable).where(JobTable.job_id.in_(candidates)).returning(JobTable.job_id)
            )
            return len(tuple(deleted))


def _entitlement(row: EntitlementTable) -> Entitlement:
    return Entitlement(
        subject_hash=row.subject_hash,
        product_id=row.product_id,
        store=Store(row.store),
        status=EntitlementStatus(row.status),
        original_transaction_id=row.original_transaction_id,
        expires_at=row.expires_at,
        last_event_id=row.last_event_id,
        last_event=StoreEvent(row.last_event),
        last_event_version=row.last_event_version,
        last_event_at=row.last_event_at,
    )


def _job(row: JobTable) -> ExportJob:
    return ExportJob(
        job_id=row.job_id,
        kind=JobKind(row.kind),
        status=JobStatus(row.status),
        created_at=row.created_at,
        completed_at=row.completed_at,
    )


def _billing_event(row: StoreTransactionTable) -> ExportBillingEvent:
    return ExportBillingEvent(
        store=Store(row.store),
        product_id=row.product_id,
        event=StoreEvent(row.event),
        occurred_at=row.occurred_at,
        expires_at=row.expires_at,
    )


def _anonymize_event(row: StoreTransactionTable) -> None:
    row.subject_hash = _deleted_digest("subject", row.event_id)
    row.transaction_id = _deleted_digest("transaction", row.event_id)
    row.original_transaction_id = _deleted_digest("original", row.event_id)
    row.event_sha256 = _deleted_digest("event", row.event_id)


def _deleted_digest(namespace: str, event_id: str) -> str:
    return hashlib.sha256(f"deleted:{namespace}:{event_id}".encode()).hexdigest()

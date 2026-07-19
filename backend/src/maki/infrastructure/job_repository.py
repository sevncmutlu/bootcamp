from datetime import datetime, timedelta

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from maki.infrastructure.subject_lock import lock_subject
from maki.infrastructure.tables import (
    IdempotencyKeyTable,
    JobTable,
    OutboxEventTable,
)
from maki.jobs.errors import IdempotencyConflictError
from maki.jobs.models import (
    IdempotencyRecord,
    JobKind,
    JobRecord,
    JobStatus,
    OutboxRecord,
)
from maki.jobs.queue import JobClaim, JobClaimOutcome


class SqlAlchemyJobRepository:
    def __init__(
        self,
        session_factory: async_sessionmaker[AsyncSession],
        *,
        lease_duration: timedelta = timedelta(minutes=5),
    ) -> None:
        self._session_factory = session_factory
        self._lease_duration = lease_duration

    async def create_with_outbox(
        self,
        job: JobRecord,
        outbox: OutboxRecord,
        idempotency: IdempotencyRecord,
    ) -> JobRecord:
        try:
            result = await self._create_once(job, outbox, idempotency)
        except IntegrityError:
            existing_job = await self._read_after_race(idempotency)
            if existing_job is None:
                raise
            return existing_job
        else:
            return result

    async def get_for_owner(
        self,
        job_id: str,
        owner_hash: str,
    ) -> JobRecord | None:
        statement = select(JobTable).where(
            JobTable.job_id == job_id,
            JobTable.owner_hash == owner_hash,
        )
        async with self._session_factory() as session:
            row = await session.scalar(statement)
        return self._to_domain(row) if row is not None else None

    async def claim_for_work(self, job_id: str, now: datetime) -> JobClaim:
        async with self._session_factory() as session, session.begin():
            row = await self._locked_job(session, job_id)
            if row is None:
                return JobClaim(outcome=JobClaimOutcome.MISSING)
            job = self._to_domain(row)
            if job.status.is_terminal:
                return JobClaim(outcome=JobClaimOutcome.TERMINAL, job=job)
            if job.status is JobStatus.ACCEPTED:
                return JobClaim(outcome=JobClaimOutcome.BUSY)
            if (
                job.status is JobStatus.RUNNING
                and job.lease_expires_at is not None
                and job.lease_expires_at > now
            ):
                return JobClaim(outcome=JobClaimOutcome.BUSY)

            claimed = job.claim(now=now, lease_duration=self._lease_duration)
            self._apply_job(row, claimed)
            return JobClaim(
                outcome=JobClaimOutcome.CLAIMED,
                job=claimed,
                claim_token=claimed.lease_token,
            )

    async def finish(
        self,
        job_id: str,
        target: JobStatus,
        now: datetime,
        claim_token: str,
        failure_code: str | None = None,
    ) -> JobRecord:
        async with self._session_factory() as session, session.begin():
            row = await self._locked_job(session, job_id)
            if row is None:
                msg = "Tamamlanacak iş bulunamadı."
                raise RuntimeError(msg)
            finished = self._to_domain(row).finish_claim(
                target,
                now=now,
                claim_token=claim_token,
                failure_code=failure_code,
            )
            self._apply_job(row, finished)
            return finished

    async def list_unpublished(self, limit: int) -> tuple[OutboxRecord, ...]:
        statement = (
            select(OutboxEventTable)
            .where(OutboxEventTable.published_at.is_(None))
            .order_by(OutboxEventTable.created_at, OutboxEventTable.event_id)
            .limit(limit)
        )
        async with self._session_factory() as session:
            rows = (await session.scalars(statement)).all()
        return tuple(self._outbox_to_domain(row) for row in rows)

    async def mark_published(self, event_id: str, published_at: datetime) -> bool:
        async with self._session_factory() as session, session.begin():
            event = await session.scalar(
                select(OutboxEventTable)
                .where(OutboxEventTable.event_id == event_id)
                .with_for_update()
            )
            if event is None or event.published_at is not None:
                return False

            event.published_at = published_at
            job_row = await self._locked_job(session, event.job_id)
            if job_row is None:
                msg = "Outbox olayı bir işe bağlı değil."
                raise RuntimeError(msg)
            job = self._to_domain(job_row)
            if job.status is JobStatus.ACCEPTED:
                self._apply_job(
                    job_row,
                    job.transition(JobStatus.QUEUED, now=published_at),
                )
            return True

    async def _create_once(
        self,
        job: JobRecord,
        outbox: OutboxRecord,
        idempotency: IdempotencyRecord,
    ) -> JobRecord:
        async with self._session_factory() as session, session.begin():
            await lock_subject(session, job.owner_hash)
            existing = await session.get(IdempotencyKeyTable, idempotency.key_hash)
            if existing is not None:
                return await self._resolve_existing(session, existing, idempotency)
            session.add(self._job_row(job))
            await session.flush()
            session.add(self._outbox_row(outbox))
            session.add(self._idempotency_row(idempotency))
        return job

    async def _read_after_race(self, idempotency: IdempotencyRecord) -> JobRecord | None:
        async with self._session_factory() as session:
            existing = await session.get(IdempotencyKeyTable, idempotency.key_hash)
            if existing is None:
                return None
            return await self._resolve_existing(session, existing, idempotency)

    @staticmethod
    async def _locked_job(session: AsyncSession, job_id: str) -> JobTable | None:
        row: JobTable | None = await session.scalar(
            select(JobTable).where(JobTable.job_id == job_id).with_for_update()
        )
        return row

    @staticmethod
    async def _resolve_existing(
        session: AsyncSession,
        existing: IdempotencyKeyTable,
        idempotency: IdempotencyRecord,
    ) -> JobRecord:
        if existing.payload_hash != idempotency.payload_hash:
            raise IdempotencyConflictError
        job = await session.get(JobTable, existing.job_id)
        if job is None:
            msg = "Tekrarlama kaydı bir işe bağlı değil."
            raise RuntimeError(msg)
        return SqlAlchemyJobRepository._to_domain(job)

    @staticmethod
    def _job_row(job: JobRecord) -> JobTable:
        return JobTable(
            job_id=job.job_id,
            kind=job.kind.value,
            status=job.status.value,
            owner_hash=job.owner_hash,
            payload=job.payload,
            payload_hash=job.payload_hash,
            created_at=job.created_at,
            updated_at=job.updated_at,
            started_at=job.started_at,
            completed_at=job.completed_at,
            failure_code=job.failure_code,
            lease_token=job.lease_token,
            lease_expires_at=job.lease_expires_at,
            attempt=job.attempt,
            version=job.version,
        )

    @staticmethod
    def _outbox_row(outbox: OutboxRecord) -> OutboxEventTable:
        return OutboxEventTable(
            event_id=outbox.event_id,
            job_id=outbox.job_id,
            topic=outbox.topic,
            event_version=outbox.event_version,
            payload=outbox.payload,
            traceparent=outbox.traceparent,
            created_at=outbox.created_at,
            published_at=outbox.published_at,
        )

    @staticmethod
    def _idempotency_row(idempotency: IdempotencyRecord) -> IdempotencyKeyTable:
        return IdempotencyKeyTable(
            key_hash=idempotency.key_hash,
            payload_hash=idempotency.payload_hash,
            job_id=idempotency.job_id,
            created_at=idempotency.created_at,
        )

    @staticmethod
    def _to_domain(row: JobTable) -> JobRecord:
        return JobRecord(
            job_id=row.job_id,
            kind=JobKind(row.kind),
            status=JobStatus(row.status),
            owner_hash=row.owner_hash,
            payload=row.payload,
            payload_hash=row.payload_hash,
            created_at=row.created_at,
            updated_at=row.updated_at,
            started_at=row.started_at,
            completed_at=row.completed_at,
            failure_code=row.failure_code,
            lease_token=row.lease_token,
            lease_expires_at=row.lease_expires_at,
            attempt=row.attempt,
            version=row.version,
        )

    @staticmethod
    def _outbox_to_domain(row: OutboxEventTable) -> OutboxRecord:
        return OutboxRecord(
            event_id=row.event_id,
            job_id=row.job_id,
            topic=row.topic,
            event_version=row.event_version,
            payload=row.payload,
            traceparent=row.traceparent,
            created_at=row.created_at,
            published_at=row.published_at,
        )

    @staticmethod
    def _apply_job(row: JobTable, job: JobRecord) -> None:
        row.status = job.status.value
        row.payload = job.payload
        row.updated_at = job.updated_at
        row.started_at = job.started_at
        row.completed_at = job.completed_at
        row.failure_code = job.failure_code
        row.lease_token = job.lease_token
        row.lease_expires_at = job.lease_expires_at
        row.attempt = job.attempt
        row.version = job.version
